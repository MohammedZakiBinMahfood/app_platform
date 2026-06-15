import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:app_platform_core/core.dart';

import '../token/token_provider.dart';
import 'upload_client.dart';

class ProgressMultipartRequest extends http.MultipartRequest {
  final void Function(UploadProgress progress)? onProgress;

  ProgressMultipartRequest({
    required String method,
    required Uri url,
    this.onProgress,
  }) : super(method, url);

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    if (onProgress == null) return byteStream;

    final total = contentLength;
    var sent = 0;

    final stream = byteStream.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) {
          sent += data.length;
          onProgress!(UploadProgress(bytesSent: sent, totalBytes: total));
          sink.add(data);
        },
      ),
    );
    return http.ByteStream(stream);
  }
}

class HttpUploadClient implements UploadClient {
  final String baseUrl;
  final http.Client client;
  final TokenProvider tokenProvider;
  final Duration timeout;
  final Map<String, String> defaultHeaders;

  HttpUploadClient({
    required this.baseUrl,
    required this.client,
    required this.tokenProvider,
    this.defaultHeaders = const {},
    this.timeout = const Duration(seconds: 120),
  });

  @override
  Future<Result<T>> upload<T>(
    String path, {
    required List<UploadFile> files,
    Map<String, String>? fields,
    Map<String, String>? headers,
    required JsonParser<T> parser,
    void Function(UploadProgress progress)? onProgress,
  }) async {
    try {
      final token = await tokenProvider.getToken();
      final uri = Uri.parse('$baseUrl$path');
      final request = ProgressMultipartRequest(
        method: 'POST',
        url: uri,
        onProgress: onProgress,
      );

      final finalHeaders = <String, String>{
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        ...defaultHeaders,
        if (headers != null) ...headers,
      };
      request.headers.addAll(finalHeaders);

      if (fields != null) request.fields.addAll(fields);

      for (final file in files) {
        switch (file.source) {
          case FileBytes(:final bytes):
            request.files.add(http.MultipartFile.fromBytes(
              file.fieldName,
              bytes,
              filename: file.filename,
            ));
          case FilePath(:final path):
            request.files.add(await http.MultipartFile.fromPath(
              file.fieldName,
              path,
              filename: file.filename,
            ));
        }
      }

      final streamedResponse =
          await client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response, parser);
    } on SocketException {
      return Failure(const NoInternetError());
    } on TimeoutException {
      return Failure(const TimeoutError());
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  Result<T> _handleResponse<T>(http.Response response, JsonParser<T> parser) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      dynamic decoded;
      if (response.body.isNotEmpty) {
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {}
      }
      return Success(parser(decoded));
    }

    switch (statusCode) {
      case 401:
        return Failure(const UnauthorizedError());
      case 403:
        return Failure(const ForbiddenError());
      case 404:
        return Failure(const NotFoundError());
      case 422:
        dynamic decodedBody;
        try {
          decodedBody = jsonDecode(response.body);
        } catch (_) {}
        return Failure(ValidationError(response.body,
            fields: decodedBody is Map ? decodedBody['errors'] : null));
      default:
        return Failure(ServerError(statusCode, response.body));
    }
  }
}

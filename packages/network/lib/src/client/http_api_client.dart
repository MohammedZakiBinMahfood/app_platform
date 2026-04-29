import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:app_platform_core/core.dart';

import '../token/token_provider.dart';
import 'api_client.dart';

typedef ResponseHandler = Result<T> Function<T>(
    http.Response response,
    JsonParser<T> parser
    );

class HttpApiClient implements ApiClient {
  final String baseUrl;
  final http.Client client;
  final TokenProvider tokenProvider;
  final Duration timeout;
  final Map<String, String> defaultHeaders;
  final ResponseHandler? customHandler;

  HttpApiClient({
    required this.baseUrl,
    required this.client,
    required this.tokenProvider,
    this.defaultHeaders = const {},
    this.timeout = const Duration(seconds: 30),
    this.customHandler
  });

  @override
  Future<Result<T>> get<T>(String path,
      {Map<String, dynamic>? query,
      Map<String, String>? headers,
      required JsonParser<T> parser}) {
    return _request(
        method: _HttpMethod.get,
        uri: Uri.parse('$baseUrl$path').replace(queryParameters: query),
        headers: headers,
        parser: parser);
  }

  @override
  Future<Result<T>> post<T>(String path,
      {Map<String, dynamic>? body,
      Map<String, dynamic>? query,
      Map<String, String>? headers,
      required JsonParser<T> parser}) {
    return _request(
        method: _HttpMethod.post,
        uri: Uri.parse('$baseUrl$path').replace(queryParameters: query),
        body: body,
        headers: headers,
        parser: parser);
  }

  @override
  Future<Result<T>> put<T>(String path,
      {Map<String, dynamic>? body,
      Map<String, String>? headers,
      required JsonParser<T> parser}) {
    return _request(
        method: _HttpMethod.put,
        uri: Uri.parse('$baseUrl$path'),
        body: body,
        headers: headers,
        parser: parser);
  }

  @override
  Future<Result<T>> patch<T>(String path,
      {Map<String, dynamic>? body,
      Map<String, String>? headers,
      required JsonParser<T> parser}) {
    return _request(
        method: _HttpMethod.patch,
        uri: Uri.parse('$baseUrl$path'),
        body: body,
        headers: headers,
        parser: parser);
  }

  @override
  Future<Result<T>> delete<T>(String path,
      {Map<String, String>? headers, required JsonParser<T> parser}) {
    return _request(
        method: _HttpMethod.delete,
        uri: Uri.parse('$baseUrl$path'),
        headers: headers,
        parser: parser);
  }

  Future<Result<T>> _request<T>({
    required _HttpMethod method,
    required Uri uri,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    required JsonParser<T> parser,
  }) async {
    try {
      final token = await tokenProvider.getToken();
      final finalHeaders = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        ...defaultHeaders,
        if (headers != null) ...headers,
      };

      http.Response response;
      Future<http.Response> send() {
        switch (method) {
          case _HttpMethod.post:
            return client.post(uri,
                headers: finalHeaders,
                body: body != null ? jsonEncode(body) : null);
          case _HttpMethod.put:
            return client.put(uri,
                headers: finalHeaders,
                body: body != null ? jsonEncode(body) : null);
          case _HttpMethod.patch:
            return client.patch(uri,
                headers: finalHeaders,
                body: body != null ? jsonEncode(body) : null);
          case _HttpMethod.delete:
            return client.delete(uri, headers: finalHeaders);
          case _HttpMethod.get:
            return client.get(uri, headers: finalHeaders);
        }
      }

      response = await send().timeout(timeout);
      if (customHandler != null) {
        return customHandler!<T>(response, parser);
      }
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
    final responseBody = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      dynamic decoded;
      if (responseBody.isNotEmpty) {
        try {
          decoded = jsonDecode(responseBody);
        } catch (_) {}
      }
      return Success(parser(decoded));
    }

    // سنستخدم UnknownError لتمرير الـ body إذا كانت الكلاسات الأخرى لا تقبله
    // أو نمرر الـ body لـ ValidationError والـ ServerError
    switch (statusCode) {
      case 401:
        return Failure(
            const UnauthorizedError()); // الـ const سيعمل هنا لأننا لم نمرر متغيرات
      case 403:
        return Failure(const ForbiddenError());
      case 404:
        return Failure(const NotFoundError());
      case 422:
        dynamic decodedBody;
        try {
          decodedBody = jsonDecode(responseBody);
        } catch (_) {}
        // نمرر الـ body كرسالة للـ ValidationError
        return Failure(ValidationError(responseBody,
            fields: decodedBody is Map ? decodedBody['errors'] : null));
      default:
        // نمرر الـ body للـ ServerError
        return Failure(ServerError(statusCode, responseBody));
    }
  }
}

enum _HttpMethod { get, post, put, patch, delete }

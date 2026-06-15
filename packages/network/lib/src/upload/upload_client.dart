import 'package:app_platform_core/core.dart';

abstract class UploadClient {
  Future<Result<T>> upload<T>(
    String path, {
    required List<UploadFile> files,
    Map<String, String>? fields,
    Map<String, String>? headers,
    required JsonParser<T> parser,
    void Function(UploadProgress progress)? onProgress,
  });
}

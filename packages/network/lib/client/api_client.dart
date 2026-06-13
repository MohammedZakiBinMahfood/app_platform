
import 'package:app_platform_core/core.dart';

abstract class ApiClient {
  Future<Result<T>> get<T>(
      String path, {
        Map<String, dynamic>? query,
        Map<String, String>? headers,
        required JsonParser<T> parser,
      });

  Future<Result<T>> post<T>(
      String path, {
        Map<String, dynamic>? body,
        Map<String, dynamic>? query,
        Map<String, String>? headers,
        required JsonParser<T> parser,
      });

  Future<Result<T>> put<T>(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
        required JsonParser<T> parser,
      });

  Future<Result<T>> patch<T>(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
        required JsonParser<T> parser,
      });

  Future<Result<T>> delete<T>(
      String path, {
        required JsonParser<T> parser,
        Map<String, String>? headers,
      });
}

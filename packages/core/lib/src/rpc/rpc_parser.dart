import '../errors/common_errors.dart';
import '../result/result.dart';

int _getCode(Map<String, dynamic> json) {
  final code = json['code'];
  if (code is int) return code;
  if (code is String) return int.tryParse(code) ?? 500;
  return 500;
}

Result<T> parseRpcResult<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic>) fromMap,
) {
  final code = _getCode(json);
  if (code != 200) {
    return Failure(
      UnknownError(json['message'] as String? ?? 'Unknown error'),
    );
  }
  final data = json['data'] as Map<String, dynamic>;
  return Success(fromMap(data));
}

Result<List<T>> parseRpcList<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic>) fromMap,
) {
  final code = _getCode(json);
  if (code != 200) {
    return Failure(
      UnknownError(json['message'] as String? ?? 'Unknown error'),
    );
  }
  final data = json['data'] as List;
  return Success(data.map((e) => fromMap(e as Map<String, dynamic>)).toList());
}

Result<void> parseRpcVoid(Map<String, dynamic> json) {
  final code = _getCode(json);
  if (code != 200) {
    return Failure(
      UnknownError(json['message'] as String? ?? 'Unknown error'),
    );
  }
  return Success(null);
}

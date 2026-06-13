

import 'validation_error_data_source.dart';

class ValidationErrorData{
  ValidationErrorDataSource source;
  String? code,
  message;
  bool isEndUserError;

  ValidationErrorData.fromJson(Map<String, dynamic> jsonMap):
        source = ValidationErrorDataSource.fromJson(jsonMap['source']),
        code = jsonMap['code'],
        message = jsonMap['message'],
        isEndUserError = jsonMap['isEndUserError'];
}
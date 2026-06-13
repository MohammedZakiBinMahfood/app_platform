
import 'app_error.dart';

// class NetworkError extends AppError {
//   const NetworkError(): super(ErrorType.connectionError);
// }

class ServerError extends AppError {
  const ServerError(String? errorData) : super(ErrorType.serverError, errorData ?? 'Server Error');
}

class MapperError extends AppError {
  const MapperError(String errorData) : super(ErrorType.mapperError,errorData);
}

class UnknownError extends AppError {
  const UnknownError(String errorData) : super(ErrorType.unknownError,errorData);
}

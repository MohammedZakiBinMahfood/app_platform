import 'app_error.dart';
import 'validation_error_data.dart';

class NoInternetError extends AppError {
  const NoInternetError() : super(ErrorType.internetConnectionError,'No internet connection');
}

class TimeoutError extends AppError {
  const TimeoutError() : super(ErrorType.timeOutError,'Request timeout');
}

class NotFoundError extends AppError<String> {
  const NotFoundError() : super(ErrorType.notFoundError,'Resource not found');
}

class UnauthorizedError extends AppError<List<ValidationErrorData>> {
  const UnauthorizedError(List<ValidationErrorData> errors, ) : super(ErrorType.unauthorizedError,errors);
}

class ForbiddenError extends AppError<List<ValidationErrorData>> {
  const ForbiddenError(List<ValidationErrorData> errors, ) : super(ErrorType.forbiddenError,errors);
}


class BadRequestError extends AppError<List<ValidationErrorData>> {
  const BadRequestError(List<ValidationErrorData> errors, ) : super(ErrorType.badRequestError,errors);
}

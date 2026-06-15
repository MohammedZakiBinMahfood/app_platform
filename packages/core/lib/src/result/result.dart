import '../errors/app_error.dart';

sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) {
    final self = this;
    if (self is Success<T>) {
      return success(self.data);
    } else if (self is Failure<T>) {
      return failure(self.error);
    }
    throw Exception('Unhandled Result type');
  }

  Result<R> map<R>(R Function(T data) transform) {
    return when(
      success: (data) => Success(transform(data)),
      failure: (error) => Failure(error),
    );
  }

  Result<T> mapError(AppError Function(AppError error) transform) {
    return when(
      success: (data) => Success(data),
      failure: (error) => Failure(transform(error)),
    );
  }

  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return when(
      success: (data) => transform(data),
      failure: (error) => Failure(error),
    );
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

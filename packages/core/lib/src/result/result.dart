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
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

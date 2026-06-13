import 'result.dart';

extension ResultMap<T> on Result<T> {
  R map<R>({
    required R Function(Success<T> value) success,
    required R Function(Failure<T> value) failure,
  }) {
    final self = this;

    if (self is Success<T>) {
      return success(self);
    } else if (self is Failure<T>) {
      return failure(self);
    }

    throw Exception('Unhandled Result type');
  }
}

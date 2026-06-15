import 'dart:async';
import 'package:app_platform_core/core.dart';

class PreFetchAction<T> {
  final Future<Result<T>> Function() task;
  final Function()? onLoading;
  final Function(T data) onSuccess;
  final Function(AppError error)? onError;

  PreFetchAction({
    required this.task,
    required this.onSuccess,
    this.onLoading,
    this.onError,
  });

  Future<void> execute() async {
    onLoading?.call();

    final result = await task();

    if (result is Success<T>) {
      onSuccess(result.data);
    } else if (result is Failure<T>) {
      onError?.call(result.error);
    }
  }
}
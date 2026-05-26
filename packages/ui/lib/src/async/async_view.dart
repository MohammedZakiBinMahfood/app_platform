import 'package:flutter/material.dart';
import 'package:app_platform_core/core.dart';

class AsyncView<T> extends StatelessWidget {
  final LoadStatus status;
  final T? data;
  final AppError? error;

  final Widget Function() onLoading;
  final Widget Function(AppError error) onError;
  final Widget Function() onEmpty;
  final Widget Function(T data) onSuccess;

  const AsyncView({
    super.key,
    required this.status,
    required this.data,
    required this.onLoading,
    required this.onError,
    required this.onEmpty,
    required this.onSuccess,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LoadStatus.loading:
        return onLoading();

      case LoadStatus.error:
        return onError(
          error ?? const UnknownError('Something went wrong'),
        );

      case LoadStatus.success:
        if (data == null) {
          return onEmpty();
        }
        return onSuccess(data as T);

      default:
        return const SizedBox.shrink();
    }
  }
}

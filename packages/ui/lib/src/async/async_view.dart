import 'package:flutter/material.dart';
import 'package:app_platform_core/core.dart';

class AsyncView<T> extends StatelessWidget {
  final LoadStatus status;
  final T? data;
  final AppError? error;

  final Widget Function()? onLoading;
  final Widget Function(AppError error)? onError;
  final Widget Function()? onEmpty;
  final Widget Function(T data) onSuccess;

  const AsyncView({
    super.key,
    required this.status,
    required this.data,
    required this.onSuccess,
    this.error,
    this.onLoading,
    this.onError,
    this.onEmpty,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LoadStatus.loading:
        return onLoading != null
            ? onLoading!()
            : const Center(child: CircularProgressIndicator());

      case LoadStatus.error:
        final resolvedError = error ?? const UnknownError('Something went wrong');
        return onError != null
            ? onError!(resolvedError)
            : Center(child: Text(resolvedError.toString()));

      case LoadStatus.success:
        if (data == null || (data is Iterable && (data as Iterable).isEmpty)) {
          return onEmpty != null
              ? onEmpty!()
              : const Center(child: Text('No data available'));
        }
        return onSuccess(data as T);

      default:
        return const SizedBox.shrink();
    }
  }
}
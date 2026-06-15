import 'package:flutter/material.dart';

import 'package:app_platform_core/core.dart';

class AsyncView<T> extends StatelessWidget {
  final LoadStatus status;
  final T? data;
  final AppError? error;

  final Widget Function(BuildContext context)? onLoading;
  final Widget Function(BuildContext context, AppError error)? onError;
  final Widget Function(BuildContext context)? onEmpty;
  final Widget Function(BuildContext context, T data) onSuccess;

  final VoidCallback? onErrorAction;

  const AsyncView({
    super.key,
    required this.status,
    required this.data,
    required this.onSuccess,
    this.onLoading,
    this.onError,
    this.onEmpty,
    this.error,
    this.onErrorAction,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LoadStatus.loading:
        return onLoading?.call(context) ?? _defaultLoading(context);

      case LoadStatus.error:
        final err = error ?? const UnknownError('Something went wrong');
        return onError?.call(context, err) ?? _defaultError(context, err);

      case LoadStatus.success:
        if (data == null) {
          return onEmpty?.call(context) ?? _defaultEmpty(context);
        }
        return onSuccess(context, data!);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _defaultLoading(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _defaultError(BuildContext context, AppError error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon(
            //   Icons.error_outline,
            //   color: Theme.of(context).colorScheme.error,
            //   size: 40,
            // ),
            // const SizedBox(height: 8),
            Text(
              error.message.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            if (onErrorAction != null)
              IconButton(
                onPressed: onErrorAction,
                icon: const Icon(
                  Icons.refresh,
                  size: 50,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _defaultEmpty(BuildContext context) {
    return Center(
      child: Text(
        'No data available',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

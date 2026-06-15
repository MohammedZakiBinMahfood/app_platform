
import 'package:flutter/material.dart';

import 'package:app_platform_core/core.dart';
import '../state.dart';

extension BaseStateWhen<T> on BaseState<T> {
  Widget when(
      BuildContext context, {
        Widget Function(BuildContext context)? loading,
        Widget Function(BuildContext context, AppError error)? error,
        Widget Function(BuildContext context)? empty,
        required Widget Function(BuildContext context, T data) success,
        VoidCallback? onErrorAction,
      }) {
    switch (status) {
      case LoadStatus.loading:
        return loading?.call(context) ?? _defaultLoading();

      case LoadStatus.error:
        final err = this.error ?? const UnknownError('Something went wrong');
        return error?.call(context, err) ??
            _defaultError(context, err, onErrorAction);

      case LoadStatus.success:
        if (data == null) {
          return empty?.call(context) ?? _defaultEmpty(context);
        }
        return success(context, data as T);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _defaultLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _defaultError(
      BuildContext context,
      AppError error,
      VoidCallback? onErrorAction,
      ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error.message.toString()),
          const SizedBox(height: 8),
          if (onErrorAction != null)
            IconButton(
              onPressed: onErrorAction,
              icon: const Icon(Icons.refresh,size: 50,),
            ),
        ],
      ),
    );
  }

  Widget _defaultEmpty(BuildContext context) {
    return const Center(
      child: Text('No data'),
    );
  }
}

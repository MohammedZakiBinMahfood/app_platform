
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_platform_core/core.dart';
import 'base_state.dart';

abstract class BaseNotifier<T> extends Notifier<BaseState<T>> {

  @override
  BaseState<T> build() {
    return BaseState();
  }

  void setLoading() {
    state = state.copyWith(
      status: LoadStatus.loading,
      clearError: true,
    );
  }

  void setSuccess(T data) {
    state = BaseState(
      status: LoadStatus.success,
      data: data,
    );
  }

  void setError(AppError error) {
    state = BaseState(
      status: LoadStatus.error,
      error: error,
    );
  }

  void notify() {
    state = state.copyWith();
  }
}

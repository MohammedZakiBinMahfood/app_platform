// هذا يجعلها تظهر في الـ UI بشكل طبيعي جداً
import 'package:app_platform_core/core.dart';
import 'package:app_platform_state/state.dart';

extension PreFetchStateExtension on Object {
  // استخدمنا Object لكي تعمل مع ref (Riverpod) أو حتى داخل الـ Notifier إذا لزم الأمر
  void preFetch<T>({
    required Future<Result<T>> Function() task,
    required Function() onLoading,
    required Function(T data) onSuccess,
    required Function(AppError error) onError,
  }) {
    PreFetchAction<T>(
      task: task,
      onLoading: onLoading,
      onSuccess: onSuccess,
      onError: onError,
    ).execute();
  }
}
import 'package:app_platform_core/core.dart';
import 'package:app_platform_state/action/action_status.dart';

class ActionState {
  final ActionStatus status;
  final AppError? error;

  const ActionState._({
    required this.status,
    this.error,
  });

  /// 🟢 idle
  const ActionState.idle() : this._(status: ActionStatus.idle);

  /// ⏳ loading
  const ActionState.loading() : this._(status: ActionStatus.loading);

  /// ✅ success
  const ActionState.success() : this._(status: ActionStatus.success);

  /// ❌ failure
  const ActionState.failure(AppError error)
      : this._(
          status: ActionStatus.failure,
          error: error,
        );

  bool get isLoading => status == ActionStatus.loading;
  bool get isSuccess => status == ActionStatus.success;
  bool get isFailure => status == ActionStatus.failure;
}

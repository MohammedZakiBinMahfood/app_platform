import 'package:app_platform_core/core.dart';

class UploadState<T> {
  final LoadStatus status;
  final double progress;
  final T? data;
  final AppError? error;

  const UploadState._({
    this.status = LoadStatus.idle,
    this.progress = 0,
    this.data,
    this.error,
  });

  factory UploadState.idle() => const UploadState._();

  factory UploadState.inProgress(double progress) =>
      UploadState._(status: LoadStatus.loading, progress: progress);

  factory UploadState.success(T data) =>
      UploadState._(status: LoadStatus.success, progress: 1, data: data);

  factory UploadState.failure(AppError error) =>
      UploadState._(status: LoadStatus.error, error: error);
}

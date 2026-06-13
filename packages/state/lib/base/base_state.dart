

import 'package:app_platform_core/core.dart';

class BaseState<T> {
  final LoadStatus status;
  final T? data;
  final AppError? error;

  const BaseState({
    this.status = LoadStatus.idle,
    this.data,
    this.error,
  });

  // إضافة دالة copyWith
  BaseState<T> copyWith({
    LoadStatus? status,
    T? data,
    AppError? error,
    bool clearData = false, // اختيار إضافي لتصفير البيانات عند الحاجة
    bool clearError = false, // اختيار إضافي لتصفير الخطأ عند الحاجة
  }) {
    return BaseState<T>(
      status: status ?? this.status,
      data: clearData ? null : (data ?? this.data),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

import '../../core.dart';

class OperationState {
  final LoadStatus status;
  final String? statusMessage;

  OperationState({
    required this.status,
    this.statusMessage,
  });

  // إضافة دالة copyWith
  OperationState copyWith({
    LoadStatus? status,
    String? statusMessage,
    bool clearMessage = false, // خيار إضافي لتصفير الرسالة عند الحاجة
  }) {
    return OperationState(
      status: status ?? this.status,
      statusMessage: clearMessage ? null : (statusMessage ?? this.statusMessage),
    );
  }

  // ميزة إضافية: حالة الابتداء (Initial State) لسهولة الاستخدام في Riverpod
  factory OperationState.initial() => OperationState(status: LoadStatus.idle);
}
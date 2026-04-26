import '../../core.dart';

class OperationState {
  final LoadStatus status;
  final String? statusMessage;

  OperationState(this.status, this.statusMessage);
}

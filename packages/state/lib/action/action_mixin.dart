
import '../state.dart';

mixin ActionMixin<T> on BaseNotifier<T> {
  final ActionStore actions = ActionStore();

  void notifyActions() {
    notify();
  }
}

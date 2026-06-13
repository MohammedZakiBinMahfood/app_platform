import 'action_type.dart';

class ActionKey {
  final ActionType type;
  final String? id;

  const ActionKey(this.type, [this.id]);

  /// المفتاح النهائي المستخدم داخل ActionStore
  String get value {
    return id == null ? type.name : '${type.name}_$id';
  }

  @override
  String toString() => value;
}

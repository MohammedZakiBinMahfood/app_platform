import 'package:app_platform_state/state.dart';

typedef Validator = String? Function(Object? value);

typedef FormValidator<K extends Enum> =
String? Function(dynamic value, FormStateModel<K> form);

typedef AsyncValidator = Future<String?> Function(
    Object? value,
    );
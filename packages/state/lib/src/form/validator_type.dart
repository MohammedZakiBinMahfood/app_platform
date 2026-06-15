import 'package:app_platform_state/src/form/validation_context.dart';
import 'package:app_platform_state/state.dart';

typedef Validator<K extends Enum> =
String? Function(ValidationContext<K> context);

typedef AsyncValidator<K extends Enum> =
Future<String?> Function(ValidationContext<K> context);

typedef FieldValidator<TValue> =
String? Function(TValue value);

typedef FormValidator<TData> =
String? Function(TData data);
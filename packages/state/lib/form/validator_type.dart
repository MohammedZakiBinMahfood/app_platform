import '../state.dart';

typedef Validator<K extends Enum> =
String? Function(ValidationContext<K> context);

typedef AsyncValidator<K extends Enum> =
Future<String?> Function(ValidationContext<K> context);

typedef FieldValidator<TValue> =
String? Function(TValue value);

typedef FormValidator<TData> =
String? Function(TData data);

import '../state.dart';

class FormStateModel<K extends Enum> {
  final Map<K, FieldState<dynamic>> fields;

  const FormStateModel({
    this.fields = const {},
  });

  FieldState<T> field<T>(K key) {
    return fields[key] as FieldState<T>;
  }

  FormStateModel<K> updateField<T>(
      K key,
      FieldState<T> field,
      ) {
    return FormStateModel<K>(
      fields: {
        ...fields,
        key: field,
      },
    );
  }

  /// All fields are valid (sync + async) and not validating
  bool get isValid =>
      fields.values.every((f) => f.isValid);

  /// Any field is currently running async validation
  bool get isValidating =>
      fields.values.any((f) => f.isValidating);

  /// Can submit only when:
  /// - no validation in progress
  /// - no errors
  bool get canSubmit =>
      isValid && !isValidating;
}


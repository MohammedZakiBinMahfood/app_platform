import 'validation_field_state.dart';

class FormValidationState<K extends Enum> {
  final Map<K, ValidationFieldState> fields;

  const FormValidationState({
    this.fields = const {},
  });

  ValidationFieldState field(K key) {
    return fields[key] ?? const ValidationFieldState();
  }

  FormValidationState<K> updateField(
    K key,
    ValidationFieldState field,
  ) {
    return FormValidationState<K>(
      fields: {
        ...fields,
        key: field,
      },
    );
  }

  bool get isValid {
    return fields.values.every((e) => e.isValid);
  }

  bool get isValidating {
    return fields.values.any((e) => e.validating);
  }

  bool get canSubmit {
    return isValid && !isValidating;
  }
}

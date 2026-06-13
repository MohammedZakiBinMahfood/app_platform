import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state.dart';

abstract class ValidationController<K extends Enum>
    extends Notifier<FormValidationState<K>> {
  late final Map<K, Validator<K>> _validators;

  late final Map<K, AsyncValidator<K>> _asyncValidators;

  Timer? _debounce;

  @override
  FormValidationState<K> build();

  void init({
    Map<K, Validator<K>> validators = const {},
    Map<K, AsyncValidator<K>> asyncValidators = const {},
  }) {
    _validators = validators;
    _asyncValidators = asyncValidators;

    ref.onDispose(() {
      _debounce?.cancel();
    });

    state = FormValidationState<K>();
  }

  ValidationContext<K> _context(K field) {
    return ValidationContext<K>(
      ref: ref,
      field: field,
    );
  }

  String? validateField(K field) {
    final validator = _validators[field];

    if (validator == null) {
      return null;
    }

    return validator(_context(field));
  }

  void touch(K field) {
    final current = state.field(field);

    state = state.updateField(
      field,
      current.copyWith(touched: true),
    );
  }

  void clear(K field) {
    final current = state.field(field);

    state = state.updateField(
      field,
      current.copyWith(error: true),
    );
  }

  void validate(K field) {
    final current = state.field(field);

    final error = validateField(field);

    state = state.updateField(
      field,
      current.copyWith(
        error: error,
        touched: true,
      ),
    );
  }

  Future<void> validateAsync(K field) async {
    validate(field);

    final asyncValidator = _asyncValidators[field];

    if (asyncValidator == null) {
      return;
    }

    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () async {
        final current = state.field(field);

        state = state.updateField(
          field,
          current.copyWith(validating: true),
        );

        final error = await asyncValidator(_context(field));

        final latest = state.field(field);

        state = state.updateField(
          field,
          latest.copyWith(
            error: error,
            validating: false,
          ),
        );
      },
    );
  }

  bool validateAll() {
    bool valid = true;

    for (final field in _validators.keys) {
      final current = state.field(field);

      final error = validateField(field);

      if (error != null) {
        valid = false;
      }

      state = state.updateField(
        field,
        current.copyWith(
          error: error,
          touched: true,
        ),
      );
    }

    return valid;
  }

  bool validateStep(List<K> fields) {
    bool isValid = true;

    for (final field in fields) {
      validate(field);

      if (state.field(field).error != null) {
        isValid = false;
      }
    }

    return isValid;
  }

  void reset() {
    state = FormValidationState<K>();
  }

  void setFieldValidation(
    K field, {
    String? error,
    bool touched = true,
    bool validating = false,
  }) {
    final current = state.field(field);

    state = state.updateField(
      field,
      current.copyWith(
        error: error,
        touched: touched,
        validating: validating,
      ),
    );
  }

  String? requiredStringValidator(String? value, {String? customMessage}) {
    if (value == null || value.trim().isEmpty) {
      return customMessage ?? 'This field is required';
    }
    return null;
  }

  String? requiredObjectValidator(Object? value, {String? customMessage}) {
    if (value == null) {
      return customMessage ?? 'This field is required';
    }
    if (value is List && value.isEmpty) {
      return customMessage ?? 'This field is required';
    }
    return null;
  }
}

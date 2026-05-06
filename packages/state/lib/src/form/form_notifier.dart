import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'field_state.dart';
import 'form_state_model.dart';
import 'validator_type.dart';

abstract class FormNotifier<K extends Enum>
    extends Notifier<FormStateModel<K>> {

  // Sync validators
  late Map<K, Validator> _validators;

  late Map<K, FormValidator<K>> _formValidators;

  // Async validators
  late Map<K, AsyncValidator> _asyncValidators;

  // debounce
  Timer? _debounce;

  @override
  FormStateModel<K> build();

  // ---------------------------------------------------------------------------
  // init (بديل constructor)
  // ---------------------------------------------------------------------------
  void init({
    required FormStateModel<K> initial,
    Map<K, Validator> validators = const {},
    Map<K, FormValidator<K>> formValidators = const {},
    Map<K, AsyncValidator> asyncValidators = const {},
  }) {
    state = initial;
    _validators = validators;
    _formValidators = formValidators;
    _asyncValidators = asyncValidators;

    // cleanup
    ref.onDispose(() {
      _debounce?.cancel();
    });
  }

  // ---------------------------------------------------------------------------
  // Update field (sync)
  // ---------------------------------------------------------------------------
  void update<T>(K key, T value) {
    final validator = _validators[key];
    final formValidator = _formValidators[key];

    String? error;

    if (validator != null) {
      error = validator(value);
    }

    if (formValidator != null) {
      error = formValidator(value, state);
    }

    state = state.updateField(
      key,
      FieldState<T>(
        value: value,
        syncError: error,
        asyncError: null,
        touched: true,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Update with async validation (debounced)
  // ---------------------------------------------------------------------------
  void updateAsync<T>(K key, T value) {
    update(key, value);

    final asyncValidator = _asyncValidators[key];
    if (asyncValidator == null) return;

    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 500),
          () async {
        final field = state.field<T>(key);

        state = state.updateField(
          key,
          field.copyWith(isValidating: true),
        );

        final asyncError = await asyncValidator(value);

        final latestField = state.field<T>(key);

        state = state.updateField(
          key,
          latestField.copyWith(
            asyncError: asyncError,
            isValidating: false,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Validate all fields
  // ---------------------------------------------------------------------------
  void validateAll() {
    final updated = <K, FieldState<dynamic>>{};

    for (final entry in state.fields.entries) {
      final key = entry.key;
      final field = entry.value;

      final validator = _validators[key];
      final syncError =
      validator != null ? validator(field.value) : null;

      updated[key] = field.copyWith(
        syncError: syncError,
        touched: true,
      );
    }

    state = FormStateModel<K>(fields: updated);
  }

  // ---------------------------------------------------------------------------
  // Validate specific step
  // ---------------------------------------------------------------------------
  bool validateStep(List<K> keys) {
    final updated = <K, FieldState<dynamic>>{};
    bool isValid = true;

    for (final entry in state.fields.entries) {
      final key = entry.key;
      final field = entry.value;

      if (!keys.contains(key)) {
        updated[key] = field;
        continue;
      }

      final validator = _validators[key];
      final syncError =
      validator != null ? validator(field.value) : null;

      if (syncError != null) {
        isValid = false;
      }

      updated[key] = field.copyWith(
        syncError: syncError,
        touched: true,
      );
    }

    state = FormStateModel<K>(fields: updated);

    return isValid;
  }

  // ---------------------------------------------------------------------------
  // Reset form
  // ---------------------------------------------------------------------------
  void reset() {
    final resetFields = <K, FieldState<dynamic>>{};

    for (final entry in state.fields.entries) {
      resetFields[entry.key] =
          FieldState<dynamic>(value: entry.value.value);
    }

    state = FormStateModel<K>(fields: resetFields);
  }
}
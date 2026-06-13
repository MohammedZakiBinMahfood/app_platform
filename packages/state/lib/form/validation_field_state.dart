class ValidationFieldState {
  final String? error;
  final bool touched;
  final bool validating;

  const ValidationFieldState({
    this.error,
    this.touched = false,
    this.validating = false,
  });

  bool get isValid => error == null;

  ValidationFieldState copyWith({
    Object? error = _unset,
    bool? touched,
    bool? validating,
  }) {
    return ValidationFieldState(
      error: error == _unset
          ? this.error
          : error as String?,
      touched: touched ?? this.touched,
      validating: validating ?? this.validating,
    );
  }
}

const _unset = Object();
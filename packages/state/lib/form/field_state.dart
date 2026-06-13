class FieldState<T> {
  final T value;

  /// Error from sync validators (required, email, numeric, ...)
  final String? syncError;

  /// Error from async validators (server, uniqueness, ...)
  final String? asyncError;

  final bool touched;
  final bool isValidating;

  const FieldState({
    required this.value,
    this.syncError,
    this.asyncError,
    this.touched = false,
    this.isValidating = false,
  });

  /// Final error shown to the UI
  String? get error => asyncError ?? syncError;

  /// Field is valid only if:
  /// - no sync error
  /// - no async error
  /// - not validating
  bool get isValid =>
      syncError == null &&
          asyncError == null &&
          !isValidating;

  FieldState<T> copyWith({
    T? value,
    String? syncError,
    String? asyncError,
    bool? touched,
    bool? isValidating,
  }) {
    return FieldState<T>(
      value: value ?? this.value,
      syncError: syncError ?? this.syncError,
      asyncError: asyncError ?? this.asyncError,
      touched: touched ?? this.touched,
      isValidating: isValidating ?? this.isValidating,
    );
  }
}

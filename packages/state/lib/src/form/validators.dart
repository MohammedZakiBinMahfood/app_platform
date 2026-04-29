import 'validator_type.dart';

class Validators {
  static Validator required({
    String message = 'حقل مطلوب',
  }) {
    return (value) {
      final v = (value as String?)?.trim() ?? '';
      return v.isEmpty ? message : null;
    };
  }

  static Validator email({
    String message = 'Invalid email',
  }) {
    final regex =
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return (value) {
      final v = (value as String?)?.trim() ?? '';
      if (v.isEmpty) return null;
      return regex.hasMatch(v) ? null : message;
    };
  }

  static Validator website({
    String message = 'Invalid website',
  }) {
    final regex = RegExp(
      r'^(https?:\/\/)?([\w-]+\.)+[a-zA-Z]{2,}(\/\S*)?$',
      caseSensitive: false,
    );

    return (value) {
      final v = (value as String?)?.trim() ?? '';
      if (v.isEmpty) return null;
      return regex.hasMatch(v) ? null : message;
    };
  }

  static Validator numeric({
    String message = 'Must be a number',
  }) {
    return (value) {
      final v = (value as String?)?.trim() ?? '';
      if (v.isEmpty) return null;
      return double.tryParse(v) == null
          ? message
          : null;
    };
  }

  static Validator minLength(
      int length, {
        String? message,
      }) {
    return (value) {
      final v = (value as String?) ?? '';
      return v.length < length
          ? message ?? 'Minimum $length characters'
          : null;
    };
  }

  static Validator maxLength(
      int length, {
        String? message,
      }) {
    return (value) {
      final v = (value as String?) ?? '';
      return v.length > length
          ? message ?? 'Maximum $length characters'
          : null;
    };
  }

  static Validator range({
    required num min,
    required num max,
    String? message,
  }) {
    return (value) {
      final v = (value as String?)?.trim() ?? '';
      final number = num.tryParse(v);
      if (number == null) return null;
      if (number < min || number > max) {
        return message ??
            'Value must be between $min and $max';
      }
      return null;
    };
  }

  /// 🔥 combine بدون generic
  static Validator combine(
      List<Validator> validators) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}

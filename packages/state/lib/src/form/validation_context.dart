import 'package:flutter_riverpod/flutter_riverpod.dart';

class ValidationContext<K extends Enum> {
  final Ref ref;
  final K field;

  const ValidationContext({
    required this.ref,
    required this.field,
  });

  T read<T>(ProviderListenable<T> provider) {
    return ref.read(provider);
  }
}
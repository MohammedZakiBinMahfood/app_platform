import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../state.dart';

void listenForActions({
  required WidgetRef ref,
  required ProviderListenable<ActionStore> provider,
  required Map<ActionKey, ActionReaction> reactions,
}) {
  ref.listen<ActionStore>(provider, (previous, next) {
    if (previous == null) return;

    for (final entry in reactions.entries) {
      final key = entry.key.value;
      final reaction = entry.value;

      final prevAction = previous.get(key);
      final nextAction = next.get(key);

      // ✅ success
      if (prevAction.isLoading &&
          !nextAction.isLoading &&
          nextAction.error == null) {
        reaction.onSuccess();
      }

      // ❌ error
      if (prevAction.isLoading && nextAction.error != null) {
        reaction.onError(nextAction.error!);
      }
    }
  });
}

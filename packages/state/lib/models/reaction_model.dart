import 'dart:ui';

import 'package:app_platform_core/core.dart';


class ActionReaction {
  final VoidCallback onSuccess;
  final void Function(AppError error) onError;

  const ActionReaction({
    required this.onSuccess,
    required this.onError,
  });
}

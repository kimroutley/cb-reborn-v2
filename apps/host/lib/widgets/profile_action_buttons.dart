import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class ProfileActionButtons extends StatelessWidget {
  const ProfileActionButtons({
    super.key,
    required this.saving,
    required this.canSave,
    required this.canDiscard,
    required this.onSave,
    required this.onDiscard,
    required this.onReload,
  });

  final bool saving;
  final bool canSave;
  final bool canDiscard;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return CBProfileActionButtons(
      saving: saving,
      canSave: canSave,
      canDiscard: canDiscard,
      onSave: onSave,
      onDiscard: onDiscard,
      onReload: onReload,
    );
  }
}

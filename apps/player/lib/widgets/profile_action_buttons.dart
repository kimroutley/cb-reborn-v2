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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CBPrimaryButton(
                label: saving ? 'Saving...' : 'Save Profile',
                icon: Icons.save_outlined,
                onPressed: canSave ? onSave : null,
              ),
            ),
            const SizedBox(width: CBSpace.x2),
            CBTextButton(
              label: 'Discard',
              onPressed: canDiscard ? onDiscard : null,
            ),
          ],
        ),
        const SizedBox(height: CBSpace.x2),
        CBTextButton(
          label: 'Reload From Cloud',
          onPressed: saving ? null : onReload,
        ),
      ],
    );
  }
}

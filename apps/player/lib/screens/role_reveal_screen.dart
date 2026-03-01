import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

import '../widgets/full_role_reveal_content.dart';

class RoleRevealScreen extends StatelessWidget {
  final PlayerSnapshot player;
  final VoidCallback onConfirm;

  const RoleRevealScreen({
    super.key,
    required this.player,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = CBColors.fromHex(player.roleColorHex);

    return Theme(
      data: CBTheme.buildTheme(CBTheme.buildColorScheme(roleColor)),
      child: CBPrismScaffold(
        title: 'IDENTITY ASSIGNED',
        showAppBar: true,
        body: Semantics(
          label:
              'Your assigned role: ${player.roleName}. Dossier and mission. Confirm to continue.',
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            physics: const BouncingScrollPhysics(),
            child: FullRoleRevealContent(
              player: player,
              onConfirm: () {
                onConfirm();
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }
}

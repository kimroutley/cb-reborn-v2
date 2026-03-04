import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  final Role? role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return const SizedBox.shrink();
    }

    final roleColor = CBColors.fromHex(role!.colorHex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: roleColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: CBColors.circleGlow(roleColor, intensity: 0.2),
          ),
          child: CBRoleAvatar(
            assetPath: role!.assetPath,
            color: roleColor,
            size: 48,
          ),
        ),
        const SizedBox(height: 10),
        CBBadge(
          text: role!.name.toUpperCase(),
          color: roleColor,
        ),
      ],
    );
  }
}

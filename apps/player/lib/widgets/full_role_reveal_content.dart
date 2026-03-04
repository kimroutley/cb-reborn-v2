import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class FullRoleRevealContent extends StatelessWidget {
  final PlayerSnapshot player;
  final VoidCallback? onConfirm;

  const FullRoleRevealContent({
    super.key,
    required this.player,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    Color roleColor = scheme.primary;
    if (player.roleColorHex.isNotEmpty) {
      roleColor = CBColors.fromHex(player.roleColorHex);
    }

    return CBFadeSlide(
      child: CBGlassTile(
        borderColor: roleColor.withValues(alpha: 0.5),
        isPrismatic: true,
        padding: const EdgeInsets.all(CBSpace.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: CBSpace.x4),
            // Role Avatar
            Center(
              child: CBRoleAvatar(
                assetPath: 'assets/roles/${player.roleId}.png',
                size: 120,
                color: roleColor,
                breathing: true,
              ),
            ),
            const SizedBox(height: CBSpace.x8),

            // Role Name
            Text(
              player.roleName.toUpperCase(),
              style: textTheme.headlineMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
                shadows: CBColors.textGlow(roleColor, intensity: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CBSpace.x2),

            // Alliance
            Center(
              child: CBBadge(
                text: player.alliance.toUpperCase(),
                color: roleColor,
              ),
            ),

            const SizedBox(height: CBSpace.x8),
            Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CBColors.transparent,
                    roleColor.withValues(alpha: 0.3),
                    CBColors.transparent
                  ],
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x8),

            // Description
            Container(
              padding: const EdgeInsets.all(CBSpace.x4),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(CBRadius.sm),
                border: Border.all(color: roleColor.withValues(alpha: 0.1)),
              ),
              child: Text(
                player.roleDescription.toUpperCase(),
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.8),
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: CBSpace.x10),

            // Confirm Button
            if (onConfirm != null) ...[
              CBPrimaryButton(
                label: 'ACKNOWLEDGE IDENTITY',
                onPressed: () {
                  HapticService.heavy();
                  onConfirm!();
                },
                backgroundColor: roleColor,
                icon: Icons.fingerprint_rounded,
              ),
              const SizedBox(height: CBSpace.x4),
            ],
          ],
        ),
      ),
    );
  }
}

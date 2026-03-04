import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

import '../player_bridge.dart';

class RoleRevealCard extends StatelessWidget {
  final PlayerSnapshot player;
  final int dayCount;
  final String phase;

  const RoleRevealCard({
    super.key,
    required this.player,
    required this.dayCount,
    required this.phase,
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

    String statusText = 'ACTIVE';
    Color statusColor = scheme.tertiary;
    if (!player.isAlive) {
      statusText = 'DE-ACTIVATED';
      statusColor = scheme.error;
    } else if (player.silencedDay == dayCount && phase == 'day') {
      statusText = 'SILENCED';
      statusColor = CBColors.alertOrange;
    }

    final accent = player.isAlive ? roleColor : scheme.error;

    return CBFadeSlide(
      child: CBGlassTile(
        borderColor: accent.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(CBSpace.x6),
        isPrismatic: player.isAlive,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(CBSpace.x1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: accent.withValues(alpha: 0.3), width: 2),
                  boxShadow: CBColors.circleGlow(accent, intensity: 0.3),
                ),
                child: CBRoleAvatar(
                  assetPath: 'assets/roles/${player.roleId}.png',
                  size: 80,
                  color: accent,
                  breathing: player.isAlive,
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x6),
            Text(
              player.roleName.toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: scheme.onSurface,
                shadows: CBColors.textGlow(accent, intensity: 0.4),
              ),
            ),
            const SizedBox(height: CBSpace.x1),
            Text(
              player.alliance.toString().toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: accent.withValues(alpha: 0.6),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: CBSpace.x6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CBBadge(
                  text: 'ID: ${player.id.toUpperCase()}',
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  icon: Icons.fingerprint_rounded,
                ),
                const SizedBox(width: 12),
                CBBadge(
                  text: statusText,
                  color: statusColor,
                  icon: player.isAlive
                      ? Icons.verified_user_rounded
                      : Icons.cancel_rounded,
                ),
              ],
            ),
            const SizedBox(height: CBSpace.x6),
            CBPanel(
              borderColor: accent.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(CBSpace.x4),
              child: Column(
                children: [
                  CBSectionHeader(
                    title: 'ROLE INTEL',
                    icon: Icons.info_outline_rounded,
                    color: accent,
                  ),
                  const SizedBox(height: CBSpace.x4),
                  Text(
                    player.roleDescription.toUpperCase(),
                    style: textTheme.bodySmall!.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

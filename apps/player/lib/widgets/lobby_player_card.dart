import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class LobbyPlayerCard extends StatelessWidget {
  const LobbyPlayerCard({super.key, required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final roleColor = CBColors.fromHex(player.role.colorHex);

    return CBGlassTile(
      padding: const EdgeInsets.all(2),
      color: roleColor.withOpacity(0.1),
      borderColor: roleColor.withOpacity(0.3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                roleColor.withOpacity(0.15),
                roleColor.withOpacity(0.05),
              ],
              stops: const [0, 1],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CBRoleAvatar(
                  assetPath: player.role.assetPath,
                  color: roleColor,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  player.role.name.toUpperCase(),
                  style: textTheme.headlineSmall?.copyWith(
                    color: roleColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: CBColors.textGlow(roleColor, intensity: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'YOUR ASSIGNED ROLE',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  player.role.description,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
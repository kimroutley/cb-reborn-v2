import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

/// Body for the sliding panel when a player is tapped in Group Chat.
/// Shows player name and, if role is known, a role card (dossier) like the Blackbook.
class PlayerProfilePanelContent extends StatelessWidget {
  const PlayerProfilePanelContent({
    super.key,
    required this.player,
  });

  final PlayerSnapshot player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasRole = player.roleId.isNotEmpty &&
        player.roleId != 'unassigned' &&
        player.roleId != 'hidden';
    final role = hasRole ? roleCatalogMap[player.roleId] : null;
    final roleColor = hasRole && role != null
        ? CBColors.fromHex(role.colorHex)
        : scheme.primary;

    return Semantics(
      header: true,
      label: 'Profile for ${player.name}',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: hasRole && role != null
                ? CBRoleAvatar(
                    assetPath: role.assetPath,
                    color: roleColor,
                    size: 80,
                    breathing: true,
                  )
                : Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withValues(alpha: 0.15),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: scheme.primary,
                      size: 40,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            player.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              shadows: CBColors.textGlow(roleColor, intensity: 0.35),
            ),
          ),
          const SizedBox(height: 8),
          if (hasRole && role != null)
            CBBadge(
              text: role.name.toUpperCase(),
              color: roleColor,
            )
          else
            Text(
              'ROLE NOT VISIBLE',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          if (hasRole && role != null) ...[
            const SizedBox(height: 24),
            CBPanel(
              borderColor: roleColor.withValues(alpha: 0.3),
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CBSectionHeader(
                    title: 'DOSSIER',
                    icon: Icons.description_outlined,
                    color: roleColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    role.description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (role.tacticalTip.isNotEmpty) ...[
              const SizedBox(height: 16),
              CBPanel(
                borderColor: scheme.secondary.withValues(alpha: 0.2),
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CBSectionHeader(
                      title: 'TACTICAL TIP',
                      icon: Icons.lightbulb_outline_rounded,
                      color: scheme.secondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      role.tacticalTip,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
        ),
      ),
    );
  }
}

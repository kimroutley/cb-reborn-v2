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
      final hex = player.roleColorHex.replaceAll('#', '');
      final normalized = hex.length == 6 ? 'FF$hex' : hex;
      final parsed = int.tryParse(normalized, radix: 16);
      if (parsed != null) roleColor = Color(parsed);
    }

    String statusText = 'ACTIVE';
    Color statusColor = scheme.primary;
    if (!player.isAlive) {
      statusText = 'ELIMINATED';
      statusColor = scheme.secondary;
    } else if (player.silencedDay == dayCount && phase == 'day') {
      statusText = 'SILENCED';
      statusColor = scheme.error;
    }

    final accent = player.isAlive ? roleColor : scheme.error;

    return CBGlassTile(
      title: player.roleName,
      subtitle: player.alliance.toString().toUpperCase(),
      accentColor: accent,
      isPrismatic: true,
      icon: CBRoleAvatar(
        assetPath: 'assets/roles/${player.roleId}.png',
        size: 56,
        color: accent,
        breathing: player.isAlive,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CBBadge(text: 'ID: ${player.id.toUpperCase()}', color: roleColor),
              const SizedBox(width: CBSpace.x2),
              CBBadge(text: statusText, color: statusColor),
            ],
          ),
          const SizedBox(height: CBSpace.x4),
          Text(
            player.roleDescription,
            style: textTheme.bodySmall!.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

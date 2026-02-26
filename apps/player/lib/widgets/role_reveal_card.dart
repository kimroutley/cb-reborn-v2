import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

import 'role_detail_dialog.dart';

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
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

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
      statusColor = scheme.error;
    } else if (player.silencedDay == dayCount && phase == 'day') {
      statusText = 'SILENCED';
      statusColor = scheme.error;
    }

    final role = roleCatalogMap[player.roleId] ?? roleCatalog.first;
    final accent = player.isAlive ? roleColor : scheme.error;

    return CBPanel(
      borderColor: accent.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => showRoleDetailDialog(context, role),
            child: CBRoleAvatar(
              assetPath: role.assetPath,
              size: 64,
              color: accent,
              breathing: player.isAlive,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            player.roleName.toUpperCase(),
            style: textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              shadows: [
                Shadow(
                  color: accent.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CBBadge(
            text: 'STRATEGIC CLASS: ${role.type}',
            color: accent,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CBMiniTag(
                text: 'ID: ${player.id.substring(0, 6).toUpperCase()}',
                color: accent,
              ),
              const SizedBox(width: 8),
              CBMiniTag(text: statusText, color: statusColor),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            player.roleDescription,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          if (role.tacticalTip.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.secondary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 14, color: scheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      role.tacticalTip,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

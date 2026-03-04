import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class LiveIntelPanel extends StatelessWidget {
  final List<Player> players;

  const LiveIntelPanel({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final alive = players.where((p) => p.isAlive).toList();
    final staff = alive.where((p) => p.alliance == Team.clubStaff).length;
    final animals = alive.where((p) => p.alliance == Team.partyAnimals).length;
    final total = staff + animals;
    final alivePlayerIds = alive.map((p) => p.id).toSet();
    final pendingDramaSwapTargetIds = <String>{};
    for (final dramaQueen in players.where(
      (p) => p.role.id == RoleIds.dramaQueen && p.isAlive,
    )) {
      final targetAId = dramaQueen.dramaQueenTargetAId;
      final targetBId = dramaQueen.dramaQueenTargetBId;
      if (targetAId == null || targetBId == null) continue;
      if (targetAId == targetBId) continue;
      if (targetAId == dramaQueen.id || targetBId == dramaQueen.id) continue;
      if (!alivePlayerIds.contains(targetAId) ||
          !alivePlayerIds.contains(targetBId)) {
        continue;
      }
      pendingDramaSwapTargetIds
        ..add(targetAId)
        ..add(targetBId);
    }

    final staffOdds = total > 0 ? (staff / total * 100).round() : 50;

    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(CBSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CBSectionHeader(
            title: 'TACTICAL INTELLIGENCE',
            color: scheme.primary,
            icon: Icons.radar_rounded,
          ),
          const SizedBox(height: CBSpace.x6),

          Text(
            'PROBABILITY MATRIX',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: CBSpace.x4),
          _winOddsBar(context, 'DEALER SUCCESS', staffOdds, scheme.secondary),
          const SizedBox(height: CBSpace.x3),
          _winOddsBar(
              context, 'PARTY STABILITY', 100 - staffOdds, scheme.tertiary),

          const SizedBox(height: CBSpace.x8),

          Row(
            children: [
              Text(
                'PATRON STATUS RAIL',
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              CBBadge(text: '${alive.length} ACTIVE', color: scheme.tertiary, icon: Icons.sensors_rounded),
            ],
          ),
          const SizedBox(height: CBSpace.x4),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return Padding(
                  padding: const EdgeInsets.only(right: CBSpace.x4),
                  child: _buildPlayerAvatar(
                    context,
                    player,
                    hasPendingDramaSwap:
                        pendingDramaSwapTargetIds.contains(player.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _winOddsBar(
      BuildContext context, String label, int percentage, Color color) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: textTheme.labelSmall!.copyWith(
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: textTheme.labelLarge!.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontFamily: 'RobotoMono',
                shadows: CBColors.textGlow(color, intensity: 0.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.05),
              border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
            ),
            child: Stack(
              children: [
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutExpo,
                  widthFactor: percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.7),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerAvatar(
    BuildContext context,
    Player player, {
    required bool hasPendingDramaSwap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color statusColor = scheme.tertiary; // Healthy
    if (!player.isAlive) {
      statusColor = scheme.error;
    } else if (player.isSinBinned) {
      statusColor = scheme.error.withValues(alpha: 0.5);
    } else if (player.isShadowBanned) {
      statusColor = scheme.secondary;
    }

    final roleColor = CBColors.fromHex(player.role.colorHex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: player.isAlive ? roleColor.withValues(alpha: 0.4) : scheme.onSurface.withValues(alpha: 0.1),
                  width: 1.5
                ),
              ),
              child: CBRoleAvatar(
                assetPath: player.role.assetPath,
                color: roleColor,
                size: 44,
                pulsing: player.isAlive && !player.isSinBinned,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 2),
                  boxShadow: CBColors.circleGlow(statusColor, intensity: 0.3),
                ),
              ),
            ),
            if (player.hasHostShield)
              Positioned(
                top: -4,
                left: -4,
                child: Icon(
                  Icons.shield_rounded,
                  color: scheme.primary,
                  size: 18,
                  shadows: CBColors.iconGlow(scheme.primary, intensity: 0.4),
                ),
              ),
            if (hasPendingDramaSwap)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: scheme.secondary,
                    shape: BoxShape.circle,
                    boxShadow: CBColors.circleGlow(scheme.secondary, intensity: 0.25),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 10,
                    color: scheme.onSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          player.name.toUpperCase().split(' ').first,
          style: textTheme.labelSmall!.copyWith(
            fontSize: 8,
            color: player.isAlive ? scheme.onSurface.withValues(alpha: 0.7) : scheme.onSurface.withValues(alpha: 0.3),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            fontFamily: 'RobotoMono',
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

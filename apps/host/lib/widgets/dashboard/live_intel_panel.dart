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

    // Calculate win probability (Dealer vs Party Animal balance)
    // In social deduction, fewer dealers usually means higher win probability for them
    // unless they are outnumbered too heavily.
    final staffOdds = total > 0 ? (staff / total * 100).round() : 50;

    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'TACTICAL INTELLIGENCE',
            color: scheme.primary,
            icon: Icons.analytics_rounded,
          ),
          const SizedBox(height: 20),

          // Win Odds Section
          Text(
            '// PROBABILITY MATRIX',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 12),
          _winOddsBar(context, 'CLUB STAFF', staffOdds, scheme.secondary),
          const SizedBox(height: 12),
          _winOddsBar(
              context, 'PARTY ANIMALS', 100 - staffOdds, scheme.tertiary),

          const SizedBox(height: 24),

          // Player Health Rail
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '// PATRON STATUS RAIL',
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
              CBBadge(text: '${alive.length} ACTIVE', color: scheme.tertiary),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: textTheme.labelSmall!.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: textTheme.labelLarge!.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                shadows: CBColors.textGlow(color, intensity: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * (percentage / 100),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: CBColors.boxGlow(color, intensity: 0.3),
                    ),
                  ),
                ],
              );
            },
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
      statusColor = CBColors.dead;
    } else if (player.isSinBinned) {
      statusColor = scheme.error;
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
            CBRoleAvatar(
              assetPath: player.role.assetPath,
              color: roleColor,
              size: 44,
              pulsing: player.isAlive && !player.isSinBinned,
            ),
            // Status dot
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
                  boxShadow: CBColors.circleGlow(statusColor, intensity: 0.4),
                ),
              ),
            ),
            // Shield icon
            if (player.hasHostShield)
              Positioned(
                top: -4,
                left: -4,
                child: Icon(
                  Icons.shield_rounded,
                  color: scheme.primary,
                  size: 18,
                  shadows: CBColors.iconGlow(scheme.primary),
                ),
              ),
            if (hasPendingDramaSwap)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: CBColors.boxGlow(
                      scheme.secondary,
                      intensity: 0.25,
                    ),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 10,
                    color: scheme.surface,
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
            color: statusColor.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class LiveIntelPanel extends StatelessWidget {
  final List<Player> players;

  const LiveIntelPanel({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final alive = players.where((p) => p.isAlive).toList();
    final staff = alive.where((p) => p.alliance == Team.clubStaff).length;
    final animals = alive.where((p) => p.alliance == Team.partyAnimals).length;
    final total = staff + animals;
    final staffOdds = total > 0 ? (staff / total * 100).round() : 50;

    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'Live Intel & Win Prediction',
            color: scheme.primary,
            icon: Icons.analytics,
          ),
          const SizedBox(height: 16),

          // Win Odds Bars
          Text(
            'WIN PROBABILITY',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: scheme.tertiary,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 8),
          _winOddsBar(context, 'CLUB STAFF', staffOdds, scheme.error),
          const SizedBox(height: 6),
          _winOddsBar(context, 'PARTY ANIMALS', 100 - staffOdds, scheme.tertiary),
          const SizedBox(height: 16),

          // Player Health Rail
          Text(
            'PLAYER STATUS',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: scheme.tertiary,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildPlayerAvatar(context, player),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _winOddsBar(BuildContext context, String label, int percentage, Color color) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: textTheme.bodySmall!.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: textTheme.bodySmall!.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerAvatar(BuildContext context, Player player) {
    final textTheme = Theme.of(context).textTheme;
    Color statusColor = CBColors.matrixGreen;
    if (!player.isAlive) {
      statusColor = CBColors.dead;
    } else if (player.isSinBinned) {
      statusColor = CBColors.darkMetal;
    } else if (player.isShadowBanned) {
      statusColor = CBColors.alertOrange;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            CBRoleAvatar(
              assetPath: player.role.assetPath,
              color: CBColors.fromHex(player.role.colorHex),
              size: 40,
            ),
            // Status dot
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: CBColors.surface, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            // Shield icon
            if (player.hasHostShield)
              const Positioned(
                top: -2,
                left: -2,
                child: Icon(
                  Icons.shield,
                  color: CBColors.electricCyan,
                  size: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          player.name.split(' ').first,
          style: textTheme.bodySmall!.copyWith(
            fontSize: 8,
            color: statusColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

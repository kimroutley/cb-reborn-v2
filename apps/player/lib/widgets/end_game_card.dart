import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

import '../player_bridge.dart';

class EndGameCard extends StatelessWidget {
  final String? winner;
  final List<String> report;
  final PlayerSnapshot? player;
  final VoidCallback? onReturnToHub;

  const EndGameCard({
    super.key,
    required this.winner,
    required this.report,
    required this.player,
    this.onReturnToHub,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    // Determine victory status
    final isStaff = player?.isClubStaff ?? false;
    final isAnimals = player?.isPartyAnimal ?? false;
    final winnerStaff = winner == 'clubStaff';
    final winnerAnimals = winner == 'partyAnimals';
    final isVictory = (isStaff && winnerStaff) || (isAnimals && winnerAnimals);

    final resultText = isVictory ? 'VICTORY' : 'DEFEAT';
    final resultColor = isVictory ? scheme.primary : scheme.secondary;

    String winnerName = 'UNKNOWN';
    if (winnerStaff) winnerName = 'CLUB STAFF';
    if (winnerAnimals) winnerName = 'PARTY ANIMALS';
    if (winner == 'neutral') winnerName = 'NEUTRAL';

    return CBPanel(
      borderColor: resultColor,
      borderWidth: 2,
      padding: const EdgeInsets.all(24),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isVictory ? Icons.emoji_events : Icons.cancel,
            size: 64,
            color: resultColor,
          ),
          const SizedBox(height: 16),
          CBBadge(text: resultText, color: resultColor),
          const SizedBox(height: 8),
          Text(
            '$winnerName WIN',
            style: textTheme.displaySmall!.copyWith(
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (report.isNotEmpty) ...[
            for (final line in report)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium!,
                ),
              ),
            const SizedBox(height: 16),
          ],
          if (player != null) ...[
            CBBadge(
              text:
                  'You were ${player!.roleName.toUpperCase()} (${player!.isClubStaff ? "Club Staff" : "Party Animals"})',
              color: resultColor,
            ),
          ],
          if (onReturnToHub != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CBPrimaryButton(
                label: 'RETURN TO HUB',
                onPressed: onReturnToHub,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

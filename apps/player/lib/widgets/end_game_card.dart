import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:cb_models/cb_models.dart';

bool isPlayerVictory({
  required String? winner,
  required PlayerSnapshot? player,
}) {
  if (player == null || winner == null) return false;

  final isStaff = player.isClubStaff;
  final isAnimals = player.isPartyAnimal;
  final winnerStaff = winner == 'clubStaff';
  final winnerAnimals = winner == 'partyAnimals';

  if ((isStaff && winnerStaff) || (isAnimals && winnerAnimals)) {
    return true;
  }

  // Club Manager co-wins with the winning team as long as they survive,
  // except during neutral solo wins.
  final isClubManager = player.roleId == RoleIds.clubManager;
  if (isClubManager && player.isAlive && winner != 'neutral') {
    return true;
  }

  return false;
}

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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    // Determine victory status
    final isVictory = isPlayerVictory(winner: winner, player: player);
    final winnerStaff = winner == 'clubStaff';
    final winnerAnimals = winner == 'partyAnimals';

    final resultText = isVictory ? 'VICTORY' : 'MISSION FAILED';
    final resultColor = isVictory ? scheme.tertiary : scheme.error;

    String winnerName = 'UNKNOWN';
    if (winnerStaff) winnerName = 'CLUB STAFF';
    if (winnerAnimals) winnerName = 'PARTY ANIMALS';
    if (winner == 'neutral') winnerName = 'NEUTRAL';

    return CBFadeSlide(
      child: CBGlassTile(
        borderColor: resultColor.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(CBSpace.x6),
        isPrismatic: isVictory,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(CBSpace.x4),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: resultColor.withValues(alpha: 0.3), width: 2),
                boxShadow: CBColors.circleGlow(resultColor, intensity: 0.4),
              ),
              child: Icon(
                isVictory ? Icons.emoji_events_rounded : Icons.gavel_rounded,
                size: 56,
                color: resultColor,
              ),
            ),
            const SizedBox(height: CBSpace.x6),
            CBBadge(text: resultText, color: resultColor),
            const SizedBox(height: CBSpace.x3),
            Text(
              '$winnerName CONTROL VERIFIED',
              style: textTheme.headlineSmall!.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                shadows: CBColors.textGlow(scheme.onSurface, intensity: 0.3),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CBSpace.x6),
            if (report.isNotEmpty) ...[
              CBPanel(
                borderColor: resultColor.withValues(alpha: 0.2),
                padding: const EdgeInsets.all(CBSpace.x4),
                child: Column(
                  children: report.map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('> ', style: TextStyle(color: resultColor, fontWeight: FontWeight.bold, fontFamily: 'RobotoMono')),
                        Expanded(
                          child: Text(
                            line.toUpperCase(),
                            style: textTheme.bodySmall!.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: CBSpace.x6),
            ],
            if (player != null)
              CBMiniTag(
                text: 'IDENTITY: ${player!.roleName.toUpperCase()} // ${player!.isClubStaff ? "STAFF" : "PARTY"}',
                color: isVictory ? scheme.primary : scheme.secondary,
              ),
            if (onReturnToHub != null) ...[
              const SizedBox(height: CBSpace.x8),
              CBPrimaryButton(
                label: 'RETURN TO HUB',
                onPressed: () {
                  HapticService.medium();
                  onReturnToHub!();
                },
                backgroundColor: resultColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

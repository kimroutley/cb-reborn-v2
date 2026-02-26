import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class BarTabPanel extends StatelessWidget {
  final GameState gameState;

  const BarTabPanel({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final playersWithDebt =
        gameState.players.where((p) => p.drinksOwed > 0).toList()
          ..sort((a, b) => b.drinksOwed.compareTo(a.drinksOwed));
    final playersWithPenalties =
        gameState.players.where((p) => p.penalties.isNotEmpty).toList();
    final totalDebt =
        gameState.players.fold<int>(0, (sum, p) => sum + p.drinksOwed);
    final globalDebt = gameState.globalDrinkDebt;

    final hasContent =
        playersWithDebt.isNotEmpty || playersWithPenalties.isNotEmpty || globalDebt > 0;

    if (!hasContent) return const SizedBox.shrink();

    return CBPanel(
      borderColor: CBColors.alertOrange.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: CBSectionHeader(
                  title: 'BAR TAB TRACKER',
                  color: CBColors.alertOrange,
                  icon: Icons.local_bar_rounded,
                ),
              ),
              if (totalDebt > 0 || globalDebt > 0)
                CBBadge(
                  text:
                      '${totalDebt + globalDebt} DRINK${(totalDebt + globalDebt) == 1 ? '' : 'S'} OWED',
                  color: CBColors.alertOrange,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '// SOCIAL PENALTIES & DRINK DEBTS. IRL CONSEQUENCES.',
            style: textTheme.labelSmall!.copyWith(
              color: CBColors.alertOrange.withValues(alpha: 0.6),
              fontSize: 8,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),

          if (globalDebt > 0) ...[
            const SizedBox(height: 16),
            CBGlassTile(
              isPrismatic: true,
              padding: const EdgeInsets.all(12),
              borderColor: CBColors.alertOrange.withValues(alpha: 0.4),
              child: Row(
                children: [
                  const Icon(Icons.public_rounded,
                      color: CBColors.alertOrange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GLOBAL DRINK DEBT',
                          style: textTheme.labelSmall!.copyWith(
                            color: CBColors.alertOrange,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'Accumulated by game events. Shared by all patrons.',
                          style: textTheme.labelSmall!.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$globalDebt',
                    style: textTheme.headlineSmall!.copyWith(
                      color: CBColors.alertOrange,
                      fontWeight: FontWeight.w900,
                      shadows:
                          CBColors.textGlow(CBColors.alertOrange, intensity: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Individual debts
          if (playersWithDebt.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '// INDIVIDUAL TABS',
              style: textTheme.labelSmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 8),
            ...playersWithDebt.map((player) {
              final roleColor = CBColors.fromHex(player.role.colorHex);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: CBGlassTile(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  borderColor: roleColor.withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      CBRoleAvatar(
                        assetPath: player.role.assetPath,
                        color: roleColor,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          player.name.toUpperCase(),
                          style: textTheme.labelSmall!.copyWith(
                            color: roleColor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '${player.drinksOwed}',
                        style: textTheme.titleMedium!.copyWith(
                          color: CBColors.alertOrange,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.local_bar_rounded,
                          size: 14, color: CBColors.alertOrange),
                    ],
                  ),
                ),
              );
            }),
          ],

          // Penalties
          if (playersWithPenalties.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '// ACTIVE PENALTIES',
              style: textTheme.labelSmall!.copyWith(
                color: scheme.error.withValues(alpha: 0.6),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 8),
            ...playersWithPenalties.map((player) {
              final roleColor = CBColors.fromHex(player.role.colorHex);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: CBGlassTile(
                  padding: const EdgeInsets.all(10),
                  borderColor: scheme.error.withValues(alpha: 0.2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name.toUpperCase(),
                        style: textTheme.labelSmall!.copyWith(
                          color: roleColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: player.penalties
                            .map((p) => CBBadge(
                                  text: p.toUpperCase(),
                                  color: scheme.error,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../cb_theme.dart';

class GhostLoungeTarget {
  final String id;
  final String name;

  const GhostLoungeTarget({
    required this.id,
    required this.name,
  });
}

class GhostLoungeBet {
  final String bettorName;
  final String targetName;
  final int oddsCount;

  const GhostLoungeBet({
    required this.bettorName,
    required this.targetName,
    required this.oddsCount,
  });
}

/// Shared Ghost Lounge screen for eliminated players.
///
/// This view surfaces Dead Pool interactions and live ghost-bet visibility.
class GhostLoungeView extends StatelessWidget {
  final List<GhostLoungeTarget> aliveTargets;
  final List<GhostLoungeBet> activeBets;
  final String? currentBetTargetName;
  final ValueChanged<String> onPlaceBet;

  const GhostLoungeView({
    super.key,
    required this.aliveTargets,
    required this.activeBets,
    required this.onPlaceBet,
    this.currentBetTargetName,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'GHOST LOUNGE',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          CBPanel(
            borderColor: scheme.error.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CBSectionHeader(
                  title: 'SPECTATOR PROTOCOL',
                  icon: Icons.visibility_rounded,
                  color: scheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  '// YOUR TRANSMISSION HAS BEEN SEVERED. ACCESSING THE DEAD POOL TERMINAL...',
                  style: textTheme.labelSmall!.copyWith(
                    color: scheme.error.withValues(alpha: 0.6),
                    fontSize: 8,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Identify the next node to be purged from the network. Influence the remaining patrons from the shadows.',
                  style: textTheme.bodyMedium!.copyWith(color: scheme.onSurface.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 24),
                CBGlassTile(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderColor: currentBetTargetName == null ? scheme.secondary.withValues(alpha: 0.4) : scheme.tertiary.withValues(alpha: 0.4),
                  child: Row(
                    children: [
                      Icon(
                        currentBetTargetName == null ? Icons.warning_amber_rounded : Icons.radar_rounded,
                        color: currentBetTargetName == null ? scheme.secondary : scheme.tertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          currentBetTargetName == null
                              ? 'NO ACTIVE PREDICTION'
                              : 'TARGET LOCKED: ${currentBetTargetName!.toUpperCase()}',
                          style: textTheme.labelSmall!.copyWith(
                            color: currentBetTargetName == null ? scheme.secondary : scheme.tertiary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CBPrimaryButton(
                  label: aliveTargets.isEmpty
                      ? 'NO ACTIVE TARGETS'
                      : currentBetTargetName == null
                          ? 'PLACE PREDICTION'
                          : 'RE-LOCK TARGET',
                  icon: Icons.casino_rounded,
                  backgroundColor: scheme.error.withValues(alpha: 0.2),
                  foregroundColor: scheme.error,
                  onPressed: aliveTargets.isEmpty
                      ? null
                      : () {
                          showThemedBottomSheet<void>(
                            context: context,
                            accentColor: scheme.error,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'DEAD POOL: SELECT TARGET',
                                  style: textTheme.labelLarge!.copyWith(
                                    color: scheme.error,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    shadows: CBColors.textGlow(scheme.error, intensity: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 300),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: aliveTargets.map(
                                        (target) => Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: CBPrimaryButton(
                                            label: target.name,
                                            backgroundColor: scheme.error.withValues(alpha: 0.15),
                                            foregroundColor: scheme.error,
                                            onPressed: () {
                                              onPlaceBet(target.id);
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                      ).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CBPanel(
            borderColor: scheme.primary.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CBSectionHeader(
                  title: 'GHOST LOUNGE INTEL',
                  icon: Icons.radar_rounded,
                  color: scheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  '// LIVE DATA STREAM FROM SPECTATOR NODES.',
                  style: textTheme.labelSmall!.copyWith(
                    color: scheme.primary.withValues(alpha: 0.6),
                    fontSize: 8,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                if (activeBets.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'NO ACTIVE GHOST TRANSMISSIONS.',
                        style: textTheme.labelSmall!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.3),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  )
                else
                  ...activeBets.map(
                    (bet) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CBGlassTile(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        borderColor: scheme.outlineVariant.withValues(alpha: 0.3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bet.bettorName.toUpperCase(),
                                    style: textTheme.labelSmall!.copyWith(
                                      color: scheme.onSurface.withValues(alpha: 0.5),
                                      fontSize: 8,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'PREDICTS ',
                                        style: textTheme.labelSmall!.copyWith(
                                          color: scheme.error.withValues(alpha: 0.7),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        bet.targetName.toUpperCase(),
                                        style: textTheme.labelLarge!.copyWith(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w900,
                                          shadows: CBColors.textGlow(scheme.error, intensity: 0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            CBBadge(
                              text: '${bet.oddsCount} BETS',
                              color: scheme.error,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

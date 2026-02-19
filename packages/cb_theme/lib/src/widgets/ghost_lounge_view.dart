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

    return Scaffold(
      appBar: AppBar(title: const Text('GHOST LOUNGE')),
      body: CBNeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CBPanel(
                borderColor: scheme.error.withValues(alpha: 0.6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CBSectionHeader(
                      title: 'WELCOME TO THE GHOST LOUNGE',
                      icon: Icons.visibility_outlined,
                      color: scheme.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You are out of the game, but not out of influence. Use the Dead Pool to predict the next exile.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    CBBadge(
                      text: currentBetTargetName == null
                          ? 'NO ACTIVE BET'
                          : 'YOUR BET: ${currentBetTargetName!.toUpperCase()}',
                      color: currentBetTargetName == null
                          ? scheme.secondary
                          : scheme.tertiary,
                    ),
                    const SizedBox(height: 16),
                    CBPrimaryButton(
                      label: aliveTargets.isEmpty
                          ? 'No Eligible Targets'
                          : currentBetTargetName == null
                              ? 'Place Dead Pool Bet'
                              : 'Change Dead Pool Bet',
                      icon: Icons.casino_outlined,
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
                                      'PLACE DEAD POOL BET',
                                      style: textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 16),
                                    ...aliveTargets.map(
                                      (target) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: CBPrimaryButton(
                                          label: target.name,
                                          onPressed: () {
                                            onPlaceBet(target.id);
                                            Navigator.pop(context);
                                          },
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
              const SizedBox(height: 14),
              CBPanel(
                borderColor: scheme.primary.withValues(alpha: 0.6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CBSectionHeader(
                      title: 'LIVE DEAD POOL BETS',
                      icon: Icons.analytics_outlined,
                    ),
                    const SizedBox(height: 8),
                    if (activeBets.isEmpty)
                      Text(
                        'No ghost bets are active yet.',
                        style: textTheme.bodyMedium,
                      )
                    else
                      ...activeBets.map(
                        (bet) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${bet.bettorName} → ${bet.targetName}',
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                              CBBadge(
                                text: '${bet.oddsCount} on target',
                                color: CBColors.alertOrange,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

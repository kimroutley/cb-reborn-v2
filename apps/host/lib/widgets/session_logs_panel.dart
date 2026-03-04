import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cb_logic/cb_logic.dart';

import 'ai_recap_export.dart';

class SessionLogsPanel extends StatelessWidget {
  final GameState gameState;
  final Game controller;

  const SessionLogsPanel(
      {super.key, required this.gameState, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Export Action Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: CBGlassTile(
            borderColor: scheme.primary.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(CBSpace.x2),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: scheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI MISSION LOGS',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                CBGhostButton(
                  label: 'EXPORT',
                  icon: Icons.ios_share_rounded,
                  fullWidth: false,
                  onPressed: () {
                    HapticService.selection();
                    showAIRecapExportMenu(context: context, controller: controller);
                  },
                ),
              ],
            ),
          ),
        ),

        // Logs List
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(CBRadius.lg)),
              border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.2),
                  width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(CBRadius.lg - 2)),
              child: ListView.separated(
                reverse: true,
                padding: const EdgeInsets.all(CBSpace.x5),
                physics: const BouncingScrollPhysics(),
                itemCount: gameState.gameHistory.length,
                separatorBuilder: (context, index) => Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.1),
                  height: 12,
                ),
                itemBuilder: (context, index) {
                  final log = gameState
                      .gameHistory[gameState.gameHistory.length - 1 - index];
                  final logColor = _getLogColor(log, scheme);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '> ',
                          style: textTheme.labelSmall?.copyWith(
                            color: logColor.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w900,
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            log.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.8),
                              fontFamily: 'RobotoMono',
                              fontSize: 10,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getLogColor(String log, ColorScheme scheme) {
    final logUpper = log.toUpperCase();
    if (logUpper.contains('DEAD') ||
        logUpper.contains('KILLED') ||
        logUpper.contains('ELIMINATED')) {
      return scheme.error;
    } else if (logUpper.contains('VOTE') || logUpper.contains('VOTED')) {
      return scheme.secondary;
    } else if (logUpper.contains('ABILITY') || logUpper.contains('USED')) {
      return scheme.secondary;
    } else if (logUpper.contains('DAY') ||
        logUpper.contains('NIGHT') ||
        logUpper.contains('PHASE')) {
      return scheme.primary;
    } else {
      return scheme.tertiary;
    }
  }
}

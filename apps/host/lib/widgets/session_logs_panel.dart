import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cb_logic/cb_logic.dart';

import 'ai_recap_export.dart';

class SessionLogsPanel extends StatelessWidget {
  final GameState gameState;
  final Game controller;

  const SessionLogsPanel({
    super.key,
    required this.gameState,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Export Action Bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CBBadge(
                text: "AI SYNC",
                color: scheme.primary,
              ), // Migrated from CBColors.neonBlue
              const Spacer(),
              _buildGeminiButton(context, scheme),
            ],
          ),
        ),

        // Logs List
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow.withValues(alpha: 0.65),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.2),
              ), // Migrated from CBColors.neonBlue
            ),
            child: ListView.builder(
              reverse: true,
              itemCount: gameState.gameHistory.length,
              itemBuilder: (context, index) {
                final log = gameState
                    .gameHistory[gameState.gameHistory.length - 1 - index];
                final logColor = _getLogColor(log, scheme);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "> ",
                        style: CBTypography.code.copyWith(
                          color: logColor,
                          fontSize: 12,
                          shadows: CBColors.textGlow(logColor, intensity: 0.4),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          log.toUpperCase(),
                          style: CBTypography.code.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 12,
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
      ],
    );
  }

  Widget _buildGeminiButton(BuildContext context, ColorScheme scheme) {
    return IconButton(
      icon: Icon(
        Icons.auto_awesome,
        color: scheme.primary,
      ), // Migrated from CBColors.neonBlue
      onPressed: () =>
          showAIRecapExportMenu(context: context, controller: controller),
      tooltip: "Export to Gemini",
    );
  }

  Color _getLogColor(String log, ColorScheme scheme) {
    final logUpper = log.toUpperCase();
    if (logUpper.contains('DEAD') ||
        logUpper.contains('KILLED') ||
        logUpper.contains('ELIMINATED')) {
      return scheme.error; // Migrated from CBColors.dead
    } else if (logUpper.contains('VOTE') || logUpper.contains('VOTED')) {
      return scheme.secondary; // Migrated from CBColors.hotPink
    } else if (logUpper.contains('ABILITY') || logUpper.contains('USED')) {
      return scheme
          .secondary; // Migrated from CBColors.neonPurple (using secondary for general actions/abilities)
    } else if (logUpper.contains('DAY') ||
        logUpper.contains('NIGHT') ||
        logUpper.contains('PHASE')) {
      return scheme.primary; // Migrated from CBColors.neonBlue
    } else {
      return scheme
          .tertiary; // Migrated from CBColors.matrixGreen (default/success)
    }
  }
}

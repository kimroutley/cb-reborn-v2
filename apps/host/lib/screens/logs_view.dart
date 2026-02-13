import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class LogsView extends StatelessWidget {
  final GameState gameState;

  const LogsView({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CBSectionHeader(title: 'LIVE SESSION LOGS'),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: scheme.surface,
            child: ListView.builder(
              reverse: true,
              itemCount: gameState.gameHistory.length,
              itemBuilder: (context, index) {
                // Show most recent at bottom, but we reverse the list in UI
                final log = gameState
                    .gameHistory[gameState.gameHistory.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Placeholder for future proper historical timestamps from GameState.
                      Text(
                        '[00:00:00] ',
                        style: textTheme.bodySmall!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        '> ',
                        style: textTheme.bodySmall!.copyWith(
                          color: scheme
                              .tertiary, // Migrated from CBColors.matrixGreen
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          log.toUpperCase(),
                          style: textTheme.bodySmall!.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.8),
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
}

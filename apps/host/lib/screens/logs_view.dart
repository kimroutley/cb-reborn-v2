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
        CBSectionHeader(
          title: 'LIVE SESSION LOGS',
          icon: Icons.history_edu_rounded,
          color: scheme.primary,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: CBPanel(
            borderColor: scheme.outlineVariant.withValues(alpha: 0.3),
            padding: EdgeInsets.zero, // Padding handled by internal ListView
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.2), // Darker translucent background
                borderRadius: BorderRadius.circular(16), // Match panel rounded corners
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: gameState.gameHistory.length,
                  itemBuilder: (context, index) {
                    final log = gameState
                        .gameHistory[gameState.gameHistory.length - 1 - index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '# ',
                            style: textTheme.labelSmall!.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.4),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              log.toUpperCase(),
                              style: textTheme.labelSmall!.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.8),
                                fontSize: 9,
                                letterSpacing: 0.5,
                                fontFamily: 'RobotoMono',
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
        ),
      ],
    );
  }
}

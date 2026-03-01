import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class LogsView extends StatelessWidget {
  final GameState gameState;
  final VoidCallback? onOpenCommand;

  const LogsView({
    super.key,
    required this.gameState,
    this.onOpenCommand,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasLogs = gameState.gameHistory.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CBFadeSlide(
          child: CBSectionHeader(
            title: 'ACTIVE SESSION LOGS',
            icon: Icons.history_edu_rounded,
            color: scheme.primary,
          ),
        ),
        if (onOpenCommand != null) ...[
          const SizedBox(height: 16),
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: CBGlassTile(
              borderColor: scheme.secondary.withValues(alpha: 0.35),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.touch_app_rounded,
                        size: 18, color: scheme.secondary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'RETURN TO THE COMMAND CENTRE FOR ROUND CONTROLS.',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  CBGhostButton(
                    label: 'COMMAND',
                    icon: Icons.dashboard_customize_rounded,
                    fullWidth: false,
                    onPressed: () {
                      HapticService.selection();
                      onOpenCommand!();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Expanded(
          child: hasLogs
              ? CBFadeSlide(
                  delay: const Duration(milliseconds: 200),
                  child: CBPanel(
                    borderColor: scheme.outlineVariant.withValues(alpha: 0.2),
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(CBRadius.md),
                      child: ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: gameState.gameHistory.length,
                        itemBuilder: (context, index) {
                          final log = gameState.gameHistory[
                              gameState.gameHistory.length - 1 - index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${gameState.gameHistory.length - index} ',
                                  style: textTheme.labelSmall!.copyWith(
                                    color: scheme.onSurface.withValues(alpha: 0.3),
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'RobotoMono',
                                    fontSize: 9,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    log.toUpperCase(),
                                    style: textTheme.labelSmall!.copyWith(
                                      color: scheme.onSurface.withValues(alpha: 0.8),
                                      fontSize: 10,
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
                )
              : Center(
                  child: CBFadeSlide(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_toggle_off_rounded,
                            size: 64, color: scheme.onSurface.withValues(alpha: 0.1)),
                        const SizedBox(height: 24),
                        Text(
                          'NO ACTIVITY LOGGED',
                          style: textTheme.labelLarge?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'GAME EVENTS WILL APPEAR HERE.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.2),
                            fontSize: 9,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

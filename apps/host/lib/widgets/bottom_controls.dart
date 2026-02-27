import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomControls extends StatelessWidget {
  final bool isLobby;
  final bool isEndGame;
  final int playerCount;
  final VoidCallback onAction;
  final VoidCallback onAddMock;
  final bool eyesOpen;
  final Function(bool) onToggleEyes;
  final VoidCallback? onBack;
  final int requiredPlayers;

  const BottomControls({
    super.key,
    required this.isLobby,
    required this.isEndGame,
    required this.onAction,
    required this.onAddMock,
    required this.eyesOpen,
    required this.onToggleEyes,
    this.playerCount = 0,
    this.onBack,
    this.requiredPlayers = 4,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasNavigationActions = onBack != null || (isLobby && kDebugMode);
    final hasRoundActions = !isEndGame;
    final needsMorePlayers = isLobby && playerCount < requiredPlayers;
    final missingPlayers =
        (requiredPlayers - playerCount).clamp(0, requiredPlayers);

    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _panelTitle(),
            style: textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          if (hasNavigationActions) ...[
            const SizedBox(height: 12),
            Text(
              'NAVIGATION',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Move between host flow screens.',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (onBack != null)
                  CBGhostButton(
                    label: 'Back',
                    icon: Icons.arrow_back_rounded,
                    fullWidth: false,
                    onPressed: onBack,
                  ),
                if (isLobby && kDebugMode)
                  CBGhostButton(
                    label: 'Add Bot',
                    icon: Icons.smart_toy_rounded,
                    fullWidth: false,
                    onPressed: onAddMock,
                  ),
              ],
            ),
          ],
          if (hasRoundActions) ...[
            if (hasNavigationActions) const SizedBox(height: 12),
            Text(
              isLobby ? 'LOBBY ACTION' : 'ROUND ACTION',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isLobby
                  ? 'Start when roster and setup are ready.'
                  : 'Control visibility and advance phase flow.',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
              ),
            ),
            if (isLobby) ...[
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: CBGlassTile(
                  key: ValueKey(needsMorePlayers),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  borderColor: needsMorePlayers
                      ? scheme.secondary.withValues(alpha: 0.4)
                      : scheme.tertiary.withValues(alpha: 0.4),
                  child: Row(
                    children: [
                      Icon(
                        needsMorePlayers
                            ? Icons.group_add_rounded
                            : Icons.check_circle_rounded,
                        size: 16,
                        color: needsMorePlayers
                            ? scheme.secondary
                            : scheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          needsMorePlayers
                              ? 'Need $missingPlayers more players to launch.'
                              : 'Roster threshold reached. Ready to launch.',
                          style: textTheme.labelSmall?.copyWith(
                            color: needsMorePlayers
                                ? scheme.secondary
                                : scheme.tertiary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!isLobby)
                  IconButton.filledTonal(
                    onPressed: () => onToggleEyes(!eyesOpen),
                    tooltip: eyesOpen ? 'Eyes Open' : 'Eyes Closed',
                    icon: Icon(
                      eyesOpen
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: needsMorePlayers ? 0.7 : 1,
                  child: FilledButton.icon(
                    onPressed: needsMorePlayers
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            onAction();
                          },
                    icon: Icon(_primaryIcon()),
                    label: Text(_primaryLabel()),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _panelTitle() {
    if (isLobby) return 'Lobby Actions';
    if (isEndGame) return 'End Game Actions';
    return 'Round Actions';
  }

  String _primaryLabel() {
    if (isEndGame) return 'New Game';
    if (isLobby) {
      return playerCount < requiredPlayers
          ? 'Need ${requiredPlayers - playerCount} More'
          : 'Open The Club';
    }
    return 'Advance Phase';
  }

  IconData _primaryIcon() {
    if (isEndGame) return Icons.refresh_rounded;
    if (isLobby) return Icons.play_arrow_rounded;
    return Icons.fast_forward_rounded;
  }
}

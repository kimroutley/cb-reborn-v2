import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    final missingPlayers = (requiredPlayers - playerCount).clamp(0, requiredPlayers);

    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(CBSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _panelTitle().toUpperCase(),
            style: textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
          ),

          if (hasNavigationActions) ...[
            const SizedBox(height: 16),
            Text(
              'NAVIGATION',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onBack != null)
                  Expanded(
                    child: CBGhostButton(
                      onPressed: onBack,
                      icon: Icons.arrow_back_rounded,
                      label: 'Back',
                    ),
                  ),
                if (onBack != null && isLobby && kDebugMode) const SizedBox(width: 12),
                if (isLobby && kDebugMode)
                  Expanded(
                    child: CBGhostButton(
                      onPressed: onAddMock,
                      icon: Icons.smart_toy_rounded,
                      label: 'Add Bot',
                      color: scheme.tertiary,
                    ),
                  ),
              ],
            ),
          ],

          if (hasRoundActions) ...[
            if (hasNavigationActions) const SizedBox(height: 20),
            Text(
              isLobby ? 'LOBBY PROTOCOL' : 'ROUND PROTOCOL',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            if (isLobby) ...[
              CBFadeSlide(
                child: CBGlassTile(
                  key: ValueKey(needsMorePlayers),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderColor: needsMorePlayers
                      ? scheme.secondary.withValues(alpha: 0.4)
                      : scheme.tertiary.withValues(alpha: 0.4),
                  child: Row(
                    children: [
                      Icon(
                        needsMorePlayers
                            ? Icons.group_add_rounded
                            : Icons.check_circle_rounded,
                        size: 18,
                        color:
                            needsMorePlayers ? scheme.secondary : scheme.tertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          needsMorePlayers
                              ? 'NEED $missingPlayers MORE OPERATIVES TO INITIATE.'
                              : 'ROSTER THRESHOLD VERIFIED. READY TO LAUNCH.',
                          style: textTheme.labelSmall?.copyWith(
                            color:
                                needsMorePlayers ? scheme.secondary : scheme.tertiary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                if (!isLobby) ...[
                  IconButton.filledTonal(
                    onPressed: () {
                      HapticService.selection();
                      onToggleEyes(!eyesOpen);
                    },
                    tooltip: eyesOpen ? 'Eyes Open' : 'Eyes Closed',
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.primary.withValues(alpha: 0.1),
                      foregroundColor: scheme.primary,
                    ),
                    icon: Icon(
                      eyesOpen
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: CBPrimaryButton(
                    onPressed: needsMorePlayers ? null : onAction,
                    icon: _primaryIcon(),
                    label: _primaryLabel(),
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
    if (isLobby) return 'Lobby Terminal';
    if (isEndGame) return 'Post-Mission Protocol';
    return 'Operation Controls';
  }

  String _primaryLabel() {
    if (isEndGame) return 'New Session';
    if (isLobby) {
      return playerCount < requiredPlayers
          ? 'INSUFFICIENT DATA'
          : 'Initiate Session';
    }
    return 'Advance Protocol';
  }

  IconData _primaryIcon() {
    if (isEndGame) return Icons.refresh_rounded;
    if (isLobby) return Icons.play_arrow_rounded;
    return Icons.fast_forward_rounded;
  }
}

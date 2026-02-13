import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class BottomControls extends StatelessWidget {
  final bool isLobby;
  final bool isEndGame;
  final int playerCount;
  final VoidCallback onAction;
  final VoidCallback onAddMock;
  final bool eyesOpen;
  final Function(bool) onToggleEyes;
  final VoidCallback? onBack;

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
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surface
                .withValues(alpha: 0.7), // Migrated from CBColors.voidBlack
            border: Border(
              top: BorderSide(
                color: scheme.primary.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // ── BACK BUTTON ──
              if (onBack != null) ...[
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new,
                      color:
                          scheme.onSurface), // Migrated from CBColors.onSurface
                  onPressed: onBack,
                  tooltip: 'Go Back',
                ),
                const SizedBox(width: 4),
              ],

              // ── LOBBY DEBUG ──
              if (isLobby && kDebugMode) ...[
                Expanded(
                  child: CBGhostButton(
                    label: 'ADD MOCK',
                    color: scheme.primary,
                    onPressed: onAddMock,
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // ── EYES TOGGLE (gameplay only) ──
              if (!isLobby && !isEndGame) ...[
                IconButton(
                  icon: Icon(
                    eyesOpen ? Icons.visibility : Icons.visibility_off,
                    color: eyesOpen
                        ? scheme.tertiary
                        : scheme
                            .error, // Migrated from CBColors.matrixGreen and CBColors.dead
                  ),
                  onPressed: () => onToggleEyes(!eyesOpen),
                  tooltip: eyesOpen ? 'Eyes Open' : 'Eyes Closed',
                ),
                const SizedBox(width: 4),
              ],

              // ── LEFT BOLT ──
              if (!isLobby && !isEndGame) ...[
                _NeonBoltButton(onPressed: onAction, color: scheme.primary),
                const SizedBox(width: 8),
              ],

              // ── PRIMARY ACTION ──
              Expanded(
                child: _PrimaryActionButton(
                  isLobby: isLobby,
                  isEndGame: isEndGame,
                  playerCount: playerCount,
                  onPressed: onAction,
                ),
              ),

              // ── RIGHT BOLT ──
              if (!isLobby && !isEndGame) ...[
                const SizedBox(width: 8),
                _NeonBoltButton(onPressed: onAction, color: scheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular lightning bolt button with neon purple glow.
class _NeonBoltButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;

  const _NeonBoltButton({required this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: CBColors.circleGlow(color, intensity: 0.5),
      ),
      child: IconButton(
        style: IconButton.styleFrom(
          backgroundColor:
              scheme.surfaceContainerLowest, // Migrated from CBColors.surface
          shape: CircleBorder(
            side: BorderSide(color: color, width: 1.5),
          ),
        ),
        icon: Icon(Icons.bolt, color: color, size: 22),
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        tooltip: 'Advance',
      ),
    );
  }
}

/// Central action button that adapts label/color based on game phase.
class _PrimaryActionButton extends StatelessWidget {
  final bool isLobby;
  final bool isEndGame;
  final int playerCount;
  final VoidCallback onPressed;

  const _PrimaryActionButton({
    required this.isLobby,
    required this.isEndGame,
    required this.playerCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final skipColor = scheme.secondary;
    final skipOnColor = scheme.onSecondary;
    // During gameplay: red SKIP button with play icon and glow
    if (!isLobby && !isEndGame) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: CBColors.boxGlow(
            skipColor,
            intensity: 0.25,
          ),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: skipColor,
            foregroundColor: skipOnColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.play_arrow, size: 20),
          label: Text(
            'SKIP',
            style: textTheme.labelLarge!.copyWith(color: skipOnColor),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
        ),
      );
    }

    // Lobby & End-game: themed primary button
    final label = isEndGame
        ? 'NEW GAME'
        : (playerCount < 4 ? 'NEED ${4 - playerCount} MORE' : 'START GAME');

    return CBPrimaryButton(
      label: label,
      onPressed: onPressed,
    );
  }
}

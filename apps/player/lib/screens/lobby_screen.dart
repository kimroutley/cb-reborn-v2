import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../active_bridge.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final gameState = ref.watch(activeBridgeProvider).state;

    return CBNeonBackground(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 48),
            children: [
              // ── SYSTEM: CONNECTED ──
              CBMessageBubble(
                sender: 'SYSTEM',
                message: "SECURE CONNECTION ESTABLISHED",
                isSystemMessage: true,
              ),

              // ── WELCOME MESSAGE ──
              CBMessageBubble(
                sender: 'CLUB MANAGER',
                message:
                    "Welcome to Club Blackout. You're on the list. Find a seat and wait for the music to drop.",
                color: scheme.secondary,
              ),

              // ── PLAYER STATUS ──
              if (gameState.myPlayerSnapshot != null)
                CBMessageBubble(
                  sender: 'RESULT',
                  message:
                      "IDENTIFIED AS: ${gameState.myPlayerSnapshot!.name.toUpperCase()}",
                  isSystemMessage: true,
                ),

              // ── ROSTER FEED ──
              CBMessageBubble(
                sender: 'SYSTEM',
                message: "PATRONS ENTERING: ${gameState.players.length}",
                isSystemMessage: true,
              ),

              ...gameState.players.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final isMe = p.id == gameState.myPlayerId;
                return CBFadeSlide(
                  key: ValueKey('lobby_join_${p.id}'),
                  delay: Duration(milliseconds: 24 * idx.clamp(0, 10)),
                  child: CBMessageBubble(
                    sender: 'SECURITY',
                    message: "${p.name.toUpperCase()} has entered the lounge.",
                    color: isMe ? scheme.primary : scheme.tertiary,
                  ),
                );
              }),

              // ── SPACING FOR LOADING ──
              const SizedBox(height: 120),
            ],
          ),

          // ── DYNAMIC FOOTER: WAITING STATUS ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.9),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CBBreathingLoader(size: 32),
                  const SizedBox(height: 20),
                  Text(
                    "WAITING FOR HOST TO START SESSION",
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall!.copyWith(
                      color: scheme.onSurface,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.5),
                          blurRadius: 24,
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "CHECK THE GAME BIBLE IN THE SIDE MENU TO PREP",
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall!.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.3),
                      fontSize: 8,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

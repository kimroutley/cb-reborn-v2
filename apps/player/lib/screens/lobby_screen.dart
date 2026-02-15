import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_drawer.dart';
import '../player_bridge.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final gameState = ref.watch(playerBridgeProvider);

    return CBPrismScaffold(
      title: 'CLUB LOBBY',
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(vertical: CBSpace.x6),
            children: [
              // ── SYSTEM: CONNECTED ──
              CBMessageBubble(
                variant: CBMessageVariant.system,
                content: "SECURE CONNECTION ESTABLISHED",
                accentColor: scheme.primary,
              ),

              // ── WELCOME MESSAGE ──
              CBMessageBubble(
                variant: CBMessageVariant.narrative,
                senderName: "CLUB MANAGER",
                content:
                    "Welcome to Club Blackout. You're on the list. Find a seat and wait for the music to drop.",
                accentColor: scheme.secondary,
                avatar: CBRoleAvatar(
                  color: scheme.secondary,
                  size: 32,
                  pulsing: true,
                ),
              ),

              // ── PLAYER STATUS ──
              if (gameState.myPlayerSnapshot != null)
                CBMessageBubble(
                  variant: CBMessageVariant.result,
                  content:
                      "IDENTIFIED AS: ${gameState.myPlayerSnapshot!.name.toUpperCase()}",
                  accentColor: scheme.tertiary,
                ),

              // ── ROSTER FEED ──
              CBMessageBubble(
                variant: CBMessageVariant.system,
                content: "PATRONS ENTERING: ${gameState.players.length}",
                accentColor: scheme.tertiary,
              ),

              ...gameState.players.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final isMe = p.id == gameState.myPlayerId;
                return CBFadeSlide(
                  key: ValueKey('lobby_join_${p.id}'),
                  delay: Duration(milliseconds: 24 * idx.clamp(0, 10)),
                  child: CBMessageBubble(
                    variant: CBMessageVariant.narrative,
                    senderName: "SECURITY",
                    content: "${p.name.toUpperCase()} has entered the lounge.",
                    accentColor: isMe ? scheme.primary : scheme.tertiary,
                    avatar: CBRoleAvatar(
                      color: isMe ? scheme.primary : scheme.tertiary,
                      size: 32,
                      pulsing: isMe,
                    ),
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
              padding: CBInsets.panel,
              decoration: BoxDecoration(
                color: CBColors.background.withValues(
                  alpha: 0.9,
                ), // Replaced gradient with solid color
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CBBreathingSpinner(size: 32),
                  const SizedBox(height: 20),
                  Text(
                    "WAITING FOR HOST TO START SESSION",
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall!.copyWith(
                      color: scheme.onSurface,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.bold,
                      shadows: CBColors.textGlow(
                        scheme.primary,
                        intensity: 0.5,
                      ),
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

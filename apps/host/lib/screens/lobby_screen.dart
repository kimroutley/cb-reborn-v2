import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_bridge.dart';
import '../providers/lobby_profiles_provider.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/lobby/lobby_access_code_tile.dart';
import '../widgets/lobby/lobby_config_tile.dart';
import '../widgets/lobby/lobby_games_night_banner.dart';
import '../widgets/lobby/lobby_player_list.dart';
import '../widgets/simulation_mode_badge_action.dart';
import 'game_screen.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gameState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final session = ref.watch(sessionProvider);
    final isCloud = gameState.syncMode == SyncMode.cloud;
    final bridge = ref.read(hostBridgeProvider);
    final canStart = gameState.players.length >= 5;
    final profilesAsync = ref.watch(lobbyProfilesProvider);

    return CBPrismScaffold(
      title: 'LOBBY',
      drawer: const CustomDrawer(),
      actions: const [SimulationModeBadgeAction()],
      floatingActionButton: canStart
          ? CBPrimaryButton(
              label: "START SESSION",
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                HapticService.heavy();
                controller.startGame();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const GameScreen()),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: ListView(
        padding: const EdgeInsets.symmetric(
            vertical: CBSpace.x6, horizontal: CBSpace.x5),
        children: [
          // ── SYSTEM: SESSION CREATED ──
          CBMessageBubble(
            variant: CBMessageVariant.system,
            content: "SESSION BROADCAST ACTIVE. STANDBY FOR HANDSHAKE.",
            accentColor:
                theme.colorScheme.primary, // Migrated from CBColors.neonBlue
          ),

          const SizedBox(height: 16),

          // ── ACCESS CODE TILE ──
          LobbyAccessCodeTile(
            bridge: bridge,
            isCloud: isCloud,
            session: session,
            primaryColor: theme.colorScheme.primary,
          ),

          const SizedBox(height: 24),

          // ── SYSTEM: CONFIGURATION ──
          CBSectionHeader(
            title: "NETWORK PROTOCOLS",
            color: theme
                .colorScheme.secondary, // Migrated from CBColors.neonPurple
          ),

          const SizedBox(height: 12),

          LobbyConfigTile(
            gameState: gameState,
            controller: controller,
            primaryColor: theme.colorScheme.primary,
            secondaryColor: theme.colorScheme.secondary,
          ),

          const SizedBox(height: 32),

          // ── GAMES NIGHT BANNER ──
          const LobbyGamesNightBanner(),

          const SizedBox(height: 32),

          // ── SYSTEM: ROSTER STATUS & PLAYER LIST ──
          const LobbyPlayerList(),

          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

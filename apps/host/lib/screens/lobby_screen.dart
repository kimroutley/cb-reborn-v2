import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_bridge.dart';
import '../host_destinations.dart';
import '../host_navigation.dart';
import '../providers/lobby_profiles_provider.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/lobby/lobby_access_code_tile.dart';
import '../widgets/lobby/lobby_config_tile.dart';
import '../widgets/lobby/lobby_games_night_banner.dart';
import '../sheets/manual_role_assignment_sheet.dart';
import '../widgets/lobby/lobby_player_list.dart';
import '../widgets/simulation_mode_badge_action.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  void _showManualRoleAssignmentSheet(BuildContext context, WidgetRef ref) {
    showThemedBottomSheet<void>(
      context: context,
      accentColor: Theme.of(context).colorScheme.secondary,
      child: const ManualRoleAssignmentSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gameState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final session = ref.watch(sessionProvider);
    final isCloud = gameState.syncMode == SyncMode.cloud;
    final bridge = ref.read(hostBridgeProvider);
    final hasMinPlayers = gameState.players.length >= Game.minPlayers;
    final allManuallyAssigned = gameState.players.every(
      (p) => p.role.id != 'unassigned' && p.alliance != Team.unknown,
    );
    final canStart = hasMinPlayers &&
        (gameState.gameStyle != GameStyle.manual || allManuallyAssigned);
    ref.watch(lobbyProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LOBBY'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [SimulationModeBadgeAction()],
      ),
      drawer: const CustomDrawer(),
      floatingActionButton: canStart
          ? CBPrimaryButton(
              label: "START SESSION",
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                HapticService.heavy();
                final started = controller.startGame();
                if (started) {
                  ref
                      .read(hostNavigationProvider.notifier)
                      .setDestination(HostDestination.game);
                } else {
                  HapticService.error();
                }
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: CBNeonBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            vertical: CBSpace.x6,
            horizontal: CBSpace.x5,
          ),
          children: [
            // ── SYSTEM: SESSION CREATED ──
            CBMessageBubble(
              isSystemMessage: true,
              sender: 'System',
              message: "SESSION BROADCAST ACTIVE. STANDBY FOR HANDSHAKE.",
              color: theme.colorScheme.primary,
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
              onManualAssign: () =>
                  _showManualRoleAssignmentSheet(context, ref),
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
      ),
    );
  }
}

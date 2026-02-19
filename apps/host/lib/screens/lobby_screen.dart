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
import '../widgets/lobby/lobby_player_list.dart';
import '../widgets/simulation_mode_badge_action.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  void _showManualRoleAssignmentSheet(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameProvider.notifier);
    final assignableRoles =
        roleCatalog.where((role) => role.id != 'unassigned').toList();

    showThemedBottomSheet<void>(
      context: context,
      accentColor: Theme.of(context).colorScheme.secondary,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final currentState = ref.read(gameProvider);
          final textTheme = Theme.of(context).textTheme;
          final scheme = Theme.of(context).colorScheme;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'MANUAL ROLE ASSIGNMENT',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Drag a role chip onto a player card, or use quick-select.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: assignableRoles
                    .map(
                      (role) => Draggable<String>(
                        data: role.id,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Chip(
                            label: Text(role.name),
                            backgroundColor: Color(int.parse(
                                    role.colorHex.substring(1),
                                    radix: 16) |
                                0xFF000000),
                            labelStyle: textTheme.labelLarge
                                ?.copyWith(color: Colors.black),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.4,
                          child: Chip(label: Text(role.name)),
                        ),
                        child: Chip(
                          label: Text(role.name),
                          avatar: const Icon(Icons.drag_indicator, size: 16),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              ...currentState.players.map(
                (player) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DragTarget<String>(
                    onWillAcceptWithDetails: (details) =>
                        details.data.isNotEmpty,
                    onAcceptWithDetails: (details) {
                      controller.assignRole(player.id, details.data);
                      setModalState(() {});
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovering = candidateData.isNotEmpty;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isHovering
                              ? scheme.secondary.withValues(alpha: 0.18)
                              : scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isHovering
                                ? scheme.secondary
                                : scheme.outline.withValues(alpha: 0.45),
                            width: isHovering ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.name,
                                    style: textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    player.role.id == 'unassigned'
                                        ? 'Unassigned'
                                        : player.role.name,
                                    style: textTheme.labelMedium?.copyWith(
                                      color: player.role.id == 'unassigned'
                                          ? scheme.onSurfaceVariant
                                          : scheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownButton<String>(
                              value: player.role.id == 'unassigned'
                                  ? null
                                  : player.role.id,
                              hint: const Text('Select'),
                              items: roleCatalog
                                  .map(
                                    (role) => DropdownMenuItem<String>(
                                      value: role.id,
                                      child: Text(role.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (roleId) {
                                if (roleId == null) return;
                                controller.assignRole(player.id, roleId);
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CBPrimaryButton(
                label: 'DONE',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      ),
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

    return CBPrismScaffold(
      title: 'LOBBY',
      actions: const [SimulationModeBadgeAction()],
      drawer: const CustomDrawer(),
      floatingActionButton: canStart
          ? CBPrimaryButton(
              label: "START SESSION",
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                HapticService.heavy();
                final started = controller.startGame();
                if (started) {
                  ref.read(hostNavigationProvider.notifier).setDestination(HostDestination.game);
                } else {
                  HapticService.error();
                }
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: ListView(
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
    );
  }
}

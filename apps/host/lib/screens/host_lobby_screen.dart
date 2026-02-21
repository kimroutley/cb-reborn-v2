import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_destinations.dart';
import '../host_navigation.dart';
import '../widgets/bottom_controls.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/lobby/lobby_player_list.dart';
import '../widgets/simulation_mode_badge_action.dart';
import '../sheets/manual_role_assignment_sheet.dart';

class HostLobbyScreen extends ConsumerWidget {
  const HostLobbyScreen({super.key});

  void _showManualRoleAssignmentSheet(BuildContext context) {
    showThemedBottomSheet<void>(
      context: context,
      accentColor: Theme.of(context).colorScheme.secondary,
      child: const ManualRoleAssignmentSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final session = ref.watch(sessionProvider);
    final controller = ref.read(gameProvider.notifier);
    final nav = ref.read(hostNavigationProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasMinPlayers = gameState.players.length >= Game.minPlayers;
    final isManual = gameState.gameStyle == GameStyle.manual;
    final allRolesAssigned = gameState.players.every((p) => p.role.id != 'unassigned');

    final canStart = hasMinPlayers && (!isManual || allRolesAssigned);

    return CBPrismScaffold(
      title: 'LOBBY',
      drawer: const CustomDrawer(currentDestination: HostDestination.lobby),
      actions: const [SimulationModeBadgeAction()],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── SYSTEM STATUS ──
          CBMessageBubble(
            sender: 'SYSTEM',
            message: "ESTABLISHING CLUB CONNECTION... BROADCASTING ON CODE: ${session.joinCode}",
            style: CBMessageStyle.system,
            color: scheme.primary,
          ),

          const SizedBox(height: 24),

          // ── CONFIGURATION PANEL ──
          CBPanel(
            borderColor: scheme.primary.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CBSectionHeader(
                  title: 'NETWORK PROTOCOLS',
                  icon: Icons.settings_input_component_rounded,
                  color: scheme.primary,
                ),
                const SizedBox(height: 16),
                _buildConfigOption(
                  context,
                  'SYNC MODE',
                  gameState.syncMode.name.toUpperCase(),
                  scheme.primary,
                  () {
                    final next = gameState.syncMode == SyncMode.local ? SyncMode.cloud : SyncMode.local;
                    controller.setSyncMode(next);
                  }
                ),
                const SizedBox(height: 12),
                _buildConfigOption(
                  context,
                  'GAME STYLE',
                  gameState.gameStyle.name.toUpperCase(),
                  scheme.secondary,
                  () {
                    // Cycle through styles
                    final styles = GameStyle.values;
                    final next = styles[(gameState.gameStyle.index + 1) % styles.length];
                    controller.setGameStyle(next);
                  }
                ),
                if (isManual) ...[
                  const SizedBox(height: 16),
                  CBPrimaryButton(
                    label: 'ASSIGN ROLES MANUALLY',
                    icon: Icons.badge_rounded,
                    backgroundColor: scheme.secondary.withValues(alpha: 0.2),
                    foregroundColor: scheme.secondary,
                    onPressed: () => _showManualRoleAssignmentSheet(context),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── PLAYER LIST ──
          const LobbyPlayerList(),

          const SizedBox(height: 120),
        ],
      ),
      bottomNavigationBar: BottomControls(
        isLobby: true,
        isEndGame: false,
        playerCount: gameState.players.length,
        onAction: () {
          if (!hasMinPlayers) {
            showThemedSnackBar(
              context,
              'Need at least ${Game.minPlayers} players to open the club.',
              accentColor: scheme.error,
            );
            return;
          }
          if (isManual && !allRolesAssigned) {
            showThemedSnackBar(
              context,
              'Assign all roles manually or change Game Style.',
              accentColor: scheme.secondary,
            );
            return;
          }

          final success = controller.startGame();
          if (success) {
            nav.setDestination(HostDestination.game);
          }
        },
        onAddMock: controller.addBot,
        eyesOpen: gameState.eyesOpen,
        onToggleEyes: controller.toggleEyes,
        onBack: () => nav.setDestination(HostDestination.home),
      ),
    );
  }

  Widget _buildConfigOption(BuildContext context, String label, String value, Color color, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBGlassTile(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderColor: color.withValues(alpha: 0.3),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  shadows: CBColors.textGlow(color, intensity: 0.3),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit_rounded, size: 14, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

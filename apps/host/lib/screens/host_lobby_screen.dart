import 'dart:async';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../cloud_host_bridge.dart';
import '../host_destinations.dart';
import '../host_navigation.dart';
import '../widgets/bottom_controls.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/lobby/lobby_player_list.dart';
import '../widgets/simulation_mode_badge_action.dart';
import '../sheets/manual_role_assignment_sheet.dart';

class HostLobbyScreen extends ConsumerStatefulWidget {
  const HostLobbyScreen({super.key});

  @override
  ConsumerState<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends ConsumerState<HostLobbyScreen> {
  bool _didBootstrapCloud = false;
  bool _isCloudLinkReady = false;
  String? _cloudLinkError;

  static const String _playerJoinHost = 'cb-reborn.web.app';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBootstrapCloud) {
      return;
    }
    _didBootstrapCloud = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapCloudRuntime();
    });
  }

  Future<void> _bootstrapCloudRuntime() async {
    if (!mounted) return;
    setState(() {
      _isCloudLinkReady = false;
      _cloudLinkError = null;
    });

    final controller = ref.read(gameProvider.notifier);
    final syncMode = ref.read(gameProvider).syncMode;
    final bridge = ref.read(cloudHostBridgeProvider);

    if (syncMode != SyncMode.cloud) {
      controller.setSyncMode(SyncMode.cloud);
    }

    try {
      await bridge.start();
      if (!mounted) return;
      setState(() {
        _isCloudLinkReady = bridge.isRunning;
        _cloudLinkError = bridge.isRunning ? null : 'Cloud link inactive';
      });
    } catch (e) {
      debugPrint('[HostLobbyScreen] Cloud bridge start failed: $e');
      if (!mounted) return;
      setState(() {
        _isCloudLinkReady = false;
        _cloudLinkError = 'Cloud link retry required';
      });
    }
  }

  String _buildPlayerJoinUrl(String joinCode) {
    return Uri.https(
      _playerJoinHost,
      '/join',
      {
        'mode': 'cloud',
        'code': joinCode,
        'autoconnect': '1',
      },
    ).toString();
  }

  void _showManualRoleAssignmentSheet(BuildContext context) {
    showThemedBottomSheet<void>(
      context: context,
      accentColor: Theme.of(context).colorScheme.secondary,
      child: const ManualRoleAssignmentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final session = ref.watch(sessionProvider);
    final controller = ref.read(gameProvider.notifier);
    final nav = ref.read(hostNavigationProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final joinUrl = _buildPlayerJoinUrl(session.joinCode);

    final hasMinPlayers = gameState.players.length >= Game.minPlayers;
    final isManual = gameState.gameStyle == GameStyle.manual;
    final allRolesAssigned = gameState.players.every((p) => p.role.id != 'unassigned');

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

          CBPanel(
            borderColor: scheme.primary.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CBSectionHeader(
                  title: 'JOIN BEACON',
                  icon: Icons.qr_code_2_rounded,
                  color: scheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'SCAN TO OPEN PLAYER JOIN SESSION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                CBGlassTile(
                  borderColor: _isCloudLinkReady
                      ? scheme.tertiary.withValues(alpha: 0.45)
                      : (_cloudLinkError == null
                          ? scheme.secondary.withValues(alpha: 0.45)
                          : scheme.error.withValues(alpha: 0.45)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        _isCloudLinkReady
                            ? Icons.cloud_done_rounded
                            : (_cloudLinkError == null
                                ? Icons.cloud_sync_rounded
                                : Icons.cloud_off_rounded),
                        size: 16,
                        color: _isCloudLinkReady
                            ? scheme.tertiary
                            : (_cloudLinkError == null
                                ? scheme.secondary
                                : scheme.error),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isCloudLinkReady
                              ? 'CLOUD LINK: ACTIVE'
                              : (_cloudLinkError == null
                                  ? 'CLOUD LINK: ESTABLISHING...'
                                  : 'CLOUD LINK: RETRY REQUIRED'),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: _isCloudLinkReady
                                    ? scheme.tertiary
                                    : (_cloudLinkError == null
                                        ? scheme.secondary
                                        : scheme.error),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                        ),
                      ),
                      if (_cloudLinkError != null)
                        IconButton(
                          tooltip: 'Retry cloud link',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.refresh_rounded,
                            color: scheme.error,
                            size: 16,
                          ),
                          onPressed: _bootstrapCloudRuntime,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: CBGlassTile(
                    borderColor: scheme.primary.withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(14),
                    child: QrImageView(
                      data: joinUrl,
                      size: 180,
                      version: QrVersions.auto,
                      backgroundColor: scheme.onPrimary,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: scheme.surface,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: scheme.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  joinUrl,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ],
            ),
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
                  label: 'SYNC MODE',
                  currentValue: SyncMode.cloud.name.toUpperCase(),
                  nextValue: 'LOCKED',
                  color: scheme.primary,
                  onTap: () {}
                ),
                const SizedBox(height: 12),
                _buildConfigOption(
                  context,
                  label: 'GAME STYLE',
                  currentValue: gameState.gameStyle.label.toUpperCase(),
                  nextValue: GameStyle.values[(gameState.gameStyle.index + 1) % GameStyle.values.length].label.toUpperCase(),
                  color: scheme.secondary,
                  onTap: () {
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

  Widget _buildConfigOption(
    BuildContext context, {
    required String label,
    required String currentValue,
    required String nextValue,
    required Color color,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBGlassTile(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderColor: color.withValues(alpha: 0.3),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentValue,
                style: textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  shadows: CBColors.textGlow(color, intensity: 0.3),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'NEXT: $nextValue',
                style: textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.cached_rounded, size: 14, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

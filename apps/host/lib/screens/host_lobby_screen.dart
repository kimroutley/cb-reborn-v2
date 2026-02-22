import 'dart:async';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../auth/auth_provider.dart';
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
  static const String _playerJoinHost = 'cb-reborn.web.app';

  Future<void> _bootstrapCloudRuntime() async {
    if (!mounted) return;

    final controller = ref.read(gameProvider.notifier);
    final syncMode = ref.read(gameProvider).syncMode;
    final authState = ref.read(authProvider);
    final bridge = ref.read(cloudHostBridgeProvider);

    if (authState.user == null) {
      showThemedSnackBar(
        context,
        'SIGN IN FIRST TO ESTABLISH CLOUD LINK.',
        accentColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (syncMode != SyncMode.cloud) {
      controller.setSyncMode(SyncMode.cloud);
    }

    try {
      await bridge.start();
      if (!mounted) return;
      showThemedSnackBar(
        context,
        'CLOUD LINK VERIFIED END-TO-END.',
        accentColor: Theme.of(context).colorScheme.tertiary,
      );
    } catch (e) {
      debugPrint('[HostLobbyScreen] Cloud bridge start failed: $e');
      if (!mounted) return;
      showThemedSnackBar(
        context,
        'CLOUD LINK FAILED. RETRY REQUIRED.',
        accentColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<void> _terminateCloudRuntime() async {
    final bridge = ref.read(cloudHostBridgeProvider);
    await bridge.stop();
    if (!mounted) return;
    showThemedSnackBar(
      context,
      'CLOUD LINK OFFLINE.',
      accentColor: Theme.of(context).colorScheme.secondary,
    );
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

  Future<void> _copyToClipboard(
    BuildContext context, {
    required String value,
    required String successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    HapticService.selection();
    showThemedSnackBar(
      context,
      successMessage,
      accentColor: Theme.of(context).colorScheme.tertiary,
    );
  }

  void _showExpandedJoinQrSheet(
    BuildContext context, {
    required String joinUrl,
    required String joinCode,
  }) {
    showThemedDialog<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'JOIN SESSION BEACON',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'CODE: $joinCode',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'RobotoMono',
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Center(
            child: CBGlassTile(
              borderColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: joinUrl,
                size: 260,
                version: QrVersions.auto,
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Theme.of(context).colorScheme.surface,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              CBGhostButton(
                label: 'Copy Code',
                icon: Icons.pin_rounded,
                onPressed: () {
                  Navigator.of(context).pop();
                  _copyToClipboard(
                    context,
                    value: joinCode,
                    successMessage: 'Join code copied.',
                  );
                },
                fullWidth: false,
              ),
              CBPrimaryButton(
                label: 'Copy Link',
                icon: Icons.link_rounded,
                onPressed: () {
                  Navigator.of(context).pop();
                  _copyToClipboard(
                    context,
                    value: joinUrl,
                    successMessage: 'Join link copied.',
                  );
                },
                fullWidth: false,
              ),
            ],
          ),
        ],
      ),
    );
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
    final linkState = ref.watch(cloudLinkStateProvider);
    final scheme = Theme.of(context).colorScheme;
    final joinUrl = _buildPlayerJoinUrl(session.joinCode);
    final isCloudVerified = linkState.isVerified;
    final isCloudBusy = linkState.phase == CloudLinkPhase.initializing ||
        linkState.phase == CloudLinkPhase.publishing ||
        linkState.phase == CloudLinkPhase.verifying;
    final hasCloudError = linkState.phase == CloudLinkPhase.degraded;
    final requiresAuth = linkState.phase == CloudLinkPhase.requiresAuth;
    final cloudStatusKey = linkState.phase.name;

    final hasMinPlayers = gameState.players.length >= Game.minPlayers;
    final isManual = gameState.gameStyle == GameStyle.manual;
    final allRolesAssigned = gameState.players.every(
      (p) => p.role.id != 'unassigned' && p.alliance != Team.unknown,
    );

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
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: CBGlassTile(
                    key: ValueKey(cloudStatusKey),
                  borderColor: isCloudVerified
                        ? scheme.tertiary.withValues(alpha: 0.45)
                    : (hasCloudError
                      ? scheme.error.withValues(alpha: 0.45)
                      : (requiresAuth
                        ? scheme.secondary.withValues(alpha: 0.45)
                        : scheme.primary.withValues(alpha: 0.35))),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                      isCloudVerified
                              ? Icons.cloud_done_rounded
                        : (hasCloudError
                          ? Icons.cloud_off_rounded
                          : (requiresAuth
                            ? Icons.lock_outline_rounded
                            : Icons.cloud_sync_rounded)),
                          size: 16,
                      color: isCloudVerified
                              ? scheme.tertiary
                        : (hasCloudError
                          ? scheme.error
                          : (requiresAuth
                            ? scheme.secondary
                            : scheme.primary)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                      isCloudVerified
                        ? 'CLOUD LINK: VERIFIED'
                        : (hasCloudError
                          ? 'CLOUD LINK: DEGRADED'
                          : (requiresAuth
                            ? 'CLOUD LINK: SIGN-IN REQUIRED'
                            : (isCloudBusy
                              ? 'CLOUD LINK: ESTABLISHING...'
                              : 'CLOUD LINK: OFFLINE'))),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                          color: isCloudVerified
                                      ? scheme.tertiary
                            : (hasCloudError
                              ? scheme.error
                              : (requiresAuth
                                ? scheme.secondary
                                : scheme.primary)),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                          ),
                        ),
                    if (hasCloudError)
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
                ),
                if ((linkState.message ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    linkState.message!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CBPrimaryButton(
                        label:
                            isCloudVerified ? 'RE-VERIFY LINK' : 'ESTABLISH LINK',
                        icon: Icons.cloud_sync_rounded,
                        onPressed: isCloudBusy ? null : _bootstrapCloudRuntime,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CBGhostButton(
                        label: 'GO OFFLINE',
                        icon: Icons.cloud_off_rounded,
                        color: scheme.secondary,
                        onPressed: isCloudBusy ? null : _terminateCloudRuntime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: isCloudVerified ? 1 : 0.82,
                  child: CBGlassTile(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    borderColor: scheme.primary.withValues(alpha: 0.35),
                    child: Row(
                      children: [
                        Icon(
                          Icons.pin_rounded,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'JOIN CODE: ${session.joinCode}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontFamily: 'RobotoMono',
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy code',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            _copyToClipboard(
                              context,
                              value: session.joinCode,
                              successMessage: 'Join code copied.',
                            );
                          },
                          icon: Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    scale: isCloudVerified ? 1 : 0.97,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        _showExpandedJoinQrSheet(
                          context,
                          joinUrl: joinUrl,
                          joinCode: session.joinCode,
                        );
                      },
                      child: CBGlassTile(
                        borderColor: scheme.primary.withValues(alpha: 0.4),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QrImageView(
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
                            const SizedBox(height: 8),
                            Text(
                              isCloudVerified
                                  ? 'TAP TO EXPAND'
                                : 'LINK NOT VERIFIED YET',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: scheme.primary.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CBGlassTile(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  borderColor: scheme.primary.withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          joinUrl,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.primary,
                                fontFamily: 'RobotoMono',
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Copy join link',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          _copyToClipboard(
                            context,
                            value: joinUrl,
                            successMessage: 'Join link copied.',
                          );
                        },
                        icon: Icon(
                          Icons.link_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

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
                    const styles = GameStyle.values;
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

          const SizedBox(height: 28),

          // ── PLAYER LIST ──
          const LobbyPlayerList(),

          const SizedBox(height: 24),

          BottomControls(
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
                  'Manual start requires every player to have role + alliance. Complete assignment first.',
                  accentColor: scheme.secondary,
                );
                return;
              }

              final success = controller.startGame();
              if (success) {
                nav.setDestination(HostDestination.game);
              } else {
                if (gameState.phase != GamePhase.lobby) {
                  showThemedSnackBar(
                    context,
                    'SESSION ALREADY ACTIVE. OPENING COMMAND SCREEN.',
                    accentColor: scheme.tertiary,
                  );
                  nav.setDestination(HostDestination.game);
                  return;
                }

                showThemedSnackBar(
                  context,
                  'Unable to start session. Check roster and setup.',
                  accentColor: scheme.error,
                );
              }
            },
            onAddMock: controller.addBot,
            eyesOpen: gameState.eyesOpen,
            onToggleEyes: controller.toggleEyes,
            onBack: () => nav.setDestination(HostDestination.home),
            requiredPlayers: Game.minPlayers,
          ),

          const SizedBox(height: 28),
        ],
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
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentValue,
                style: textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  fontFamily: 'RobotoMono',
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
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
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

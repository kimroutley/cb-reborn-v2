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
import '../widgets/custom_drawer.dart';
import '../widgets/lobby/lobby_player_list.dart';
import '../widgets/simulation_mode_badge_action.dart';
import '../sheets/game_settings_sheet.dart';

class HostLobbyScreen extends ConsumerStatefulWidget {
  const HostLobbyScreen({super.key});

  @override
  ConsumerState<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends ConsumerState<HostLobbyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  static const String _playerJoinHost = 'cb-reborn.web.app';

  Future<void> _bootstrapCloudRuntime() async {
    if (!mounted) return;
    final controller = ref.read(gameProvider.notifier);
    final syncMode = ref.read(gameProvider).syncMode;
    final authState = ref.read(authProvider);
    final bridge = ref.read(cloudHostBridgeProvider);

    if (authState.user == null) {
      _showSnack('SIGN IN REQUIRED TO ESTABLISH LINK', isError: true);
      return;
    }
    if (syncMode != SyncMode.cloud) controller.setSyncMode(SyncMode.cloud);

    try {
      await bridge.start();
      if (!mounted) return;
      _showSnack('CLOUD LINK ESTABLISHED');
      HapticService.medium();
    } catch (e) {
      debugPrint('[HostLobbyScreen] Cloud bridge start failed: $e');
      if (!mounted) return;
      _showSnack('CLOUD LINK FAILED. RETRYING...', isError: true);
    }
  }

  Future<void> _terminateCloudRuntime() async {
    final gameState = ref.read(gameProvider);
    final bridge = ref.read(cloudHostBridgeProvider);
    if (gameState.syncMode == SyncMode.cloud && bridge.isRunning) {
      try {
        await bridge.deleteGame();
      } catch (error) {
        debugPrint('[HostLobbyScreen] Cloud cleanup failed: $error');
        if (mounted) {
          _showSnack('STALE DATA PERSISTS ON SERVER',
              isError: true);
        }
      }
    }
    await bridge.stop();
    if (!mounted) return;
    _showSnack('CLOUD LINK DEACTIVATED');
    HapticService.light();
  }

  String _buildPlayerJoinUrl(String joinCode) {
    return Uri.https(_playerJoinHost, '/join', {
      'mode': 'cloud',
      'code': joinCode,
    }).toString();
  }

  Future<void> _copyToClipboard(
    BuildContext context, {
    required String value,
    required String successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    HapticService.selection();
    _showSnack(successMessage.toUpperCase());
  }

  void _showSnack(String message, {bool isError = false}) {
    showThemedSnackBar(
      context,
      message,
      accentColor: isError
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.tertiary,
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
    final isOnline = linkState.isVerified;
    final hasError = linkState.phase == CloudLinkPhase.degraded;
    final isConnecting = linkState.phase == CloudLinkPhase.initializing ||
        linkState.phase == CloudLinkPhase.publishing ||
        linkState.phase == CloudLinkPhase.verifying;
    final playerCount = gameState.players.length;
    final canStart = playerCount >= Game.minPlayers;

    return CBPrismScaffold(
      title: 'COMMAND LOBBY',
      drawer: const CustomDrawer(currentDestination: HostDestination.lobby),
      actions: const [SimulationModeBadgeAction()],
      appBarBottom: TabBar(
        controller: _tabController,
        indicatorColor: scheme.primary,
        indicatorWeight: 3,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.4),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          fontSize: 10,
        ),
        tabs: const [
          Tab(text: 'OPERATIVES', icon: Icon(Icons.groups_3_rounded, size: 18)),
          Tab(text: 'RECRUIT', icon: Icon(Icons.qr_code_2_rounded, size: 18)),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _NetworkBar(
              isOnline: isOnline,
              isConnecting: isConnecting,
              hasError: hasError,
              onToggle: (val) {
                if (val) {
                  _bootstrapCloudRuntime();
                } else {
                  _terminateCloudRuntime();
                }
              },
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  // ── Tab 1: OPERATIVES ──
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: CBGhostButton(
                                label: 'GAME CONFIG',
                                icon: Icons.tune_rounded,
                                color: scheme.primary,
                                onPressed: () => showThemedBottomSheet(
                                  context: context,
                                  child: const GameSettingsSheet(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CBGhostButton(
                                label: 'ADD BOT',
                                icon: Icons.smart_toy_rounded,
                                color: scheme.tertiary,
                                onPressed: () {
                                  HapticService.medium();
                                  controller.addBot();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: LobbyPlayerList(),
                        ),
                      ),
                    ],
                  ),

                  // ── Tab 2: RECRUIT ──
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      CBFadeSlide(
                        child: _JoinCard(
                          joinCode: session.joinCode,
                          joinUrl: joinUrl,
                          isOnline: isOnline,
                          onCopyCode: () => _copyToClipboard(
                            context,
                            value: session.joinCode,
                            successMessage: 'Join code copied',
                          ),
                          onCopyLink: () => _copyToClipboard(
                            context,
                            value: joinUrl,
                            successMessage: 'Invite link copied',
                          ),
                          onExpandQr: () => _showQrDialog(
                            context,
                            joinUrl: joinUrl,
                            joinCode: session.joinCode,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CBFadeSlide(
                        delay: const Duration(milliseconds: 100),
                        child: _ConnectionHints(
                          joinCode: session.joinCode,
                          isOnline: isOnline,
                          scheme: scheme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            _LaunchBar(
              canStart: canStart,
              playerCount: playerCount,
              minPlayers: Game.minPlayers,
              onContinue: () {
                HapticService.heavy();
                nav.setDestination(HostDestination.gameSetup);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQrDialog(
    BuildContext context, {
    required String joinUrl,
    required String joinCode,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showThemedDialog<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SCAN TO RECRUIT',
            style: textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CBColors.voidBlack,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: CBColors.boxGlow(scheme.primary, intensity: 0.4),
              ),
              child: QrImageView(
                data: joinUrl,
                size: 240,
                version: QrVersions.auto,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: scheme.primary,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: scheme.primary,
                ),
                backgroundColor: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            joinCode,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w900,
              letterSpacing: 8.0,
              color: scheme.primary,
              shadows: CBColors.textGlow(scheme.primary, intensity: 0.8),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: CBGhostButton(
                  label: 'COPY CODE',
                  icon: Icons.content_copy_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _copyToClipboard(
                      context,
                      value: joinCode,
                      successMessage: 'Code copied',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CBPrimaryButton(
                  label: 'COPY LINK',
                  icon: Icons.link_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _copyToClipboard(
                      context,
                      value: joinUrl,
                      successMessage: 'Link copied',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetworkBar extends StatelessWidget {
  final bool isOnline;
  final bool isConnecting;
  final bool hasError;
  final ValueChanged<bool> onToggle;

  const _NetworkBar({
    required this.isOnline,
    required this.isConnecting,
    required this.hasError,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Color accent;
    final String label;
    final IconData icon;

    if (isOnline) {
      accent = scheme.tertiary;
      label = 'COMM LINK ACTIVE';
      icon = Icons.cloud_done_rounded;
    } else if (isConnecting) {
      accent = scheme.secondary;
      label = 'ESTABLISHING LINK...';
      icon = Icons.cloud_sync_rounded;
    } else if (hasError) {
      accent = scheme.error;
      label = 'LINK DEGRADED - TAP TO RETRY';
      icon = Icons.cloud_off_rounded;
    } else {
      accent = scheme.onSurface.withValues(alpha: 0.4);
      label = 'OFFLINE';
      icon = Icons.cloud_off_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: CBGlassTile(
        isPrismatic: isOnline,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderColor: accent.withValues(alpha: 0.4),
        child: Row(
          children: [
            if (isConnecting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(icon, size: 18, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontFamily: 'RobotoMono',
                ),
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: CBSwitch(
                value: isOnline,
                color: accent,
                onChanged: isConnecting ? null : onToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  final String joinCode;
  final String joinUrl;
  final bool isOnline;
  final VoidCallback onCopyCode;
  final VoidCallback onCopyLink;
  final VoidCallback onExpandQr;

  const _JoinCard({
    required this.joinCode,
    required this.joinUrl,
    required this.isOnline,
    required this.onCopyCode,
    required this.onCopyLink,
    required this.onExpandQr,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBGlassTile(
      isPrismatic: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onExpandQr,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CBColors.voidBlack,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: CBColors.boxGlow(scheme.primary, intensity: 0.2),
              ),
              child: QrImageView(
                data: joinUrl,
                size: 140,
                version: QrVersions.auto,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: scheme.primary,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: scheme.primary,
                ),
                backgroundColor: CBColors.voidBlack,
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onCopyCode,
            child: Text(
              joinCode,
              style: textTheme.headlineMedium?.copyWith(
                fontFamily: 'RobotoMono',
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: scheme.primary,
                shadows: CBColors.textGlow(scheme.primary, intensity: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RecruitActionButton(
                icon: Icons.content_copy_rounded,
                label: 'CODE',
                onPressed: onCopyCode,
              ),
              const SizedBox(width: 16),
              _RecruitActionButton(
                icon: Icons.link_rounded,
                label: 'LINK',
                onPressed: onCopyLink,
              ),
              const SizedBox(width: 16),
              _RecruitActionButton(
                icon: Icons.fullscreen_rounded,
                label: 'QR',
                onPressed: onExpandQr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecruitActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _RecruitActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        IconButton.filledTonal(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: scheme.primary.withValues(alpha: 0.1),
            foregroundColor: scheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: scheme.primary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _LaunchBar extends StatelessWidget {
  final bool canStart;
  final int playerCount;
  final int minPlayers;
  final VoidCallback onContinue;

  const _LaunchBar({
    required this.canStart,
    required this.playerCount,
    required this.minPlayers,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final missing = (minPlayers - playerCount).clamp(0, minPlayers);

    final String statusText;
    final Color statusColor;
    final IconData statusIcon;

    if (!canStart) {
      statusText = 'NEED $missing MORE';
      statusColor = scheme.secondary;
      statusIcon = Icons.person_add_rounded;
    } else {
      statusText = '$playerCount JOINED';
      statusColor = scheme.tertiary;
      statusIcon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: statusColor.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CBPrimaryButton(
                label: 'CONTINUE TO SETUP',
                icon: Icons.chevron_right_rounded,
                onPressed: canStart ? onContinue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionHints extends StatelessWidget {
  final String joinCode;
  final bool isOnline;
  final ColorScheme scheme;

  const _ConnectionHints({
    required this.joinCode,
    required this.isOnline,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CBFeedSeparator(label: 'RECRUITMENT INTEL'),
        const SizedBox(height: 20),
        _hintRow(
          context,
          Icons.qr_code_scanner_rounded,
          'BIOMETRIC SCAN',
          'Players scan the uplink code with their terminal camera.',
        ),
        const SizedBox(height: 16),
        _hintRow(
          context,
          Icons.vpn_key_rounded,
          'MANUAL OVERRIDE',
          'Type code $joinCode directly into the join terminal.',
        ),
        const SizedBox(height: 16),
        _hintRow(
          context,
          Icons.share_rounded,
          'SECURE UPLINK',
          'Dispatch join credentials via encrypted messaging.',
        ),
        if (!isOnline) ...[
          const SizedBox(height: 24),
          CBGlassTile(
            borderColor: scheme.error.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: scheme.error, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'COMM LINK IS OFFLINE. PLAYERS CANNOT CONNECT UNTIL ACTIVATED.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w900,
                      height: 1.4,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _hintRow(
      BuildContext ctx, IconData icon, String title, String desc) {
    final scheme = Theme.of(ctx).colorScheme;
    final textTheme = Theme.of(ctx).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

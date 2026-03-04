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
import 'host_chat_view.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
      _showSnack(
        'AUTHORIZATION REQUIRED: SIGN IN TO ENABLE UPLINK.',
        isError: true,
      );
      return;
    }

    if (syncMode != SyncMode.cloud) {
      controller.setSyncMode(SyncMode.cloud);
    }

    try {
      await bridge.start();
      if (!mounted) return;
      _showSnack(
        'UPLINK ESTABLISHED: SECURE CHANNEL ACTIVE.',
        isError: false,
      );
    } catch (e) {
      debugPrint('[HostLobbyScreen] Cloud bridge start failed: $e');
      if (!mounted) return;
      _showSnack(
        'UPLINK FAILED: RETRY PROTOCOL INITIATED.',
        isError: true,
      );
    }
  }

  Future<void> _terminateCloudRuntime() async {
    final bridge = ref.read(cloudHostBridgeProvider);
    await bridge.stop();
    if (!mounted) return;
    _showSnack(
      'UPLINK DISCONNECTED: GOING DARK.',
      isError: false,
    );
  }

  String _buildPlayerJoinUrl(String joinCode) {
    return Uri.https(
      _playerJoinHost,
      '/download.html',
      {
        'code': joinCode,
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
    _showSnack(successMessage, isError: false);
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

  void _showExpandedJoinQrSheet(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded,
                  color: scheme.primary, size: 28),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: Text(
                  'ACCESS BEACON',
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CBSpace.x6),
          Center(
            child: CBPanel(
              padding: CBInsets.screen,
              borderColor: scheme.primary,
              child: QrImageView(
                data: joinUrl,
                size: 240,
                version: QrVersions.auto,
                backgroundColor: scheme.surface,
              ),
            ),
          ),
          const SizedBox(height: CBSpace.x6),
          Text(
            'ACCESS KEY',
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: CBSpace.x1),
          Text(
            joinCode,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              color: scheme.onSurface,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w900,
              letterSpacing: 4.0,
              shadows: CBColors.textGlow(scheme.primary, intensity: 0.4),
            ),
          ),
          const SizedBox(height: CBSpace.x8),
          Row(
            children: [
              Expanded(
                child: CBGhostButton(
                  label: 'COPY KEY',
                  icon: Icons.copy_rounded,
                  onPressed: () {
                    HapticService.light();
                    Navigator.of(context).pop();
                    _copyToClipboard(
                      context,
                      value: joinCode,
                      successMessage: 'ACCESS KEY ARCHIVED.',
                    );
                  },
                ),
              ),
              const SizedBox(width: CBSpace.x4),
              Expanded(
                child: CBPrimaryButton(
                  label: 'SHARE LINK',
                  icon: Icons.share_rounded,
                  onPressed: () {
                    HapticService.medium();
                    Navigator.of(context).pop();
                    _copyToClipboard(
                      context,
                      value: joinUrl,
                      successMessage: 'UPLINK URL ARCHIVED.',
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

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final session = ref.watch(sessionProvider);
    final controller = ref.read(gameProvider.notifier);
    final nav = ref.read(hostNavigationProvider.notifier);
    final linkState = ref.watch(cloudLinkStateProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final joinUrl = _buildPlayerJoinUrl(session.joinCode);

    final isCloudVerified = linkState.isVerified;
    final hasCloudError = linkState.phase == CloudLinkPhase.degraded;

    final statusColor = isCloudVerified
        ? scheme.tertiary
        : (hasCloudError ? scheme.error : scheme.onSurfaceVariant);

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
          Tab(
              text: 'THE LOUNGE',
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 18)),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ─── NETWORK STATUS BAR ───
            Padding(
              padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x2, CBSpace.x4, 0),
              child: CBGlassTile(
                isPrismatic: isCloudVerified,
                padding:
                    const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: CBSpace.x2),
                borderColor: statusColor.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    Icon(Icons.hub_rounded, size: 18, color: statusColor),
                    const SizedBox(width: CBSpace.x3),
                    Expanded(
                      child: Text(
                        'PROTOCOL: ${isCloudVerified ? "UPLINK SECURE" : "UPLINK OFFLINE"}',
                        style: textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: CBSwitch(
                        value: isCloudVerified,
                        color: scheme.tertiary,
                        onChanged: (val) {
                          HapticService.selection();
                          if (val) {
                            _bootstrapCloudRuntime();
                          } else {
                            _terminateCloudRuntime();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── TABBED CONTENT ───
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  // ── Tab 1: OPERATIVES ──
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, CBSpace.x2),
                        child: Row(
                          children: [
                            Expanded(
                              child: CBGhostButton(
                                label: 'GAME CONFIG',
                                icon: Icons.tune_rounded,
                                color: scheme.primary,
                                onPressed: () {
                                  HapticService.light();
                                  showThemedBottomSheet(
                                    context: context,
                                    child: const GameSettingsSheet(),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: CBSpace.x3),
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
                          padding: EdgeInsets.symmetric(horizontal: CBSpace.x4),
                          child: LobbyPlayerList(),
                        ),
                      ),
                    ],
                  ),

                  // ── Tab 2: RECRUIT ──
                  ListView(
                    padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, CBSpace.x6),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      CBFadeSlide(
                        child: _JoinCard(
                          joinCode: session.joinCode,
                          joinUrl: joinUrl,
                          isOnline: isCloudVerified,
                          onCopyCode: () => _copyToClipboard(
                            context,
                            value: session.joinCode,
                            successMessage: 'JOIN CODE ARCHIVED.',
                          ),
                          onCopyLink: () => _copyToClipboard(
                            context,
                            value: joinUrl,
                            successMessage: 'INVITE URL ARCHIVED.',
                          ),
                          onExpandQr: () {
                            HapticService.medium();
                            _showExpandedJoinQrSheet(
                              context,
                              joinUrl: joinUrl,
                              joinCode: session.joinCode,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: CBSpace.x6),
                      CBFadeSlide(
                        delay: const Duration(milliseconds: 100),
                        child: _ConnectionHints(
                          joinCode: session.joinCode,
                          isOnline: isCloudVerified,
                          scheme: scheme,
                        ),
                      ),
                    ],
                  ),

                  // ── Tab 3: THE LOUNGE ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
                    child: HostChatView(
                      gameState: gameState,
                      showHeader: false,
                      showRoster: true,
                    ),
                  ),
                ],
              ),
            ),

            // ─── LAUNCH BAR ───
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
      padding: CBInsets.panel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onExpandQr,
            child: Container(
              padding: CBInsets.screen,
              decoration: BoxDecoration(
                color: CBColors.voidBlack,
                borderRadius: BorderRadius.circular(CBRadius.lg),
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
          const SizedBox(height: CBSpace.x5),
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
          const SizedBox(height: CBSpace.x6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RecruitActionButton(
                icon: Icons.content_copy_rounded,
                label: 'CODE',
                onPressed: onCopyCode,
              ),
              const SizedBox(width: CBSpace.x4),
              _RecruitActionButton(
                icon: Icons.link_rounded,
                label: 'LINK',
                onPressed: onCopyLink,
              ),
              const SizedBox(width: CBSpace.x4),
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
        const SizedBox(height: CBSpace.x1),
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
      padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, CBSpace.x4),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top:
              BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: CBSpace.x3, vertical: CBSpace.x2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(CBRadius.sm),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: CBSpace.x2),
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
            const SizedBox(width: CBSpace.x4),
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
        const SizedBox(height: CBSpace.x5),
        _hintRow(
          context,
          Icons.qr_code_scanner_rounded,
          'BIOMETRIC SCAN',
          'PLAYERS SCAN THE UPLINK CODE WITH THEIR TERMINAL CAMERA.',
        ),
        const SizedBox(height: CBSpace.x4),
        _hintRow(
          context,
          Icons.vpn_key_rounded,
          'MANUAL OVERRIDE',
          'TYPE CODE $joinCode DIRECTLY INTO THE JOIN TERMINAL.',
        ),
        const SizedBox(height: CBSpace.x4),
        _hintRow(
          context,
          Icons.share_rounded,
          'SECURE UPLINK',
          'DISPATCH JOIN CREDENTIALS VIA ENCRYPTED MESSAGING.',
        ),
        if (!isOnline) ...[
          const SizedBox(height: CBSpace.x6),
          CBGlassTile(
            borderColor: scheme.error.withValues(alpha: 0.4),
            padding: CBInsets.screen,
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: scheme.error, size: 20),
                const SizedBox(width: CBSpace.x4),
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

  Widget _hintRow(BuildContext ctx, IconData icon, String title, String desc) {
    final scheme = Theme.of(ctx).colorScheme;
    final textTheme = Theme.of(ctx).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(CBSpace.x2),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(CBRadius.sm),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
        const SizedBox(width: CBSpace.x4),
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
              const SizedBox(height: CBSpace.x1),
              Text(
                desc.toUpperCase(),
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
      _showSnack('Sign in required to go online.', isError: true);
      return;
    }
    if (syncMode != SyncMode.cloud) controller.setSyncMode(SyncMode.cloud);

    try {
      await bridge.start();
      if (!mounted) return;
      _showSnack('Cloud link active.');
    } catch (e) {
      debugPrint('[HostLobbyScreen] Cloud bridge start failed: $e');
      if (!mounted) return;
      _showSnack('Cloud link failed. Retry.', isError: true);
    }
  }

  Future<void> _terminateCloudRuntime() async {
    final bridge = ref.read(cloudHostBridgeProvider);
    await bridge.stop();
    if (!mounted) return;
    _showSnack('Cloud link offline.');
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
    _showSnack(successMessage);
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
      title: 'THE LOBBY',
      drawer: const CustomDrawer(currentDestination: HostDestination.lobby),
      actions: const [SimulationModeBadgeAction()],
      appBarBottom: TabBar(
        controller: _tabController,
        indicatorColor: scheme.primary,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.5),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontSize: 11,
        ),
        tabs: const [
          Tab(text: 'ROSTER', icon: Icon(Icons.groups_rounded, size: 18)),
          Tab(text: 'CONNECT', icon: Icon(Icons.qr_code_rounded, size: 18)),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ─── NETWORK STATUS BAR (persistent) ───
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

            // ─── TABBED CONTENT ───
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Tab 1: ROSTER ──
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: _GlassIconButton(
                                icon: Icons.tune_rounded,
                                tooltip: 'Timer & tie-break settings',
                                color: scheme.primary,
                                onTap: () => showThemedBottomSheet(
                                  context: context,
                                  child: const GameSettingsSheet(),
                                ),
                                expanded: true,
                                label: 'CONFIG',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _GlassIconButton(
                                icon: Icons.smart_toy_rounded,
                                tooltip: 'Add bot player',
                                color: scheme.tertiary,
                                onTap: () {
                                  HapticService.light();
                                  controller.addBot();
                                },
                                expanded: true,
                                label: 'ADD BOT',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: LobbyPlayerList(),
                        ),
                      ),
                    ],
                  ),

                  // ── Tab 2: CONNECT ──
                  ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    children: [
                      _JoinCard(
                        joinCode: session.joinCode,
                        joinUrl: joinUrl,
                        isOnline: isOnline,
                        onCopyCode: () => _copyToClipboard(
                          context,
                          value: session.joinCode,
                          successMessage: 'Code copied.',
                        ),
                        onCopyLink: () => _copyToClipboard(
                          context,
                          value: joinUrl,
                          successMessage: 'Link copied.',
                        ),
                        onExpandQr: () => _showQrDialog(
                          context,
                          joinUrl: joinUrl,
                          joinCode: session.joinCode,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ConnectionHints(
                        joinCode: session.joinCode,
                        isOnline: isOnline,
                        scheme: scheme,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── LAUNCH BAR (persistent) ───
            _LaunchBar(
              canStart: canStart,
              playerCount: playerCount,
              minPlayers: Game.minPlayers,
              onContinue: () {
                HapticFeedback.heavyImpact();
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
            'SCAN TO ENTER',
            style: textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.3),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: QrImageView(
                data: joinUrl,
                size: 220,
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
          const SizedBox(height: 24),
          Text(
            joinCode,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w900,
              letterSpacing: 6.0,
              color: scheme.primary,
              shadows: CBColors.textGlow(scheme.primary, intensity: 0.6),
            ),
          ),
          const SizedBox(height: 24),
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
                      successMessage: 'Code copied.',
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
                      successMessage: 'Link copied.',
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

// ─── NETWORK BAR ─────────────────────────────────────────────

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
      label = 'ONLINE';
      icon = Icons.cloud_done_rounded;
    } else if (isConnecting) {
      accent = scheme.secondary;
      label = 'CONNECTING...';
      icon = Icons.cloud_sync_rounded;
    } else if (hasError) {
      accent = scheme.error;
      label = 'OFFLINE - TAP TO RETRY';
      icon = Icons.cloud_off_rounded;
    } else {
      accent = scheme.onSurfaceVariant;
      label = 'OFFLINE';
      icon = Icons.cloud_off_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: CBGlassTile(
        isPrismatic: isOnline,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        borderColor: accent.withValues(alpha: 0.4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 280;
            final labelWidget = Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontFamily: 'RobotoMono',
              ),
            );
            final switchWidget = SizedBox(
              height: 28,
              child: Switch.adaptive(
                value: isOnline,
                activeTrackColor: accent,
                onChanged: isConnecting ? null : onToggle,
              ),
            );
            if (isCompact) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: accent),
                      const SizedBox(width: 8),
                      if (isConnecting)
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: accent,
                          ),
                        ),
                      if (isConnecting) const SizedBox(width: 6),
                      Expanded(child: labelWidget),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerRight, child: switchWidget),
                ],
              );
            }
            return Row(
              children: [
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: 10),
                if (isConnecting)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: accent,
                    ),
                  ),
                if (isConnecting) const SizedBox(width: 8),
                Flexible(child: labelWidget),
                const Spacer(),
                switchWidget,
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── JOIN CARD ───────────────────────────────────────────────

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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR Code (phone-friendly — tap to expand)
          GestureDetector(
            onTap: onExpandQr,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160, maxHeight: 160),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: joinUrl,
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
          ),
          const SizedBox(height: 12),

          // Join Code (hero text)
          GestureDetector(
            onTap: onCopyCode,
            child: Text(
              joinCode,
              style: textTheme.headlineMedium?.copyWith(
                fontFamily: 'RobotoMono',
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: scheme.primary,
                shadows: CBColors.textGlow(scheme.primary, intensity: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Action row: icon buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GlassIconButton(
                icon: Icons.content_copy_rounded,
                tooltip: 'Copy code',
                color: scheme.primary,
                onTap: onCopyCode,
              ),
              const SizedBox(width: 12),
              _GlassIconButton(
                icon: Icons.link_rounded,
                tooltip: 'Copy link',
                color: scheme.primary,
                onTap: onCopyLink,
              ),
              const SizedBox(width: 12),
              _GlassIconButton(
                icon: Icons.fullscreen_rounded,
                tooltip: 'Expand QR',
                color: scheme.primary,
                onTap: onExpandQr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── LAUNCH BAR ─────────────────────────────────────────────

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

    final String badgeText;
    final Color badgeColor;
    final IconData badgeIcon;

    if (!canStart) {
      badgeText = 'NEED $missing MORE';
      badgeColor = scheme.secondary;
      badgeIcon = Icons.group_add_rounded;
    } else {
      badgeText = '$playerCount JOINED';
      badgeColor = scheme.tertiary;
      badgeIcon = Icons.check_circle_rounded;
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            badgeText,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              fontFamily: 'RobotoMono',
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: CBGlassTile(
        isPrismatic: canStart,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderColor: canStart
            ? scheme.primary.withValues(alpha: 0.5)
            : scheme.onSurfaceVariant.withValues(alpha: 0.3),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 380;
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(alignment: Alignment.centerLeft, child: badge),
                    const SizedBox(height: 10),
                    CBPrimaryButton(
                      label: 'CONTINUE TO SETUP',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: canStart ? onContinue : null,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Flexible(flex: 0, child: badge),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CBPrimaryButton(
                      label: 'CONTINUE TO SETUP',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: canStart ? onContinue : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── CONNECTION HINTS (CONNECT TAB) ─────────────────────────

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
        Text(
          'HOW TO JOIN',
          style: textTheme.labelSmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        _hintRow(
          context,
          Icons.qr_code_scanner_rounded,
          'SCAN QR',
          'Players scan the QR code above with their phone camera.',
        ),
        const SizedBox(height: 10),
        _hintRow(
          context,
          Icons.keyboard_rounded,
          'ENTER CODE',
          'Open the Player app and type code $joinCode on the connect screen.',
        ),
        const SizedBox(height: 10),
        _hintRow(
          context,
          Icons.link_rounded,
          'SHARE LINK',
          'Copy the join link and send it via any messaging app.',
        ),
        if (!isOnline) ...[
          const SizedBox(height: 16),
          CBGlassTile(
            borderColor: scheme.error.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.wifi_off_rounded,
                    color: scheme.error, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Toggle ONLINE above so players can connect from their devices.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon, size: 16, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
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

// ─── REUSABLE GLASS ICON BUTTON ─────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final bool expanded;
  final String? label;

  const _GlassIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.expanded = false,
    this.label,
  });

  static const double _minTouchTarget = 44;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      type: MaterialType.transparency,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () {
            HapticService.selection();
            onTap();
          },
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _minTouchTarget,
              minHeight: _minTouchTarget,
            ),
            child: Container(
              padding: expanded
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                  : const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: expanded && label != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label!,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  )
                : Icon(icon, size: 20, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

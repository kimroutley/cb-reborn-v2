import 'package:cb_player/auth/auth_provider.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cb_models/cb_models.dart';
import '../active_bridge.dart';
import '../player_bridge.dart';
import '../player_onboarding_provider.dart';
import '../widgets/custom_drawer.dart';
import 'player_home_shell.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  static const int _minimumPlayersHintThreshold = 4;
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final seenGuide = prefs.getBool('player_guide_seen') ?? false;
        if (!seenGuide && mounted) {
          await _showPlayerGuideDialog(context);
          await prefs.setBool('player_guide_seen', true);
        }
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final player = ref.read(activeBridgeProvider).state.myPlayerSnapshot;
    if (player == null) {
      // If player is not claimed yet, send as a generic 'lounge' user
      ref.read(activeBridgeProvider).actions.sendBulletin(
        title: 'LOUNGE', // Generic name for unclaimed players
        floatContent: text,
        roleId: null, // No role assigned yet
      );
    } else {
      ref.read(activeBridgeProvider).actions.sendBulletin(
        title: player.roleName, // This will be 'Unassigned' in lobby, which is fine
        floatContent: text,
        roleId: player.roleId,
      );
    }

    _chatController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _showPlayerGuideDialog(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showThemedDialog(
      context: context,
      accentColor: scheme.secondary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'WELCOME, PATRON',
            style: textTheme.headlineSmall!.copyWith(
              color: scheme.secondary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              shadows: CBColors.textGlow(scheme.secondary),
            ),
          ),
          const SizedBox(height: 24),
          _buildGuideRow(
            context,
            Icons.chat_bubble_outline_rounded,
            'STAY INFORMED',
            'Watch the feed for game events, narrative clues, and voting results.',
          ),
          const SizedBox(height: 16),
          _buildGuideRow(
            context,
            Icons.fingerprint_rounded,
            'YOUR IDENTITY',
            'When the game starts, hold your identity card to reveal your secret role.',
          ),
          const SizedBox(height: 16),
          _buildGuideRow(
            context,
            Icons.menu_rounded,
            'THE BLACKBOOK',
            'Check the side menu for role guides and game rules at any time.',
          ),
          const SizedBox(height: 32),
          CBPrimaryButton(
            label: 'ACKNOWLEDGED',
            backgroundColor: scheme.secondary.withValues(alpha: 0.2),
            foregroundColor: scheme.secondary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow(
      BuildContext context, IconData icon, String title, String description) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.secondary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // _saveUsername logic removed

  ({String title, String detail, _LobbyStatusTone tone}) _buildLobbyStatus({
    required int playerCount,
    required bool awaitingStartConfirmation,
    required String phase,
  }) {
    if (awaitingStartConfirmation) {
      return (
        title: 'READY TO JOIN',
        detail: 'Host started the game. Confirm your join now.',
        tone: _LobbyStatusTone.readyToJoin,
      );
    }

    if (playerCount < _minimumPlayersHintThreshold) {
      return (
        title: 'WAITING FOR MORE PLAYERS',
        detail:
            'Need at least $_minimumPlayersHintThreshold players for a full session.',
        tone: _LobbyStatusTone.waitingPlayers,
      );
    }

    if (phase == 'setup') {
      return (
        title: 'WAITING FOR HOST TO ASSIGN YOU A ROLE',
        detail: 'Role cards are being assigned. Stay ready.',
        tone: _LobbyStatusTone.setup,
      );
    }

    return (
      title: 'WAITING FOR HOST TO START',
      detail: 'Review the Game Bible in the side drawer while you wait.',
      tone: _LobbyStatusTone.waitingHost,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final gameState = ref.watch(activeBridgeProvider).state;
    final authState = ref.watch(authProvider);
    final onboarding = ref.watch(playerOnboardingProvider);

    final preferredName = gameState.myPlayerSnapshot?.name.trim();
    final profileName = authState.user?.displayName?.trim();
    final displayName = (preferredName != null && preferredName.isNotEmpty)
        ? preferredName.toUpperCase()
        : (profileName != null && profileName.isNotEmpty
            ? profileName.toUpperCase()
            : 'UNKNOWN PATRON');

    final status = _buildLobbyStatus(
      playerCount: gameState.players.length,
      awaitingStartConfirmation: onboarding.awaitingStartConfirmation,
      phase: gameState.phase,
    );

    final (statusIcon, statusColor) = switch (status.tone) {
      _LobbyStatusTone.readyToJoin => (Icons.bolt_rounded, scheme.tertiary),
      _LobbyStatusTone.waitingPlayers =>
        (Icons.groups_3_rounded, scheme.secondary),
      _LobbyStatusTone.setup => (Icons.badge_rounded, scheme.primary),
      _LobbyStatusTone.waitingHost =>
        (Icons.hourglass_top_rounded, scheme.onSurfaceVariant),
    };

    final otherPlayers = gameState.players
        .where((p) => p.id != gameState.myPlayerId)
        .toList();

    return CBPrismScaffold(
      title: 'THE LOUNGE',
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              children: [
                // ── STATUS CARD ──
                CBGlassTile(
                  isPrismatic: status.tone == _LobbyStatusTone.readyToJoin,
                  borderColor: statusColor.withValues(alpha: 0.5),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PROTOCOL: ${status.title}',
                              style: textTheme.labelLarge?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          if (gameState.players.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${gameState.players.length} IN',
                                style: textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontFamily: 'RobotoMono',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        status.detail,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                      if (gameState.hostName != null &&
                          gameState.hostName!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.mic_rounded,
                                color: scheme.onSurfaceVariant, size: 12),
                            const SizedBox(width: 6),
                            Text(
                              'HOST: ${gameState.hostName!.toUpperCase()}',
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 9,
                                letterSpacing: 1.5,
                                fontFamily: 'RobotoMono',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── WELCOME / IDENTITY ──
                if (!onboarding.awaitingStartConfirmation) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CURRENT IDENTITY',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      InkWell(
                        onTap: () => Scaffold.of(context).openDrawer(),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            'EDIT PROFILE',
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.secondary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CBGlassTile(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(Icons.person_rounded,
                              color: scheme.primary, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  fontFamily: 'RobotoMono',
                                  color: scheme.onSurface,
                                ),
                              ),
                              Text(
                                'SESSION ACCESS GRANTED',
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 9,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── WHO'S IN THE LOUNGE ──
                if (otherPlayers.isNotEmpty &&
                    !onboarding.awaitingStartConfirmation) ...[
                  Text(
                    'WHO\'S IN THE LOUNGE',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.secondary,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CBGlassTile(
                    borderColor: scheme.secondary.withValues(alpha: 0.25),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: otherPlayers.map((player) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: scheme.secondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: scheme.secondary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: scheme.tertiary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                player.name.toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.8),
                                  letterSpacing: 1.0,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── LIVE FEED ──
                ..._buildBulletinList(
                    gameState, gameState.myPlayerSnapshot, scheme),
              ],
            ),
          ),

          // ── CHAT INPUT ──
          if (!onboarding.awaitingStartConfirmation)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ChatInputBar(
                controller: _chatController,
                onSend: _sendMessage,
                roleColor: scheme.primary, // Use primary color in lobby
              ),
            ),

          // ── ACTION BUTTON (FLOATING) ──
          if (onboarding.awaitingStartConfirmation)
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: CBPrimaryButton(
                label: 'CONFIRM & JOIN',
                icon: Icons.fingerprint_rounded,
                onPressed: () {
                  HapticService.heavy();
                  ref.read(confirmGameStartProvider.notifier).trigger();
                },
              ),
            ),
        ],
      ),
    );
  }
}

enum _LobbyStatusTone {
  waitingPlayers,
  waitingHost,
  setup,
  readyToJoin,
}

List<Widget> _buildBulletinList(
    PlayerGameState gameState, PlayerSnapshot? myPlayer, ColorScheme scheme) {
  final entries = gameState.bulletinBoard;
  if (entries.isEmpty) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.speaker_notes_off_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.1), size: 32),
              const SizedBox(height: 12),
              Text(
                'ENCRYPTED CHANNEL OPEN',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  color: scheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      )
    ];
  }

  final isClubManager = myPlayer?.roleId == RoleIds.clubManager;

  final widgets = <Widget>[];
  widgets.add(const Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: CBFeedSeparator(label: 'LOUNGE FEED'),
  ));

  for (int i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final prevEntry = i > 0 ? entries[i - 1] : null;
    final nextEntry = i < entries.length - 1 ? entries[i + 1] : null;

    // Render 'game_started' entries as a feed separator divider.
    if (entry.type == 'game_started') {
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: CBFeedSeparator(label: 'GAME STARTED', color: scheme.tertiary),
      ));
      continue;
    }

    final role = roleCatalogMap[entry.roleId] ?? roleCatalog.first;
    final color = entry.roleId != null
        ? CBColors.fromHex(role.colorHex)
        : (entry.type == 'system' ? scheme.secondary : scheme.primary);

    String senderName = role.id == 'unassigned' ? entry.title : role.name;

    if (isClubManager &&
        entry.roleId != null &&
        entry.roleId != myPlayer?.roleId) {
      try {
        final senderPlayer =
            gameState.players.firstWhere((p) => p.roleId == entry.roleId);
        senderName = '${role.name} (${senderPlayer.name})';
      } catch (_) {
        // Player not found
      }
    }

    // 'game_started' entries are rendered as separators above (continue);
    // exclude them from grouping so messages on either side are not merged.
    final isPrevSameSender = prevEntry != null &&
        prevEntry.title == entry.title &&
        prevEntry.type != 'game_started';
    final isNextSameSender = nextEntry != null &&
        nextEntry.title == entry.title &&
        nextEntry.type != 'game_started';

    CBMessageGroupPosition groupPos = CBMessageGroupPosition.single;
    if (isPrevSameSender && isNextSameSender) {
      groupPos = CBMessageGroupPosition.middle;
    } else if (isPrevSameSender && !isNextSameSender) {
      groupPos = CBMessageGroupPosition.bottom;
    } else if (!isPrevSameSender && isNextSameSender) {
      groupPos = CBMessageGroupPosition.top;
    }

    widgets.add(CBMessageBubble(
      sender: senderName,
      message: entry.content,
      style: entry.type == 'system'
          ? CBMessageStyle.system
          : CBMessageStyle.narrative,
      color: color,
      avatarAsset: entry.roleId != null ? role.assetPath : null,
      groupPosition: groupPos,
    ));
  }
  return widgets;
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Color roleColor;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: CBGlassTile(
          borderColor: roleColor.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: theme.textTheme.bodyMedium,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Send message...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send_rounded, color: roleColor),
                onPressed: onSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

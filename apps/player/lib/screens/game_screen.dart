import 'package:cb_models/cb_models.dart' hide PlayerSnapshot;
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../active_bridge.dart';
import '../player_bridge.dart';
import '../player_bridge_actions.dart';
import '../widgets/biometric_identity_header.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/game_action_tile.dart';
import '../widgets/ghost_lounge_content.dart';
import '../widgets/notifications_prompt_banner.dart';
import '../widgets/role_strategy_sheet.dart';
import 'role_reveal_screen.dart';
import '../widgets/role_detail_dialog.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _chatController = TextEditingController();
  String? _lastStepId;
  int? _lastSilencedDay;
  Map<String, RoleStrategy>? _strategyCatalog;
  // Tracks which roleId the reveal dialog was shown for, preventing the dialog
  // from re-queuing on every rebuild while awaiting server-side confirmation.
  String? _shownRevealForRoleId;

  @override
  void initState() {
    super.initState();
    _loadStrategyCatalog();
  }

  Future<void> _loadStrategyCatalog() async {
    try {
      final catalog = await StrategyData.loadStrategyCatalog();
      if (mounted) setState(() => _strategyCatalog = catalog);
    } catch (_) {
      // Strategy data is non-critical; degrade gracefully
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final player = ref.read(activeBridgeProvider).state.myPlayerSnapshot;
    if (player == null) return;

    ref.read(activeBridgeProvider).actions.sendBulletin(
          title: player.roleName, // Character Name for anonymity
          floatContent: text,
          roleId: player.roleId,
        );

    _chatController.clear();
    FocusScope.of(context).unfocus();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showRoleReveal(PlayerSnapshot player, PlayerBridgeActions bridge) {
    // Mark immediately so no subsequent rebuild re-queues the dialog before
    // the server round-trip completes and roleConfirmedPlayerIds is updated.
    _shownRevealForRoleId = player.roleId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => RoleRevealScreen(
          player: player,
          onConfirm: () => bridge.confirmRole(playerId: player.id),
        ),
      );
    });
  }

  void _showRoofiedDialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showThemedDialog(
      context: context,
      barrierDismissible: false,
      accentColor: scheme.error,
      child: CBPanel(
        borderColor: scheme.error.withValues(alpha: 0.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: scheme.error, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('YOU\'VE BEEN ROOFIED',
                      style: textTheme.titleMedium?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your drink was spiked. You are paralysed — your night action has been cancelled.\n\nKeep your eyes closed and say nothing.',
              style: textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: CBGhostButton(
                label: 'ACKNOWLEDGED',
                color: scheme.error,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeBridge = ref.watch(activeBridgeProvider);
    final gameState = activeBridge.state;
    final bridge = activeBridge.actions;
    final player = gameState.myPlayerSnapshot;
    final playerId = gameState.myPlayerId;

    if (player == null || playerId == null) {
      return CBPrismScaffold(
        title: 'CONNECTING...',
        drawer: const CustomDrawer(),
        body: Center(child: CBBreathingLoader()),
      );
    }

    // Scroll handling
    final newStep = gameState.currentStep;
    final canAct =
        newStep != null && (newStep.roleId == player.roleId || newStep.isVote);

    if (newStep != null && newStep.id != _lastStepId && canAct) {
      _lastStepId = newStep.id;
      HapticService.eyesOpen();
      _scrollToBottom();
    } else if (newStep == null) {
      _lastStepId = null;
    }

    // Check for Roofi/Silencing effect
    if (player.silencedDay == gameState.dayCount &&
        _lastSilencedDay != gameState.dayCount) {
      _lastSilencedDay = gameState.dayCount;
      HapticService.roofied();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showRoofiedDialog(context);
      });
    }

    final isRoleConfirmed = gameState.roleConfirmedPlayerIds.contains(playerId);
    // Reset the local guard if the server has now confirmed (e.g. new game same
    // role) or if the player has been assigned a different role than before.
    if (isRoleConfirmed) {
      _shownRevealForRoleId = null;
    }
    if (!isRoleConfirmed &&
        player.roleId.isNotEmpty &&
        player.roleId != 'unassigned' &&
        _shownRevealForRoleId != player.roleId) {
      _showRoleReveal(player, bridge);
    }

    if (!player.isAlive && gameState.phase != 'endGame') {
      return GhostLoungeContent(
        gameState: gameState,
        playerId: playerId,
        bridge: bridge,
      );
    }

    if (gameState.phase == 'endGame') {
      return _PlayerEndGameView(
        gameState: gameState,
        player: player,
        bridge: bridge,
      );
    }

    final roleColor =
        Color(int.parse(player.roleColorHex.replaceAll('#', '0xff')));

    return Theme(
      data: CBTheme.buildTheme(CBTheme.buildColorScheme(roleColor)),
      child: CBPrismScaffold(
        title: 'GAME TERMINAL',
        drawer: const CustomDrawer(),
        body: Column(
          children: [
            const NotificationsPromptBanner(),
            BiometricIdentityHeader(
              player: player,
              gameState: gameState,
              roleColor: roleColor,
              isMyTurn: canAct,
              strategy: _strategyCatalog?[player.roleId],
              onBlackbookTap: () => RoleStrategySheet.show(
                context: context,
                player: player,
                gameState: gameState,
                roleColor: roleColor,
                strategy: _strategyCatalog?[player.roleId],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 16, bottom: 200),
                children: [
                  // Phase/Day Header
                  CBFeedSeparator(
                    label:
                        "${gameState.phase.toUpperCase()} • DAY ${gameState.dayCount}",
                    color: roleColor,
                    isCinematic: true,
                  ),

                  // Bulletin Board
                  ..._buildBulletinList(gameState, player, scheme),

                  // Private Messages
                  if (gameState.privateMessages.containsKey(playerId))
                    ..._buildPrivateMessages(
                        gameState.privateMessages[playerId]!, scheme),

                  // Current Step Narration
                  if (newStep != null && newStep.readAloudText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: CBMessageBubble(
                        sender: 'DIRECTIVE',
                        message: newStep.readAloudText,
                        avatarAsset: 'assets/roles/${player.roleId}.png',
                        color: roleColor,
                        style: CBMessageStyle.standard,
                        isSender: false,
                        groupPosition: CBMessageGroupPosition.single,
                      ),
                    ),
                ],
              ),
            ),
            _ChatInputBar(
              controller: _chatController,
              onSend: _sendMessage,
              roleColor: roleColor,
            ),
          ],
        ),
        bottomNavigationBar: canAct
            ? _buildGameActionBar(
                context,
                newStep,
                roleColor,
                player,
                gameState,
                playerId,
                bridge,
              )
            : null,
      ),
    );
  }

  List<Widget> _buildBulletinList(
      PlayerGameState gameState, PlayerSnapshot? myPlayer, ColorScheme scheme) {
    final entries = gameState.bulletinBoard;
    if (entries.isEmpty) return [];

    final isClubManager = myPlayer?.roleId == RoleIds.clubManager;

    final widgets = <Widget>[];
    if (entries.isNotEmpty) {
      widgets.add(const CBFeedSeparator(label: 'PUBLIC FEED'));
    }

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final prevEntry = i > 0 ? entries[i - 1] : null;
      final nextEntry = i < entries.length - 1 ? entries[i + 1] : null;

      final role = roleCatalogMap[entry.roleId] ?? roleCatalog.first;
      final color = entry.roleId != null
          ? CBColors.fromHex(role.colorHex)
          : scheme.primary;

      // Default sender name is the character name (or title for host/system)
      String senderName = role.id == 'unassigned' ? entry.title : role.name;

      // If the viewer is the Club Manager, reveal the real player name
      if (isClubManager &&
          entry.roleId != null &&
          entry.roleId != myPlayer?.roleId) {
        try {
          final senderPlayer =
              gameState.players.firstWhere((p) => p.roleId == entry.roleId);
          senderName = '${role.name} (${senderPlayer.name})';
        } catch (_) {
          // Player not found, fallback to role name
        }
      }

      final isPrevSameSender = prevEntry != null &&
          prevEntry.title == entry.title; // Simplified check
      final isNextSameSender =
          nextEntry != null && nextEntry.title == entry.title;

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
        onAvatarTap: entry.roleId != null
            ? () => showRoleDetailDialog(context, role)
            : null,
      ));
    }
    return widgets;
  }

  List<Widget> _buildPrivateMessages(
      List<String> messages, ColorScheme scheme) {
    if (messages.isEmpty) return [];

    final widgets = <Widget>[];
    widgets.add(const CBFeedSeparator(label: 'ENCRYPTED INTEL'));

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      // Private messages usually come from System or specific roles but stored as strings.
      // We'll treat them as a continuous stream from "HQ/Security"

      CBMessageGroupPosition groupPos = CBMessageGroupPosition.single;
      if (messages.length > 1) {
        if (i == 0) {
          groupPos = CBMessageGroupPosition.top;
        } else if (i == messages.length - 1) {
          groupPos = CBMessageGroupPosition.bottom;
        } else {
          groupPos = CBMessageGroupPosition.middle;
        }
      }

      widgets.add(CBMessageBubble(
        sender: 'SECURITY',
        message: msg,
        style: CBMessageStyle.standard,
        color: scheme.tertiary,
        isSender: false,
        avatarAsset: 'assets/roles/security.png',
        groupPosition: groupPos,
      ));
    }
    return widgets;
  }

  Widget _buildGameActionBar(
    BuildContext context,
    StepSnapshot step,
    Color roleColor,
    PlayerSnapshot player,
    PlayerGameState gameState,
    String playerId,
    PlayerBridgeActions bridge,
  ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: CBPanel(
          padding: const EdgeInsets.all(12),
          borderColor: roleColor.withValues(alpha: 0.4),
          child: GameActionTile(
            step: step,
            roleColor: roleColor,
            player: player,
            gameState: gameState,
            playerId: playerId,
            bridge: bridge,
          ),
        ),
      ),
    );
  }
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
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface.withValues(alpha: 0.9),
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

// ─── PLAYER END GAME VIEW ──────────────────────────────────

class _PlayerEndGameView extends StatelessWidget {
  final PlayerGameState gameState;
  final PlayerSnapshot player;
  final PlayerBridgeActions bridge;

  const _PlayerEndGameView({
    required this.gameState,
    required this.player,
    required this.bridge,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final winnerRaw = gameState.winner;
    final winnerName = switch (winnerRaw) {
      'clubStaff' => 'CLUB STAFF',
      'partyAnimals' => 'PARTY ANIMALS',
      'neutral' => 'NEUTRAL',
      _ => 'UNKNOWN',
    };
    final winColor = switch (winnerRaw) {
      'clubStaff' => scheme.primary,
      'partyAnimals' => scheme.secondary,
      'neutral' => CBColors.alertOrange,
      _ => scheme.onSurface.withValues(alpha: 0.55),
    };

    final roleColor =
        Color(int.parse(player.roleColorHex.replaceAll('#', '0xff')));

    return CBPrismScaffold(
      title: 'GAME OVER',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          CBStatusOverlay(
            icon: Icons.emoji_events_rounded,
            label: 'GAME OVER',
            color: winColor,
            detail: '$winnerName VICTORY',
          ),
          const SizedBox(height: 24),
          CBGlassTile(
            isPrismatic: true,
            borderColor: roleColor.withValues(alpha: 0.5),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CBRoleAvatar(
                  assetPath: 'assets/roles/${player.roleId}.png',
                  color: roleColor,
                  size: 56,
                  breathing: true,
                ),
                const SizedBox(height: 12),
                Text(
                  'YOU WERE',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  player.roleName.toUpperCase(),
                  style: textTheme.headlineSmall?.copyWith(
                    color: roleColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: CBColors.textGlow(roleColor, intensity: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                CBMiniTag(
                  text: player.isAlive ? 'SURVIVED' : 'ELIMINATED',
                  color: player.isAlive ? scheme.tertiary : scheme.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (gameState.endGameReport.isNotEmpty)
            CBPanel(
              borderColor: winColor.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CBSectionHeader(
                    title: 'RESOLUTION',
                    icon: Icons.summarize_rounded,
                    color: winColor,
                  ),
                  const SizedBox(height: 12),
                  for (final line in gameState.endGameReport)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        line,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (gameState.rematchOffered)
            _buildRematchOffered(context, scheme, textTheme)
          else
            _buildWaitingForHost(scheme, textTheme),
          const SizedBox(height: 16),
          CBGhostButton(
            label: 'LEAVE SESSION',
            icon: Icons.exit_to_app_rounded,
            color: scheme.error,
            onPressed: () {
              HapticService.light();
              bridge.leave();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRematchOffered(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        CBPrimaryButton(
          label: 'REJOIN WITH NEW ROLE',
          icon: Icons.replay_rounded,
          onPressed: () {
            HapticService.medium();
            // Normally the PlayerHomeShell auto-navigates to lobby when
            // the host resets the phase. This is a safety-net: disconnect
            // so the shell re-routes to connect → auto-rejoin into lobby.
            bridge.leave();
          },
        ),
        const SizedBox(height: 12),
        Text(
          'THE HOST HAS OFFERED A REMATCH.',
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.tertiary.withValues(alpha: 0.8),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingForHost(ColorScheme scheme, TextTheme textTheme) {
    return CBGlassTile(
      borderColor: scheme.onSurfaceVariant.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded,
              size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'WAITING FOR HOST TO START A NEW GAME...',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

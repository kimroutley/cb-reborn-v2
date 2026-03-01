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
import '../widgets/player_profile_panel_content.dart';
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
  String? _shownRevealForRoleId;
  PlayerSnapshot? _selectedPlayerForPanel;
  bool _isPlayerPanelOpen = false;

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
      // Strategy data is non-critical
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
          title: player.roleName,
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
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showRoleReveal(PlayerSnapshot player, PlayerBridgeActions bridge) {
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
                        letterSpacing: 1.5)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Your drink was spiked. You are paralysed — your night action has been cancelled.\n\nKeep your eyes closed and say nothing.',
            style: textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7), height: 1.5),
          ),
          const SizedBox(height: 32),
          CBPrimaryButton(
            label: 'ACKNOWLEDGED',
            backgroundColor: scheme.error.withValues(alpha: 0.2),
            foregroundColor: scheme.error,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBridge = ref.watch(activeBridgeProvider);
    final gameState = activeBridge.state;
    final bridge = activeBridge.actions;
    final player = gameState.myPlayerSnapshot;
    final playerId = gameState.myPlayerId;

    if (player == null || playerId == null) {
      return const CBPrismScaffold(
        title: 'SYNCING...',
        body: Center(child: CBBreathingSpinner()),
      );
    }

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
        title: 'TERMINAL',
        drawer: const CustomDrawer(),
        body: Stack(
          children: [
            Column(
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
                    physics: const BouncingScrollPhysics(),
                    children: [
                      CBFeedSeparator(
                        label: "${gameState.phase.toUpperCase()} • DAY ${gameState.dayCount}",
                        color: roleColor,
                        isCinematic: true,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildInThisGameRow(context, gameState.players, roleColor),
                      ),
                      const SizedBox(height: 24),
                      const CBFeedSeparator(label: 'THE LOUNGE'),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Text(
                          'Prompts, directives, and all communications in this channel.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      ..._buildBulletinList(gameState, player, roleColor),
                      if (gameState.privateMessages.containsKey(playerId))
                        ..._buildPrivateMessages(
                            gameState.privateMessages[playerId]!, roleColor),
                      if (newStep != null && newStep.readAloudText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          child: CBMessageBubble(
                            sender: 'DIRECTIVE',
                            message: newStep.readAloudText,
                            avatarAsset: 'assets/roles/${player.roleId}.png',
                            color: roleColor,
                            style: CBMessageStyle.standard,
                            isSender: false,
                            groupPosition: CBMessageGroupPosition.single,
                            isPrismatic: true,
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
            CBSlidingPanel(
              isOpen: _isPlayerPanelOpen,
              onClose: () => setState(() {
                _isPlayerPanelOpen = false;
                _selectedPlayerForPanel = null;
              }),
              title: _selectedPlayerForPanel?.name.toUpperCase() ?? 'PROFILE',
              width: 380,
              accentColor: _selectedPlayerForPanel != null &&
                      _selectedPlayerForPanel!.roleId.isNotEmpty &&
                      _selectedPlayerForPanel!.roleId != 'unassigned'
                  ? (roleCatalogMap[_selectedPlayerForPanel!.roleId] != null
                      ? CBColors.fromHex(
                          roleCatalogMap[_selectedPlayerForPanel!.roleId]!.colorHex)
                      : null)
                  : null,
              child: _selectedPlayerForPanel != null
                  ? PlayerProfilePanelContent(player: _selectedPlayerForPanel!)
                  : const SizedBox(),
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

  Widget _buildInThisGameRow(
    BuildContext context,
    List<PlayerSnapshot> players,
    Color roleColor,
  ) {
    if (players.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'IN THIS GAME',
          style: textTheme.labelSmall?.copyWith(
            color: roleColor,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: players.map((p) {
              final pRoleColor = p.roleId.isNotEmpty && p.roleId != 'unassigned'
                  ? (roleCatalogMap[p.roleId] != null
                      ? CBColors.fromHex(
                          roleCatalogMap[p.roleId]!.colorHex)
                      : roleColor)
                  : roleColor;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CBFilterChip(
                  label: p.name,
                  selected: false,
                  onSelected: () {
                    HapticService.selection();
                    setState(() {
                      _selectedPlayerForPanel = p;
                      _isPlayerPanelOpen = true;
                    });
                  },
                  color: pRoleColor,
                  dense: true,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBulletinList(
      PlayerGameState gameState, PlayerSnapshot? myPlayer, Color roleColor) {
    var entries =
        PlayerGameState.sanitizePublicBulletinEntries(gameState.bulletinBoard);
    entries = entries
        .where((e) =>
            e.targetRoleId == null || e.targetRoleId == myPlayer?.roleId)
        .toList();
    if (entries.isEmpty) return [];

    final widgets = <Widget>[];

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final prevEntry = i > 0 ? entries[i - 1] : null;
      final nextEntry = i < entries.length - 1 ? entries[i + 1] : null;

      final role = roleCatalogMap[entry.roleId] ?? roleCatalog.first;
      final color = entry.roleId != null
          ? CBColors.fromHex(role.colorHex)
          : roleColor;

      String senderName = entry.title;
      if (entry.roleId != null) {
        try {
          final senderPlayer =
              gameState.players.firstWhere((p) => p.roleId == entry.roleId);
          senderName = senderPlayer.name;
        } catch (_) {
          senderName = role.id == 'unassigned' ? entry.title : role.name;
        }
      }

      final isPrevSameSender = prevEntry != null &&
          prevEntry.roleId == entry.roleId;
      final isNextSameSender =
          nextEntry != null && nextEntry.roleId == entry.roleId;

      CBMessageGroupPosition groupPos = CBMessageGroupPosition.single;
      if (isPrevSameSender && isNextSameSender) {
        groupPos = CBMessageGroupPosition.middle;
      } else if (isPrevSameSender && !isNextSameSender) {
        groupPos = CBMessageGroupPosition.bottom;
      } else if (!isPrevSameSender && isNextSameSender) {
        groupPos = CBMessageGroupPosition.top;
      }

      final isHostMessage = entry.roleId == null;
      final isMe = myPlayer != null && entry.roleId == myPlayer.roleId;

      widgets.add(CBMessageBubble(
        sender: senderName,
        message: entry.content,
        style: entry.type == 'system'
            ? CBMessageStyle.system
            : isHostMessage
                ? CBMessageStyle.narrative
                : CBMessageStyle.standard,
        color: color,
        isSender: isMe,
        avatarAsset: entry.roleId != null ? role.assetPath : null,
        groupPosition: groupPos,
        isCompact: true,
        isPrismatic: isHostMessage,
        onAvatarTap: entry.roleId != null
            ? () => showRoleDetailDialog(context, role)
            : null,
      ));
    }
    return widgets;
  }

  List<Widget> _buildPrivateMessages(
      List<String> messages, Color roleColor) {
    if (messages.isEmpty) return [];

    final widgets = <Widget>[];
    widgets.add(const SizedBox(height: 24));
    widgets.add(const CBFeedSeparator(label: 'ENCRYPTED INTEL'));
    widgets.add(const SizedBox(height: 8));

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
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
        color: roleColor,
        isSender: false,
        avatarAsset: 'assets/roles/security.png',
        groupPosition: groupPos,
        isCompact: true,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Theme.of(context).colorScheme.scrim.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: CBGlassTile(
          isPrismatic: true,
          padding: const EdgeInsets.all(16),
          borderColor: roleColor.withValues(alpha: 0.5),
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

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            scheme.scrim.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: CBGlassTile(
          borderColor: roleColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Send message',
                icon: Icon(Icons.send_rounded, color: roleColor, size: 20),
                onPressed: () {
                  HapticService.selection();
                  onSend();
                },
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        physics: const BouncingScrollPhysics(),
        children: [
          CBStatusOverlay(
            icon: Icons.emoji_events_rounded,
            label: 'GAME OVER',
            color: winColor,
            detail: '$winnerName VICTORY',
          ),
          const SizedBox(height: 32),
          CBGlassTile(
            isPrismatic: true,
            borderColor: roleColor.withValues(alpha: 0.5),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CBRoleAvatar(
                  assetPath: 'assets/roles/${player.roleId}.png',
                  color: roleColor,
                  size: 64,
                  breathing: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'YOU WERE',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  player.roleName.toUpperCase(),
                  style: textTheme.headlineSmall?.copyWith(
                    color: roleColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: CBColors.textGlow(roleColor),
                  ),
                ),
                const SizedBox(height: 12),
                CBMiniTag(
                  text: player.isAlive ? 'SURVIVED' : 'ELIMINATED',
                  color: player.isAlive ? scheme.tertiary : scheme.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
                  const SizedBox(height: 16),
                  for (final line in gameState.endGameReport)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        line,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          if (gameState.rematchOffered)
            _buildRematchOffered(context, scheme, textTheme)
          else
            _buildWaitingForHost(scheme, textTheme),
          const SizedBox(height: 24),
          CBGhostButton(
            label: 'LEAVE SESSION',
            icon: Icons.exit_to_app_rounded,
            color: scheme.error,
            onPressed: () {
              HapticService.light();
              bridge.leave();
            },
          ),
          const SizedBox(height: 48),
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
            bridge.leave();
          },
        ),
        const SizedBox(height: 12),
        Text(
          'THE HOST HAS OFFERED A REMATCH.',
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.tertiary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingForHost(ColorScheme scheme, TextTheme textTheme) {
    return CBGlassTile(
      borderColor: scheme.onSurfaceVariant.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CBBreathingSpinner(size: 18, strokeWidth: 2),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'WAITING FOR HOST TO START A NEW GAME...',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

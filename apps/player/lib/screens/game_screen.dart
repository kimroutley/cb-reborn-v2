import 'package:cb_models/cb_models.dart' hide PlayerSnapshot;
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../active_bridge.dart';
import '../player_bridge.dart';
import '../player_bridge_actions.dart';
import '../widgets/biometric_identity_header.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/game_action_tile.dart';
import '../widgets/ghost_lounge_content.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _lastStepId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      HapticFeedback.mediumImpact();
      _scrollToBottom();
    } else if (newStep == null) {
      _lastStepId = null;
    }

    if (!player.isAlive) {
      return GhostLoungeContent(
        gameState: gameState,
        playerId: playerId,
        bridge: bridge,
      );
    }

    final roleColor =
        Color(int.parse(player.roleColorHex.replaceAll('#', '0xff')));
    final isRoleConfirmed = gameState.roleConfirmedPlayerIds.contains(playerId);

    return Theme(
      data: CBTheme.buildTheme(CBTheme.buildColorScheme(roleColor)),
      child: CBPrismScaffold(
        title: 'GAME TERMINAL',
        drawer: const CustomDrawer(),
        body: Column(
          children: [
            BiometricIdentityHeader(
              player: player,
              roleColor: roleColor,
              isMyTurn: canAct,
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
                    color: scheme.onSurfaceVariant,
                  ),

                  // Bulletin Board
                  ..._buildBulletinList(gameState.bulletinBoard, scheme),

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
          ],
        ),
        bottomNavigationBar: (gameState.phase == 'setup' && !isRoleConfirmed)
            ? _buildSetupConfirmBar(context, bridge, playerId, roleColor)
            : canAct
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
      List<BulletinEntry> entries, ColorScheme scheme) {
    if (entries.isEmpty) return [];

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
      final senderName = role.id == 'unassigned' ? entry.title : role.name;

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

  Widget _buildSetupConfirmBar(BuildContext context, PlayerBridgeActions bridge,
      String playerId, Color color) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: CBPanel(
          borderColor: color.withValues(alpha: 0.4),
          child: CBPrimaryButton(
            label: 'CONFIRM IDENTITY',
            icon: Icons.fingerprint_rounded,
            backgroundColor: color,
            onPressed: () {
              bridge.confirmRole(playerId: playerId);
              HapticFeedback.selectionClick();
            },
          ),
        ),
      ),
    );
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

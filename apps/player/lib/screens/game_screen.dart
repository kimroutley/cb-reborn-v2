import 'package:cb_models/cb_models.dart' hide PlayerSnapshot, BulletinEntry;
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_bridge_actions.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/biometric_identity_header.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/game_action_tile.dart';
import '../widgets/ghost_lounge_content.dart';
import '../widgets/stim_effect_overlay.dart';

class GameScreen extends ConsumerStatefulWidget {
  final PlayerBridgeActions bridge;
  final PlayerGameState gameState;
  final PlayerSnapshot player;
  final String playerId;

  const GameScreen({
    super.key,
    required this.bridge,
    required this.gameState,
    required this.player,
    required this.playerId,
  });

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

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newStep = widget.gameState.currentStep;
    final canAct = newStep != null &&
        (newStep.roleId == widget.player.roleId || newStep.isVote);

    if (newStep != null && newStep.id != _lastStepId && canAct) {
      _lastStepId = newStep.id;
      HapticService.alertDispatch();
      _scrollToBottom();
    } else if (newStep == null) {
      _lastStepId = null;
    }
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
    if (!widget.player.isAlive) {
      return GhostLoungeContent(
        gameState: widget.gameState,
        player: widget.player,
        playerId: widget.playerId,
        bridge: widget.bridge,
      );
    }

    final step = widget.gameState.currentStep;
    final roleColor = CBColors.fromHex(widget.player.roleColorHex);
    final canAct =
        step != null && (step.roleId == widget.player.roleId || step.isVote);

    // Apply dynamic theme for the role
    return Theme(
      data: CBTheme.buildTheme(CBTheme.buildColorScheme(roleColor)),
      child: StimEffectOverlay(
        bulletinBoard: widget.gameState.bulletinBoard,
        child: CBPrismScaffold(
          title: 'GAME FEED',
          drawer: const CustomDrawer(),
          body: Column(
            children: [
              // ── BIOMETRIC IDENTITY HEADER ──
              BiometricIdentityHeader(
                player: widget.player,
                roleColor: roleColor,
                isMyTurn: canAct,
              ),

              // ── CHAT FEED ──
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    // 1. Current Phase Header
                    CBMessageBubble(
                      variant: CBMessageVariant.system,
                      content:
                          "${widget.gameState.phase.toUpperCase()} - DAY ${widget.gameState.dayCount}",
                      accentColor: roleColor,
                    ),

                    // 2. Bulletin History (Public events)
                    ...widget.gameState.bulletinBoard.map((entry) {
                      final role =
                          roleCatalogMap[entry.roleId] ?? roleCatalog.first;
                      final color = entry.roleId != null
                          ? CBColors.fromHex(role.colorHex)
                          : theme.colorScheme.primary; // Use theme color

                      return CBMessageBubble(
                        variant: entry.type == 'system'
                            ? CBMessageVariant.system
                            : CBMessageVariant.narrative,
                        content: entry.content,
                        senderName:
                            role.id == 'unassigned' ? entry.title : role.name,
                        accentColor: color,
                        avatar: entry.roleId != null
                            ? CBRoleAvatar(
                                assetPath: role.assetPath,
                                color: color,
                                size: 32)
                            : null,
                      );
                    }),

                    // 3. Private Intel (The "Secret" Chat)
                    if (widget.gameState.privateMessages
                        .containsKey(widget.playerId))
                      ...widget.gameState.privateMessages[widget.playerId]!
                          .map((msg) => CBMessageBubble(
                                variant: CBMessageVariant.directive,
                                content: msg,
                                accentColor: theme.colorScheme.tertiary,
                              )),

                    // 4. Current Directive
                    if (step != null) ...[
                      CBMessageBubble(
                        variant: CBMessageVariant.narrative,
                        senderName: "DIRECTIVE",
                        content: step.readAloudText,
                        accentColor: roleColor,
                        avatar: CBRoleAvatar(
                            assetPath:
                                'assets/roles/${widget.player.roleId}.png',
                            color: roleColor,
                            size: 34,
                            pulsing: true),
                      ),

                      // 5. Action Tile (Interactive)
                      if (canAct)
                        GameActionTile(
                          step: step,
                          roleColor: roleColor,
                          player: widget.player,
                          gameState: widget.gameState,
                          playerId: widget.playerId,
                          bridge: widget.bridge,
                        ),
                    ],

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

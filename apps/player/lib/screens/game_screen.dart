import 'package:cb_models/cb_models.dart' hide PlayerSnapshot;
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../active_bridge.dart';
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
    final activeBridge = ref.watch(activeBridgeProvider);
    final gameState = activeBridge.state;
    final bridge = activeBridge.actions;
    final player = gameState.myPlayerSnapshot;
    final playerId = gameState.myPlayerId;

    if (player == null || playerId == null) {
      return const Scaffold(
        body: Center(child: CBBreathingLoader()),
      );
    }

    // Scroll handling
    final newStep = gameState.currentStep;
    final canAct = newStep != null && (newStep.roleId == player.roleId || newStep.isVote);

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
        player: player,
        playerId: playerId,
        bridge: bridge,
      );
    }

    final roleColor = Color(int.parse(player.roleColorHex.replaceAll('#', '0xff')));
    final isRoleConfirmed = gameState.roleConfirmedPlayerIds.contains(playerId);

    return Theme(
      data: CBTheme.buildTheme(CBTheme.buildColorScheme(roleColor)),
      child: Scaffold(
        drawer: const CustomDrawer(),
        body: CBNeonBackground(
          child: Column(
            children: [
              BiometricIdentityHeader(
                player: player,
                roleColor: roleColor,
                isMyTurn: canAct,
              ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    CBMessageBubble(
                      sender: 'SYSTEM',
                      message: "${gameState.phase.toUpperCase()} - DAY ${gameState.dayCount}",
                      isSystemMessage: true,
                    ),
                    if (gameState.phase == 'setup' && !isRoleConfirmed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: CBPrimaryButton(
                          label: 'CONFIRM ROLE',
                          icon: Icons.verified_user_rounded,
                          onPressed: () {
                            bridge.confirmRole(playerId: playerId);
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ),
                    if (gameState.phase == 'setup' && isRoleConfirmed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: CBBadge(
                          text: 'ROLE CONFIRMED',
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ...gameState.bulletinBoard.map((entry) {
                      final role = roleCatalogMap[entry.roleId] ?? roleCatalog.first;
                      final color = entry.roleId != null
                          ? CBColors.fromHex(role.colorHex)
                          : theme.colorScheme.primary;
                      final senderName = role.id == 'unassigned' ? entry.title : role.name;

                      return CBMessageBubble(
                        sender: senderName,
                        message: entry.content,
                        isSystemMessage: entry.type == 'system',
                        color: color,
                        avatarAsset: entry.roleId != null ? role.assetPath : null,
                      );
                    }),
                    if (gameState.privateMessages.containsKey(playerId))
                      ...gameState.privateMessages[playerId]!.map((msg) => CBMessageBubble(
                            sender: 'PRIVATE',
                            message: msg,
                          )),
                    if (newStep != null) ...[
                      CBMessageBubble(
                        sender: 'DIRECTIVE',
                        message: newStep.readAloudText,
                        avatarAsset: 'assets/roles/${player.roleId}.png',
                        color: roleColor,
                      ),
                      if (canAct)
                        GameActionTile(
                          step: newStep,
                          roleColor: roleColor,
                          player: player,
                          gameState: gameState,
                          playerId: playerId,
                          bridge: bridge,
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

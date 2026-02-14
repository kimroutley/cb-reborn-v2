import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

import '../utils/role_color_extension.dart';

class GameFeedList extends StatelessWidget {
  final ScrollController scrollController;
  final GameState gameState;
  final ScriptStep? step;
  final Game controller;
  final String? firstPickId;
  final ValueChanged<String?> onFirstPickChanged;

  const GameFeedList({
    super.key,
    required this.scrollController,
    required this.gameState,
    required this.step,
    required this.controller,
    required this.firstPickId,
    required this.onFirstPickChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        itemCount: gameState.feedEvents.length +
            (step != null ? _liveWidgetCount(step!) : 0),
        itemBuilder: (context, index) {
          // Past feed events
          if (index < gameState.feedEvents.length) {
            final event = gameState.feedEvents[index];
            // Cluster: same roleId as previous non-system event
            final isClustered = index > 0 &&
                event.roleId != null &&
                event.type != FeedEventType.system &&
                gameState.feedEvents[index - 1].roleId == event.roleId &&
                gameState.feedEvents[index - 1].type != FeedEventType.system;
            return _buildFeedBubble(gameState, event, isClustered: isClustered);
          }
          // Live current step widgets (rendered after feed history)
          final liveIndex = index - gameState.feedEvents.length;
          return _buildLiveStepWidget(
              context, gameState, step!, liveIndex, controller);
        },
      ),
    );
  }

  int _liveWidgetCount(ScriptStep step) {
    if (step.actionType == ScriptActionType.phaseTransition) return 1;
    if (step.actionType == ScriptActionType.info) return 1;
    if (step.actionType == ScriptActionType.selectPlayer) {
      return 2; // Title + Grid
    }
    return 0;
  }

  Widget _buildLiveStepWidget(BuildContext context, GameState gameState,
      ScriptStep step, int index, Game controller) {
    final scheme = Theme.of(context).colorScheme;
    switch (step.actionType) {
      case ScriptActionType.phaseTransition:
        return CBPhaseInterrupt(
          title: step.title,
          accentColor: scheme.primary,
          icon: Icons.shield,
          onDismiss: () {},
        );
      case ScriptActionType.info:
        return CBMessageBubble(
          variant: CBMessageVariant.system,
          content: step.title,
          accentColor: scheme.secondary,
        );
      case ScriptActionType.selectPlayer:
        if (index == 0) {
          return CBMessageBubble(
            variant: CBMessageVariant.system,
            content: step.title,
            accentColor: scheme.primary,
          );
        }
        return _buildPlayerSelectionGrid(step, gameState, controller);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlayerSelectionGrid(
      ScriptStep step, GameState gameState, Game controller) {
    final eligiblePlayers = gameState.players.where((p) => p.isAlive).toList();
    final maxSelections =
        step.actionType == ScriptActionType.selectTwoPlayers ? 2 : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: eligiblePlayers.map((p) {
          final isSelected = firstPickId == p.id;
          return CBCompactPlayerChip(
            name: p.name,
            color: RoleColorExtension(p.role).color,
            isSelected: isSelected,
            onTap: () {
              if (maxSelections == 1) {
                controller.handleInteraction(stepId: step.id, targetId: p.id);
              } else {
                if (isSelected) {
                  onFirstPickChanged(null);
                } else {
                  onFirstPickChanged(p.id);
                }
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedBubble(GameState gameState, FeedEvent event,
      {bool isClustered = false}) {
    final player = gameState.players.firstWhere(
      (p) => p.role.id == event.roleId,
      orElse: () => Player(
        id: 'unassigned',
        name: 'Unassigned',
        role: Role(
          id: 'unassigned',
          name: 'Unassigned',
          alliance: Team.unknown,
          type: '',
          description: '',
          nightPriority: 0,
          assetPath: '',
          colorHex: '#888888',
        ),
        alliance: Team.unknown,
      ),
    );

    final role = player.role;

    return CBMessageBubble(
      variant: event.type.toMessageVariant(),
      playerHeader: CBPlayerStatusTile(
        playerName: player.name,
        roleName: role.name,
        assetPath: role.assetPath,
        roleColor: RoleColorExtension(role).color,
        isAlive: player.isAlive,
        statusEffects: player.statusEffects,
      ),
      content: event.content,
      accentColor: RoleColorExtension(role).color,
      isClustered: isClustered,
    );
  }
}

extension on FeedEventType {
  CBMessageVariant toMessageVariant() {
    switch (this) {
      case FeedEventType.narrative:
        return CBMessageVariant.narrative;
      case FeedEventType.directive:
        return CBMessageVariant.system;
      case FeedEventType.action:
        return CBMessageVariant.system;
      case FeedEventType.system:
        return CBMessageVariant.system;
      case FeedEventType.result:
        return CBMessageVariant.result;
      case FeedEventType.timer:
        return CBMessageVariant.system;
    }
  }
}

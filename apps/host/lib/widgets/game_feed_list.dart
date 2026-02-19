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

  const GameFeedList({
    super.key,
    required this.scrollController,
    required this.gameState,
    required this.step,
    required this.controller,
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
    if (step.actionType == ScriptActionType.selectPlayer ||
        step.actionType == ScriptActionType.selectTwoPlayers) {
      return 2; // Title + Grid
    }
    if (step.actionType == ScriptActionType.binaryChoice) {
      return 2; // Title + Binary options
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
          color: scheme.primary,
          icon: Icons.shield,
        );
      case ScriptActionType.info:
        return CBMessageBubble(
          isSystemMessage: true,
          sender: 'System',
          message: step.title,
          color: scheme.secondary,
        );
      case ScriptActionType.selectPlayer:
      case ScriptActionType.selectTwoPlayers:
        if (index == 0) {
          return CBMessageBubble(
            isSystemMessage: true,
            sender: 'System',
            message: step.title,
            color: scheme.primary,
          );
        }
        return _buildPlayerSelectionGrid(step, gameState, controller);
      case ScriptActionType.binaryChoice:
        if (index == 0) {
          return CBMessageBubble(
            isSystemMessage: true,
            sender: 'System',
            message: step.title,
            color: scheme.tertiary,
          );
        }
        return _buildBinaryChoice(step, controller);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBinaryChoice(ScriptStep step, Game controller) {
    // Assuming binary choices are like "Option A | Option B"
    final options = step.instructionText.split('|');
    final left = options.isNotEmpty ? options[0].trim() : 'YES';
    final right = options.length > 1 ? options[1].trim() : 'NO';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: CBPrimaryButton(
              label: left,
              onPressed: () {
                controller.handleInteraction(stepId: step.id, targetId: left);
                controller.advancePhase();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CBPrimaryButton(
              label: right,
              onPressed: () {
                controller.handleInteraction(stepId: step.id, targetId: right);
                controller.advancePhase();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSelectionGrid(
      ScriptStep step, GameState gameState, Game controller) {
    final eligiblePlayers = gameState.players.where((p) => p.isAlive).toList();
    final isMulti = step.actionType == ScriptActionType.selectTwoPlayers;

    final currentPicks = gameState.actionLog[step.id]
            ?.split(',')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: eligiblePlayers.map((p) {
          final isSelected = currentPicks.contains(p.id);
          return CBCompactPlayerChip(
            name: p.name,
            color: RoleColorExtension(p.role).color,
            isSelected: isSelected,
            onTap: () {
              if (!isMulti) {
                controller.handleInteraction(
                  stepId: step.id,
                  targetId: isSelected ? null : p.id,
                );
              } else {
                final newPicks = List<String>.from(currentPicks);
                if (isSelected) {
                  newPicks.remove(p.id);
                } else {
                  if (newPicks.length < 2) {
                    newPicks.add(p.id);
                  }
                }
                controller.handleInteraction(
                  stepId: step.id,
                  targetId: newPicks.isEmpty ? null : newPicks.join(','),
                );
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
    final color = RoleColorExtension(role).color;

    if (event.type == FeedEventType.result) {
      return CBMessageBubble(
        sender: 'SYSTEM',
        message: event.content,
        color: color,
        isSystemMessage: true,
      );
    }

    return CBMessageBubble(
      sender: player.name,
      message: event.content,
      avatarAsset: role.assetPath,
      color: color,
      isSender: event.type == FeedEventType.action,
    );
  }
}

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

import '../utils/role_color_extension.dart';

class GameBottomControls extends StatelessWidget {
  const GameBottomControls({
    super.key,
    required this.step,
    required this.gameState,
    required this.controller,
    required this.onConfirm,
    required this.onContinue,
  });

  final ScriptStep? step;
  final GameState gameState;
  final Game controller;
  final VoidCallback onConfirm;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    if (step == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Determine interactivity
    final isSelection =
        step!.actionType == ScriptActionType.selectPlayer ||
        step!.actionType == ScriptActionType.selectTwoPlayers ||
        step!.actionType == ScriptActionType.multiSelect;
    final isBinary = step!.actionType == ScriptActionType.binaryChoice;

    // Check completion status for "Next" button enabling
    final currentSelection = gameState.actionLog[step!.id];
    final isMultiSelect =
        step!.actionType == ScriptActionType.selectTwoPlayers ||
        step!.actionType == ScriptActionType.multiSelect;

    final canConfirm = isMultiSelect
        ? (currentSelection != null && currentSelection.split(',').length >= 2)
        : currentSelection != null;

    // Simulation availability
    final canSimulate =
        step!.id == 'day_vote' ||
        isSelection ||
        isBinary ||
        step!.actionType == ScriptActionType.optional;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── INPUT AREA ──
          if (isSelection)
            _buildPlayerSelectionGrid(context, step!, gameState, controller),
          if (isBinary) _buildBinaryChoice(context, step!, controller),

          if (isSelection || isBinary) const SizedBox(height: 12),

          // ── CONTROL BAR ──
          Row(
            children: [
              if (canSimulate)
                Expanded(
                  child: CBGhostButton(
                    label: 'AUTO-SIMULATE',
                    color: scheme.tertiary,
                    onPressed: () {
                      final count = controller.simulateBotTurns();
                      final msg = count > 0
                          ? 'SIMULATED $count BOT ACTION${count == 1 ? '' : 'S'}'
                          : 'NO BOTS AVAILABLE TO ACT';

                      showThemedSnackBar(
                        context,
                        msg,
                        accentColor: count > 0 ? scheme.tertiary : scheme.error,
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                ),
              if (canSimulate) const SizedBox(width: 12),

              if (isMultiSelect)
                Expanded(
                  flex: 2,
                  child: CBPrimaryButton(
                    label: 'CONFIRM SELECTION',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: canConfirm ? onConfirm : null,
                  ),
                ),

              if (!isMultiSelect)
                Expanded(
                  flex: 2,
                  child: CBPrimaryButton(
                    label: 'PROCEED',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => onContinue(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSelectionGrid(
    BuildContext context,
    ScriptStep step,
    GameState gameState,
    Game controller,
  ) {
    final eligiblePlayers = gameState.players.where((p) => p.isAlive).toList();
    final isMulti =
        step.actionType == ScriptActionType.selectTwoPlayers ||
        step.actionType == ScriptActionType.multiSelect;

    final currentPicks =
        gameState.actionLog[step.id]
            ?.split(',')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    if (eligiblePlayers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'NO ELIGIBLE TARGETS',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      );
    }

    return SizedBox(
      height: 140, // Fixed height scrollable area for inputs
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: eligiblePlayers.map((p) {
            final isSelected = currentPicks.contains(p.id);
            return CBCompactPlayerChip(
              name: p.name,
              assetPath: p.role.assetPath,
              color: RoleColorExtension(p.role).color,
              isSelected: isSelected,
              onTap: () {
                if (!isMulti) {
                  // Single select: toggle
                  controller.handleInteraction(
                    stepId: step.id,
                    targetId: isSelected ? null : p.id,
                  );
                } else {
                  // Multi select
                  final newPicks = List<String>.from(currentPicks);
                  if (isSelected) {
                    newPicks.remove(p.id);
                  } else {
                    if (newPicks.length < 2) {
                      // Cap at 2 for now, or use step config
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
      ),
    );
  }

  Widget _buildBinaryChoice(
    BuildContext context,
    ScriptStep step,
    Game controller,
  ) {
    final options = step.instructionText.split('|');
    final left = options.isNotEmpty ? options[0].trim() : 'YES';
    final right = options.length > 1 ? options[1].trim() : 'NO';
    final currentVal = gameState.actionLog[step.id];

    return Row(
      children: [
        Expanded(
          child: CBFilterChip(
            label: left,
            selected: currentVal == left,
            onSelected: () {
              controller.handleInteraction(stepId: step.id, targetId: left);
            },
            color: Theme.of(context).colorScheme.primary,
            dense: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CBFilterChip(
            label: right,
            selected: currentVal == right,
            onSelected: () {
              controller.handleInteraction(stepId: step.id, targetId: right);
            },
            color: Theme.of(context).colorScheme.error,
            dense: false,
          ),
        ),
      ],
    );
  }
}

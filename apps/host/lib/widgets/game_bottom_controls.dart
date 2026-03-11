import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

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
    final textTheme = theme.textTheme;

    // Determine interactivity
    final isSelection = step!.actionType == ScriptActionType.selectPlayer ||
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

    final canSimulate = step!.id == 'day_vote' ||
        isSelection ||
        isBinary ||
        step!.actionType == ScriptActionType.optional;

    return Container(
      padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x2, CBSpace.x4, CBSpace.x4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2), width: 1.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── INPUT AREA ──
          if (isSelection || isBinary) ...[
            CBFadeSlide(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 12, color: scheme.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 6),
                      Text(
                        'DIRECT INTERVENTION',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x3),
            if (isSelection)
              _buildPlayerSelectionGrid(context, step!, gameState, controller),
            if (isBinary)
              _buildBinaryChoice(context, step!, controller),
            const SizedBox(height: CBSpace.x4),
          ],

          // ── CONTROL BAR ──
          Row(
            children: [
              if (canSimulate)
                Expanded(
                  child: CBGhostButton(
                    label: 'AUTO-SIM',
                    icon: Icons.smart_toy_rounded,
                    color: scheme.tertiary,
                    onPressed: () {
                      HapticService.medium();
                      final count = controller.simulateBotTurns();
                      final msg = count > 0
                          ? 'SIMULATED $count BOT ACTIONS.'
                          : 'NO BOTS AVAILABLE TO ACT.';

                      showThemedSnackBar(
                        context,
                        msg,
                        accentColor: count > 0 ? scheme.tertiary : scheme.error,
                      );
                    },
                  ),
                ),
              if (canSimulate) const SizedBox(width: CBSpace.x3),

              Expanded(
                flex: 2,
                child: CBPrimaryButton(
                  label: isMultiSelect ? 'CONFIRM' : 'PROCEED',
                  icon: isMultiSelect ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                  onPressed: isMultiSelect 
                      ? (canConfirm ? onConfirm : null)
                      : onContinue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSelectionGrid(
      BuildContext context, ScriptStep step, GameState gameState, Game controller) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final eligiblePlayers = gameState.players.where((p) => p.isAlive).toList();
    final isMulti = step.actionType == ScriptActionType.selectTwoPlayers ||
                    step.actionType == ScriptActionType.multiSelect;

    final currentPicks = gameState.actionLog[step.id]
            ?.split(',')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    if (eligiblePlayers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(CBSpace.x4),
          child: Text(
            'NO ELIGIBLE TARGETS DETECTED.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.3),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(CBRadius.md),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: -2)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CBRadius.md),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CBSpace.x3),
          physics: const BouncingScrollPhysics(),
          child: Wrap(
            spacing: CBSpace.x2,
            runSpacing: CBSpace.x2,
            alignment: WrapAlignment.center,
            children: eligiblePlayers.map((p) {
              final isSelected = currentPicks.contains(p.id);
              final roleColor = CBColors.fromHex(p.role.colorHex);

              // Compute dynamic status chips
              final statuses = <String>[...p.statusEffects];
              
              if (gameState.players.any((other) => other.clingerPartnerId == p.id)) {
                if (!statuses.any((s) => s.toUpperCase() == 'OBSESSION')) statuses.add('OBSESSION');
              }
              
              if (gameState.players.any((other) => 
                  other.creepTargetId == p.id || 
                  other.teaSpillerTargetId == p.id || 
                  other.predatorTargetId == p.id ||
                  other.dramaQueenTargetAId == p.id ||
                  other.dramaQueenTargetBId == p.id)) {
                if (!statuses.any((s) => s.toUpperCase() == 'TARGET')) statuses.add('TARGET');
              }
              
              if (p.hasHostShield || gameState.players.any((other) => other.medicProtectedPlayerId == p.id)) {
                if (!statuses.any((s) => s.toUpperCase() == 'PROTECTED')) statuses.add('PROTECTED');
              }
              
              if (p.hasReviveToken) {
                if (!statuses.any((s) => s.toUpperCase() == 'SAVED')) statuses.add('SAVED');
              }

              return CBCompactPlayerChip(
                name: p.name,
                assetPath: p.role.assetPath,
                color: roleColor,
                isSelected: isSelected,
                statusEffects: statuses.take(3).toList(), // Limit to avoid overflow
                onTap: () {
                  HapticService.selection();
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
        ),
      ),
    );
  }

  Widget _buildBinaryChoice(BuildContext context, ScriptStep step, Game controller) {
    final scheme = Theme.of(context).colorScheme;
    final options = step.instructionText.split('|');
    final left = options.isNotEmpty ? options[0].trim() : 'YES';
    final right = options.length > 1 ? options[1].trim() : 'NO';
    final currentVal = gameState.actionLog[step.id];

    return Row(
      children: [
        Expanded(
          child: CBFilterChip(
            label: left.toUpperCase(),
            selected: currentVal == left,
            onSelected: () {
               HapticService.selection();
               controller.handleInteraction(stepId: step.id, targetId: left);
            },
            color: scheme.primary,
            dense: false,
          ),
        ),
        const SizedBox(width: CBSpace.x3),
        Expanded(
          child: CBFilterChip(
            label: right.toUpperCase(),
            selected: currentVal == right,
            onSelected: () {
               HapticService.selection();
               controller.handleInteraction(stepId: step.id, targetId: right);
            },
            color: scheme.error,
            dense: false,
          ),
        ),
      ],
    );
  }
}

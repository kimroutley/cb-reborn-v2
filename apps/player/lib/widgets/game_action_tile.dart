import 'package:cb_models/cb_models.dart' hide PlayerSnapshot;
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_bridge_actions.dart';
import 'package:cb_player/screens/player_selection_screen.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class GameActionTile extends StatefulWidget {
  final StepSnapshot step;
  final Color roleColor;
  final PlayerSnapshot player;
  final PlayerGameState gameState;
  final String playerId;
  final PlayerBridgeActions bridge;

  const GameActionTile({
    super.key,
    required this.step,
    required this.roleColor,
    required this.player,
    required this.gameState,
    required this.playerId,
    required this.bridge,
  });

  @override
  State<GameActionTile> createState() => _GameActionTileState();
}

class _GameActionTileState extends State<GameActionTile> {
  void _handleActionTap() {
    final isMultiSelect =
        widget.step.actionType == ScriptActionType.selectTwoPlayers.name;

    if (widget.step.isVote ||
        widget.step.actionType == ScriptActionType.selectPlayer.name ||
        isMultiSelect) {

      // Pass Lightweight's blocked vote targets if it's a vote step 
      // AND also filter them out from their night action so they can't double-block
      final disabledIds = widget.step.isVote || widget.step.roleId == RoleIds.lightweight
          ? widget.player.blockedVoteTargets
          : const <String>[];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerSelectionScreen(
            players: widget.gameState.players.where((p) => p.isAlive).toList(),
            step: widget.step,
            disabledIds: disabledIds,
            onPlayerSelected: (targetId) {
              if (widget.step.isVote) {
                widget.bridge
                    .vote(voterId: widget.playerId, targetId: targetId);
              } else {
                widget.bridge
                    .sendAction(stepId: widget.step.id, targetId: targetId);
              }

              if (!isMultiSelect || targetId.contains(',')) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      );
    } else if (widget.step.actionType == ScriptActionType.binaryChoice.name) {
      showThemedBottomSheet<void>(
        context: context,
        accentColor: widget.roleColor,
        child: Builder(
          builder: (context) {
            final textTheme = Theme.of(context).textTheme;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.step.title.toUpperCase(),
                  style: textTheme.labelLarge!.copyWith(
                    color: widget.roleColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows:
                        CBColors.textGlow(widget.roleColor, intensity: 0.5),
                  ),
                ),
                const SizedBox(height: 24),
                ...widget.step.options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: CBPrimaryButton(
                      label: option.toUpperCase(),
                      backgroundColor: widget.roleColor.withValues(alpha: 0.2),
                      foregroundColor: widget.roleColor,
                      onPressed: () {
                        widget.bridge.sendAction(
                            stepId: widget.step.id, targetId: option);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    IconData icon;
    String subTitle;

    if (widget.step.isVote) {
      title = "CRITICAL VOTE";
      icon = Icons.how_to_vote_rounded;
      subTitle = "EXILE PROTOCOL ACTIVE";
    } else if (widget.step.actionType == ScriptActionType.selectPlayer.name ||
        widget.step.actionType == ScriptActionType.selectTwoPlayers.name) {
      title = "SELECT TARGET";
      icon = Icons.gps_fixed_rounded;
      subTitle = "NEURAL LINK ESTABLISHED";
    } else if (widget.step.actionType == ScriptActionType.binaryChoice.name) {
      title = "MAKE A CHOICE";
      icon = Icons.alt_route_rounded;
      subTitle = "DECISION MATRIX LOADED";
    } else {
      title = "OPERATIVE ACTION";
      icon = Icons.flash_on_rounded;
      subTitle = "INPUT REQUIRED";
    }

    final instructionText = widget.step.instructionText.isNotEmpty
        ? widget.step.instructionText.toUpperCase()
        : "WAITING FOR YOUR INPUT...";

    return CBActionCard(
      title: title,
      subtitle: subTitle,
      instruction: instructionText,
      icon: icon,
      color: widget.roleColor,
      onTap: _handleActionTap,
      actionLabel: 'EXECUTE',
      trailing: widget.step.isVote ? Text(
        'VOTE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: widget.roleColor.withValues(alpha: 0.7),
          fontWeight: FontWeight.w900,
        ),
      ) : null,
    );
  }
}

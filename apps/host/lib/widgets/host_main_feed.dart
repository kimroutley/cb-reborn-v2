import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sheets/message_context_sheet.dart';
import 'game_bottom_controls.dart';
import '../screens/host_chat_view.dart';
import 'script_step_panel.dart';
import 'vote_tally_panel.dart';

/// The main feed for the host during the game.
/// Wraps [HostChatView] and adds script step controls and vote tallies.
class HostMainFeed extends ConsumerWidget {
  final GameState gameState;

  const HostMainFeed({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showStepPanel = gameState.phase != GamePhase.lobby &&
        gameState.phase != GamePhase.endGame &&
        gameState.currentStep != null;

    final currentStep = gameState.currentStep;
    final isDayVote =
        currentStep != null && StepKey.isDayVoteStep(currentStep.id);

    return Column(
      children: [
        if (showStepPanel) ScriptStepPanel(gameState: gameState),
        Expanded(
          child: HostChatView(
            gameState: gameState,
            showHeader: false,
          ),
        ),
        // ── STEP CONTROLS ──
        if (showStepPanel) ...[
          if (isDayVote)
            VoteTallyPanel(
              players: gameState.players,
              tally: gameState.dayVoteTally,
              votesByVoter: gameState.dayVotesByVoter,
            ),
          GameBottomControls(
            step: currentStep!,
            gameState: gameState,
            controller: ref.read(gameProvider.notifier),
            onConfirm: () {},
            onContinue: () async {
              HapticService.heavy();
              ref.read(gameProvider.notifier).advanceScript();
            },
            showInput: !isDayVote,
          ),
        ],
      ],
    );
  }
}

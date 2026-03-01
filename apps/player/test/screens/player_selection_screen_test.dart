import 'package:cb_models/cb_models.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/screens/player_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows player names for target selection even when role is redacted',
      (tester) async {
    final step = StepSnapshot(
      id: 'step_select',
      title: 'Select target',
      readAloudText: '',
      instructionText: '',
      actionType: ScriptActionType.selectPlayer.name,
    );

    final players = <PlayerSnapshot>[
      const PlayerSnapshot(
        id: 'p1',
        name: 'Alice',
        roleId: 'hidden',
        roleName: 'Unknown',
      ),
      const PlayerSnapshot(
        id: 'p2',
        name: 'Bob',
        roleId: 'hidden',
        roleName: 'Unknown',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerSelectionScreen(
          players: players,
          step: step,
          onPlayerSelected: (_) {},
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ALICE'), findsOneWidget);
    expect(find.text('BOB'), findsOneWidget);
    expect(find.text('UNKNOWN'), findsNothing);
  });

  testWidgets('shows voter names for each target during vote step',
      (tester) async {
    final step = StepSnapshot(
      id: 'day_vote_1',
      title: 'Vote',
      readAloudText: '',
      instructionText: '',
      actionType: ScriptActionType.selectPlayer.name,
    );

    final players = <PlayerSnapshot>[
      const PlayerSnapshot(
        id: 'p1',
        name: 'Alice',
        roleId: 'hidden',
        roleName: 'Unknown',
      ),
      const PlayerSnapshot(
        id: 'p2',
        name: 'Bob',
        roleId: 'hidden',
        roleName: 'Unknown',
      ),
      const PlayerSnapshot(
        id: 'p3',
        name: 'Cara',
        roleId: 'hidden',
        roleName: 'Unknown',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerSelectionScreen(
          players: players,
          step: step,
          currentPlayerId: 'p1',
          voteTally: const <String, int>{'p2': 2},
          votesByVoter: const <String, String>{
            'p1': 'p2',
            'p3': 'p2',
          },
          onPlayerSelected: (_) {},
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('VOTES: 2'), findsOneWidget);
    // Bob (p2) was voted by Cara and by current player (p1/Alice) -> "CARA, YOU"
    expect(find.textContaining('VOTED BY: CARA'), findsOneWidget);
    expect(find.textContaining('YOU'), findsOneWidget);
    expect(find.textContaining('VOTED BY: ALICE'), findsNothing);
  });
}

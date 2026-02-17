import 'package:cb_logic/cb_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StepKey', () {
    test('detects day vote step IDs', () {
      expect(StepKey.isDayVoteStep('day_vote_3'), true);
      expect(StepKey.isDayVoteStep('day_vote'), true);
      expect(StepKey.isDayVoteStep('dealer_act_player_3'), false);
    });

    test('extracts scoped player id with trailing day count', () {
      final playerId = StepKey.extractScopedPlayerId(
        stepId: 'dealer_act_player_one_3',
        prefix: 'dealer_act_',
      );
      expect(playerId, 'player_one');
    });

    test('extracts scoped player id without trailing day count', () {
      final playerId = StepKey.extractScopedPlayerId(
        stepId: 'dealer_act_player_one',
        prefix: 'dealer_act_',
      );
      expect(playerId, 'player_one');
    });

    test('returns null when prefix mismatches', () {
      final playerId = StepKey.extractScopedPlayerId(
        stepId: 'roofi_act_player_one_3',
        prefix: 'dealer_act_',
      );
      expect(playerId, null);
    });

    test('builds role action key', () {
      final key = StepKey.roleAction(
        roleId: 'dealer',
        playerId: 'player_one',
        dayCount: 4,
      );
      expect(key, 'dealer_act_player_one_4');
    });

    test('builds setup action key', () {
      final key = StepKey.setupAction(
        setupId: 'drama_queen_setup',
        playerId: 'player_one',
        dayCount: 0,
      );
      expect(key, 'drama_queen_setup_player_one_0');
    });
  });
}

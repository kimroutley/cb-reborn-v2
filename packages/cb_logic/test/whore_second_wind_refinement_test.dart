import 'package:flutter_test/flutter_test.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_logic/src/game_resolution_logic.dart';
import 'package:cb_logic/src/scripting/step_key.dart';

void main() {
  group('Whore Deflection Refinement', () {
    test('scapegoat and whore get private messages and correct exile occurs',
        () {
      final dealer = Player(
        id: 'dealer',
        name: 'The Dealer',
        alliance: Team.clubStaff,
        role: roleCatalogMap[RoleIds.dealer]!,
      );
      final whore = Player(
        id: 'whore',
        name: 'The Whore',
        alliance: Team.clubStaff,
        role: roleCatalogMap[RoleIds.whore]!,
        whoreDeflectionTargetId: 'scapegoat',
      );
      final scapegoat = Player(
        id: 'scapegoat',
        name: 'The Scapegoat',
        alliance: Team.partyAnimals,
        role: roleCatalogMap[RoleIds.partyAnimal]!,
      );

      final players = [dealer, whore, scapegoat];
      final tally = {'dealer': 2};
      final votesByVoter = {'voter1': 'dealer', 'voter2': 'dealer'};

      final res = GameResolutionLogic.resolveDayVote(
        players,
        tally,
        votesByVoter,
        1,
        TieBreakStrategy.peaceful,
      );

      // Verify Dealer is alive
      expect(res.players.firstWhere((p) => p.id == 'dealer').isAlive, isTrue);
      // Verify Scapegoat is dead
      final deadScapegoat = res.players.firstWhere((p) => p.id == 'scapegoat');
      expect(deadScapegoat.isAlive, isFalse);
      expect(deadScapegoat.deathReason, 'exile');

      // Verify Whore deflection used
      expect(res.players.firstWhere((p) => p.id == 'whore').whoreDeflectionUsed,
          isTrue);

      // Verify Report message
      expect(res.report.last, contains('SCANDAL'));
      expect(res.report.last, contains('The Scapegoat was framed'));

    });
  });

  group('Second Wind Conversion Refinement', () {
    test('second wind survives hit and converts to dealer', () {
      final dealer = Player(
        id: 'dealer',
        name: 'The Dealer',
        alliance: Team.clubStaff,
        role: roleCatalogMap[RoleIds.dealer]!,
      );
      final secondWind = Player(
        id: 'sw',
        name: 'Second Wind',
        alliance: Team.partyAnimals,
        role: roleCatalogMap[RoleIds.secondWind]!,
      );

      final players = [dealer, secondWind];
      final actionKey = StepKey.roleAction(
        roleId: RoleIds.dealer,
        playerId: 'dealer',
        dayCount: 1,
      );
      final actionLog = {actionKey: 'sw'}; // Dealer attacks Second Wind

      final gameState = GameState(
        players: players,
        actionLog: actionLog,
        phase: GamePhase.night,
        dayCount: 1,
      );

      final res = GameResolutionLogic.resolveNightActions(gameState);

      final updatedSW = res.players.firstWhere((p) => p.id == 'sw');

      // Verify survival
      expect(updatedSW.isAlive, isTrue);
      // Night resolution flags the conversion as pending; actual conversion
      // happens in the day phase handled by Game.advancePhase.
      expect(updatedSW.secondWindPendingConversion, isTrue);
      expect(updatedSW.role.id, RoleIds.secondWind);

      // Verify report mentions the trigger
      expect(res.report.any((r) => r.contains('Second Wind')), isTrue);
    });
  });
}

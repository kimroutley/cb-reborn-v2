import 'package:flutter_test/flutter_test.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_logic/src/game_resolution_logic.dart';
import 'package:cb_logic/src/scripting/step_key.dart';

void main() {
  group('Whore Deflection Refinement', () {
    test('scapegoat and whore get private messages and correct exile occurs', () {
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
        TieBreakStrategy.peaceful,
        1,
      );

      // Verify Dealer is alive
      expect(res.players.firstWhere((p) => p.id == 'dealer').isAlive, isTrue);
      // Verify Scapegoat is dead
      final deadScapegoat = res.players.firstWhere((p) => p.id == 'scapegoat');
      expect(deadScapegoat.isAlive, isFalse);
      expect(deadScapegoat.deathReason, 'exile');

      // Verify Whore deflection used
      expect(res.players.firstWhere((p) => p.id == 'whore').whoreDeflectionUsed, isTrue);

      // Verify Report message
      expect(res.report.last, contains('ABSOLUTE CHAOS'));
      expect(res.report.last, contains('The Scapegoat has been framed'));

      // Verify Private Messages
      expect(res.privateMessages['scapegoat'], contains(contains("You've been framed")));
      expect(res.privateMessages['whore'], contains(contains("Your scapegoat worked perfectly")));
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
      // Verify conversion
      expect(updatedSW.role.id, RoleIds.dealer);
      expect(updatedSW.alliance, Team.clubStaff);
      expect(updatedSW.secondWindConverted, isTrue);

      // Verify Private Message
      expect(res.privateMessages['sw'], contains(contains("You've survived, but the club staff has noticed your 'resilience'")));
    });
  });
}

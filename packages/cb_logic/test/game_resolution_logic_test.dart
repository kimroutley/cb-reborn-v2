import 'package:flutter_test/flutter_test.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_logic/src/game_resolution_logic.dart';

void main() {
  group('GameResolutionLogic.checkWinCondition', () {
    // Helper to create a dummy player
    Player createPlayer({
      required String id,
      required Team alliance,
      bool isAlive = true,
      Role? role,
    }) {
      return Player(
        id: id,
        name: 'Player $id',
        alliance: alliance,
        isAlive: isAlive,
        role:
            role ??
            const Role(
              id: 'dummy_role',
              name: 'Dummy Role',
              type: 'dummy',
              description: 'A dummy role for testing',
              nightPriority: 0,
              assetPath: 'assets/images/roles/dummy.png',
              colorHex: '#000000',
            ),
      );
    }

    test('returns null when game should continue (Staff < PA)', () {
      final players = [
        createPlayer(id: '1', alliance: Team.clubStaff),
        createPlayer(id: '2', alliance: Team.partyAnimals),
        createPlayer(id: '3', alliance: Team.partyAnimals),
      ];
      final result = GameResolutionLogic.checkWinCondition(players);
      expect(result, isNull);
    });

    test('returns Staff win when Staff >= PA (Majority)', () {
      final players = [
        createPlayer(id: '1', alliance: Team.clubStaff),
        createPlayer(id: '2', alliance: Team.clubStaff),
        createPlayer(id: '3', alliance: Team.partyAnimals),
      ];
      final result = GameResolutionLogic.checkWinCondition(players);
      expect(result, isNotNull);
      expect(result!.winner, Team.clubStaff);
    });

    test('returns Staff win when Staff == PA (Tie)', () {
      final players = [
        createPlayer(id: '1', alliance: Team.clubStaff),
        createPlayer(id: '2', alliance: Team.partyAnimals),
      ];
      final result = GameResolutionLogic.checkWinCondition(players);
      expect(result, isNotNull);
      expect(result!.winner, Team.clubStaff);
    });

    test('returns Staff win when only Staff remain', () {
      final players = [createPlayer(id: '1', alliance: Team.clubStaff)];
      final result = GameResolutionLogic.checkWinCondition(players);
      expect(result, isNotNull);
      expect(result!.winner, Team.clubStaff);
    });

    test('returns Party Animals win when all Staff are eliminated', () {
      final players = [
        createPlayer(id: '1', alliance: Team.clubStaff, isAlive: false),
        createPlayer(id: '2', alliance: Team.partyAnimals),
      ];
      final result = GameResolutionLogic.checkWinCondition(players);
      expect(result, isNotNull);
      expect(result!.winner, Team.partyAnimals);
    });

    test(
      'returns Party Animals win even if all players are dead (if staff existed)',
      () {
        final players = [
          createPlayer(id: '1', alliance: Team.clubStaff, isAlive: false),
          createPlayer(id: '2', alliance: Team.partyAnimals, isAlive: false),
        ];
        final result = GameResolutionLogic.checkWinCondition(players);
        expect(result, isNotNull);
        expect(result!.winner, Team.partyAnimals);
      },
    );

    test('returns null if there were never any Staff', () {
      final players = [
        createPlayer(id: '1', alliance: Team.partyAnimals),
        createPlayer(id: '2', alliance: Team.partyAnimals),
      ];
      final result = GameResolutionLogic.checkWinCondition(players);
      expect(result, isNull);
    });

    test('returns null for empty player list', () {
      final players = <Player>[];
      final result = GameResolutionLogic.checkWinCondition(players);
      expect(result, isNull);
    });

    test('ignores Neutral players for win condition counts', () {
      // 1 Staff, 1 PA, 1 Neutral -> Staff: 1, PA: 1 -> Tie -> Staff Win
      final players = [
        createPlayer(id: '1', alliance: Team.clubStaff),
        createPlayer(id: '2', alliance: Team.partyAnimals),
        createPlayer(id: '3', alliance: Team.neutral),
      ];
      final result = GameResolutionLogic.checkWinCondition(players);
      expect(result, isNotNull);
      expect(result!.winner, Team.clubStaff);
    });

    test(
      'Game continues if Neutral players tip the balance to not meeting win conditions',
      () {
        // 1 Staff, 2 PA, 1 Neutral -> Staff: 1, PA: 2 -> No win.
        final players = [
          createPlayer(id: '1', alliance: Team.clubStaff),
          createPlayer(id: '2', alliance: Team.partyAnimals),
          createPlayer(id: '3', alliance: Team.partyAnimals),
          createPlayer(id: '4', alliance: Team.neutral),
        ];
        final result = GameResolutionLogic.checkWinCondition(players);
        expect(result, isNull);
      },
    );

    test(
      'returns Neutral win when living Messy Bitch has spread rumor to all living players',
      () {
        final messyBitchRole = roleCatalogMap[RoleIds.messyBitch]!;
        final players = [
          createPlayer(
            id: '1',
            alliance: Team.neutral,
            role: messyBitchRole,
          ).copyWith(hasRumour: true),
          createPlayer(
            id: '2',
            alliance: Team.clubStaff,
          ).copyWith(hasRumour: true),
          createPlayer(
            id: '3',
            alliance: Team.partyAnimals,
          ).copyWith(hasRumour: true),
        ];

        final result = GameResolutionLogic.checkWinCondition(players);
        expect(result, isNotNull);
        expect(result!.winner, Team.neutral);
      },
    );

    test(
      'does not return Neutral win if not all living players have rumor',
      () {
        final messyBitchRole = roleCatalogMap[RoleIds.messyBitch]!;
        final players = [
          createPlayer(
            id: '1',
            alliance: Team.neutral,
            role: messyBitchRole,
          ).copyWith(hasRumour: true),
          createPlayer(
            id: '2',
            alliance: Team.clubStaff,
          ).copyWith(hasRumour: true),
          createPlayer(
            id: '3',
            alliance: Team.partyAnimals,
          ).copyWith(hasRumour: false),
        ];

        final result = GameResolutionLogic.checkWinCondition(players);
        expect(result, isNotNull);
        expect(result!.winner, isNot(Team.neutral));
      },
    );

    test(
      'does not return Neutral win when Messy Bitch is dead even if all living have rumor',
      () {
        final messyBitchRole = roleCatalogMap[RoleIds.messyBitch]!;
        final players = [
          createPlayer(
            id: '1',
            alliance: Team.neutral,
            role: messyBitchRole,
            isAlive: false,
          ).copyWith(hasRumour: true),
          createPlayer(
            id: '2',
            alliance: Team.clubStaff,
          ).copyWith(hasRumour: true),
          createPlayer(
            id: '3',
            alliance: Team.partyAnimals,
          ).copyWith(hasRumour: true),
        ];

        final result = GameResolutionLogic.checkWinCondition(players);
        expect(result, isNotNull);
        expect(result!.winner, isNot(Team.neutral));
      },
    );
  });
}

import 'package:cb_player/player_stats.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerStats', () {
    test('winRate calculates correctly', () {
      const statsZero = PlayerStats(playerId: '1', gamesPlayed: 0, gamesWon: 0);
      expect(statsZero.winRate, 0.0);

      const statsHalf =
          PlayerStats(playerId: '1', gamesPlayed: 10, gamesWon: 5);
      expect(statsHalf.winRate, 50.0);

      const statsFull =
          PlayerStats(playerId: '1', gamesPlayed: 10, gamesWon: 10);
      expect(statsFull.winRate, 100.0);

      const statsNone =
          PlayerStats(playerId: '1', gamesPlayed: 10, gamesWon: 0);
      expect(statsNone.winRate, 0.0);

      const statsOneThird =
          PlayerStats(playerId: '1', gamesPlayed: 3, gamesWon: 1);
      expect(statsOneThird.winRate, closeTo(33.33, 0.01));
    });

    test('favoriteRole returns N/A when no roles played', () {
      const stats = PlayerStats(playerId: '1', rolesPlayed: {});
      expect(stats.favoriteRole, 'N/A');
    });

    test('favoriteRole returns correct role name for single role', () {
      final stats = PlayerStats(
        playerId: '1',
        rolesPlayed: {RoleIds.partyAnimal: 5},
      );
      // "The Party Animal" comes from roleCatalogMap lookup
      expect(stats.favoriteRole, 'The Party Animal');
    });

    test('favoriteRole returns correct role name for most played role', () {
      final stats = PlayerStats(
        playerId: '1',
        rolesPlayed: {
          RoleIds.partyAnimal: 2,
          RoleIds.dealer: 5,
        },
      );
      expect(stats.favoriteRole, 'The Dealer');
    });

    test('favoriteRole breaks ties by taking the last one encountered', () {
      // The implementation uses reduce((a, b) => a.value > b.value ? a : b)
      // If values are equal, it returns b. So the last one in the iteration order.
      // Map literal preserves insertion order.
      final stats = PlayerStats(
        playerId: '1',
        rolesPlayed: {
          RoleIds.partyAnimal: 5,
          RoleIds.dealer: 5,
        },
      );
      // 'dealer' is inserted second, so it should be the favorite.
      expect(stats.favoriteRole, 'The Dealer');

      final stats2 = PlayerStats(
        playerId: '1',
        rolesPlayed: {
          RoleIds.dealer: 5,
          RoleIds.partyAnimal: 5,
        },
      );
      // 'party_animal' is inserted second, so it should be the favorite.
      expect(stats2.favoriteRole, 'The Party Animal');
    });

    test('favoriteRole handles unknown roles gracefully', () {
      final stats = PlayerStats(
        playerId: '1',
        rolesPlayed: {'unknown_role_id': 1},
      );
      // Should format 'unknown_role_id' to 'unknown role id'
      expect(stats.favoriteRole, 'unknown role id');
    });

    test('copyWith updates fields correctly', () {
      const stats = PlayerStats(
        playerId: '1',
        gamesPlayed: 5,
        gamesWon: 2,
        rolesPlayed: {RoleIds.partyAnimal: 5},
      );

      final updated = stats.copyWith(
        gamesPlayed: 6,
        gamesWon: 3,
      );

      expect(updated.playerId, '1');
      expect(updated.gamesPlayed, 6);
      expect(updated.gamesWon, 3);
      expect(updated.rolesPlayed, {RoleIds.partyAnimal: 5});
    });

    test('copyWith maintains existing values if arguments are null', () {
      const stats = PlayerStats(
        playerId: '1',
        gamesPlayed: 5,
        gamesWon: 2,
        rolesPlayed: {RoleIds.partyAnimal: 5},
      );

      final updated = stats.copyWith();

      expect(updated.playerId, '1');
      expect(updated.gamesPlayed, 5);
      expect(updated.gamesWon, 2);
      expect(updated.rolesPlayed, {RoleIds.partyAnimal: 5});
    });
  });
}

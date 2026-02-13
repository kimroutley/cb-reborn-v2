import 'dart:async';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class PlayerStats {
  final String playerId;
  final int gamesPlayed;
  final int gamesWon;
  final Map<String, int> rolesPlayed;

  const PlayerStats({
    required this.playerId,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.rolesPlayed = const {},
  });

  double get winRate => gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0;

  String get favoriteRole {
    if (rolesPlayed.isEmpty) {
      return 'N/A';
    }
    final roleId =
        rolesPlayed.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final role = roleCatalogMap[roleId];
    return role?.name ?? roleId.replaceAll('_', ' ');
  }

  PlayerStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    Map<String, int>? rolesPlayed,
  }) {
    return PlayerStats(
      playerId: playerId,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      rolesPlayed: rolesPlayed ?? this.rolesPlayed,
    );
  }
}

class PlayerStatsNotifier extends Notifier<PlayerStats> {
  // For simplicity, this will track stats for the currently active player ID.
  // A more robust solution might store stats per player ID.
  String _activePlayerId = 'player_1'; // Default/placeholder

  @override
  PlayerStats build() {
    _loadStats();
    return PlayerStats(playerId: _activePlayerId);
  }

  // Setter to update the active player ID and reload stats
  void setActivePlayerId(String id) {
    if (_activePlayerId == id) return;
    _activePlayerId = id;
    _loadStats();
  }

  Future<void> _loadStats() async {
    final records = PersistenceService.instance.loadGameRecords();

    int gamesPlayed = 0;
    int gamesWon = 0;
    final Map<String, int> rolesPlayed = {};

    for (final record in records) {
      // Only consider games where this player participated
      final playerInRecord = record.roster.firstWhereOrNull(
        (p) => p.id == _activePlayerId,
      );
      if (playerInRecord != null) {
        gamesPlayed++;
        if (record.winner == playerInRecord.alliance) {
          gamesWon++;
        }
        rolesPlayed.update(playerInRecord.roleId, (value) => value + 1,
            ifAbsent: () => 1);
      }
    }

    state = state.copyWith(
      gamesPlayed: gamesPlayed,
      gamesWon: gamesWon,
      rolesPlayed: rolesPlayed,
    );
  }
}

final playerStatsProvider = NotifierProvider<PlayerStatsNotifier, PlayerStats>(
  PlayerStatsNotifier.new,
);

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

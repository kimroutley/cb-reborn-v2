import 'package:cb_models/cb_models.dart';

class GamePlayerController {
  static const int maxPlayers = 25;
  static final _whitespaceRegex = RegExp(r'\s+');

  static String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(_whitespaceRegex, ' ');
  }

  static String _buildUniqueName(String desired, List<Player> players, {String? excludePlayerId}) {
    final base = desired.trim();
    if (base.isEmpty) {
      return desired;
    }

    final existing = players
        .where((p) => p.id != excludePlayerId)
        .map((p) => _normalizeName(p.name))
        .toSet();

    var candidate = base;
    var suffix = 2;
    while (existing.contains(_normalizeName(candidate))) {
      candidate = '$base ($suffix)';
      suffix++;
    }
    return candidate;
  }

  static String _buildUniquePlayerId(String baseId, List<Player> players) {
    final existingIds = players.map((p) => p.id).toSet();
    var candidate = baseId;
    var suffix = 2;
    while (existingIds.contains(candidate)) {
      candidate = '${baseId}_$suffix';
      suffix++;
    }
    return candidate;
  }

  static GameState addPlayer(GameState state, String name, {String? authUid}) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return state;
    }

    if (authUid != null && authUid.isNotEmpty) {
      final existingByUid = state.players.where((p) => p.authUid == authUid);
      if (existingByUid.isNotEmpty) {
        final existing = existingByUid.first;
        final nextName = _buildUniqueName(
          trimmedName,
          state.players,
          excludePlayerId: existing.id,
        );
        return state.copyWith(
          players: state.players
              .map(
                (p) => p.id == existing.id
                    ? p.copyWith(name: nextName, authUid: authUid)
                    : p,
              )
              .toList(),
        );
      }
    }

    if (state.players.length >= maxPlayers) {
      return state;
    }

    final canonicalName = _buildUniqueName(trimmedName, state.players);
    final seedId = (authUid != null && authUid.isNotEmpty)
        ? authUid.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        : canonicalName.toLowerCase().replaceAll(' ', '_');
    final id = _buildUniquePlayerId(seedId, state.players);

    final newPlayer = Player(
      id: id,
      name: canonicalName,
      authUid: authUid,
      role: Role(
        id: 'unassigned',
        name: 'Unassigned',
        alliance: Team.unknown,
        type: '',
        description: '',
        nightPriority: 0,
        assetPath: '',
        colorHex: '#000000',
      ),
      alliance: Team.unknown,
    );
    return state.copyWith(players: [...state.players, newPlayer]);
  }

  static GameState removePlayer(GameState state, String id) {
    return state.copyWith(
      players: state.players.where((p) => p.id != id).toList(),
    );
  }

  static GameState updatePlayerName(GameState state, String id, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      return state;
    }

    final updatedName = _buildUniqueName(trimmed, state.players, excludePlayerId: id);
    return state.copyWith(
      players: state.players
          .map((p) => p.id == id ? p.copyWith(name: updatedName) : p)
          .toList(),
    );
  }

  static GameState mergePlayers(GameState state, {required String sourceId, required String targetId}) {
    if (sourceId == targetId) {
      return state;
    }

    final source = state.players.where((p) => p.id == sourceId).toList();
    final target = state.players.where((p) => p.id == targetId).toList();
    if (source.isEmpty || target.isEmpty) {
      return state;
    }

    final src = source.first;
    final tgt = target.first;
    final mergedTarget = tgt.copyWith(
      authUid: tgt.authUid ?? src.authUid,
      name: _buildUniqueName(tgt.name, state.players, excludePlayerId: targetId),
    );

    return state.copyWith(
      players: state.players
          .where((p) => p.id != sourceId)
          .map((p) => p.id == targetId ? mergedTarget : p)
          .toList(),
      gameHistory: [
        ...state.gameHistory,
        '[HOST] Merged ${src.name} into ${mergedTarget.name}',
      ],
    );
  }

  static GameState assignRole(GameState state, String playerId, String roleId) {
    final role = roleCatalogMap[roleId] ?? roleCatalog.first;
    return state.copyWith(
      players: state.players
          .map(
            (p) => p.id == playerId
                ? p.copyWith(
                    role: role,
                    alliance: role.alliance,
                    lives: role.id == RoleIds.allyCat ? 9 : p.lives,
                  )
                : p,
          )
          .toList(),
    );
  }
}

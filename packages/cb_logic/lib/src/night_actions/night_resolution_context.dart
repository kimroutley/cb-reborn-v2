import 'package:cb_models/cb_models.dart';
import '../game_resolution_logic.dart';

class NightResolutionContext {
  final List<Player> _players;
  final Map<String, String> log;
  final int dayCount;
  final Map<String, List<String>> _privateMessages;

  // Mutable State
  final List<String> report = [];
  final List<String> teasers = [];

  // Accumulated data from actions
  final Set<String> blockedIds = {};
  final Set<String> protectedIds = {};
  final Set<String> silencedIds = {};
  final List<String> murderTargets = [];

  NightResolutionContext({
    required List<Player> players,
    required this.log,
    required this.dayCount,
    required Map<String, List<String>> privateMessages,
  })  : _players = List<Player>.from(players),
        _privateMessages = Map<String, List<String>>.from(privateMessages);

  List<Player> get players => _players;
  Map<String, List<String>> get privateMessages => _privateMessages;

  void updatePlayer(Player player) {
    final index = _players.indexWhere((p) => p.id == player.id);
    if (index != -1) {
      _players[index] = player;
    }
  }

  void addPrivateMessage(String playerId, String message) {
    _privateMessages.putIfAbsent(playerId, () => []).add(message);
  }

  Player getPlayer(String id) {
    return _players.firstWhere((p) => p.id == id);
  }

  NightResolution toNightResolution() {
    return NightResolution(
      players: _players,
      report: report,
      teasers: teasers,
      privateMessages: _privateMessages,
    );
  }
}

import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../active_bridge.dart';
import '../player_bridge.dart';
import '../widgets/custom_drawer.dart';

/// Wrapper for CB Guide Screen in player app.
/// This ensures visually mirrored parity with the host app bible.
class GuidesScreen extends ConsumerWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBridge = ref.watch(activeBridgeProvider);
    final playerState = activeBridge.state;

    // Construct GameState from playerState
    final gameState = _mapToGameState(playerState);

    // Construct local Player from playerState.myPlayerSnapshot
    final localPlayer = _mapToPlayer(playerState.myPlayerSnapshot);

    return CBGuideScreen(
      gameState: gameState,
      localPlayer: localPlayer,
      drawer: const CustomDrawer(),
    );
  }

  GameState _mapToGameState(PlayerGameState state) {
    return GameState(
      phase: _mapPhase(state.phase),
      dayCount: state.dayCount,
      players: state.players.map((p) => _mapToPlayer(p)!).toList(),
      bulletinBoard: state.bulletinBoard,
      eyesOpen: state.eyesOpen,
      winner: _mapTeam(state.winner),
      endGameReport: state.endGameReport,
      rematchOffered: state.rematchOffered,
      privateMessages: state.privateMessages,
      gameHistory: state.gameHistory,
      deadPoolBets: state.deadPoolBets,
      playerStats: state.playerStats,
    );
  }

  Player? _mapToPlayer(PlayerSnapshot? snapshot) {
    if (snapshot == null) return null;
    final role = roleCatalogMap[snapshot.roleId] ?? roleCatalog.first;
    return Player(
      id: snapshot.id,
      name: snapshot.name,
      authUid: snapshot.authUid,
      role: role,
      alliance: snapshot.allianceTeam,
      isAlive: snapshot.isAlive,
      lives: snapshot.lives,
      isBot: snapshot.isBot,
      drinksOwed: snapshot.drinksOwed,
      penalties: snapshot.penalties,
      deathDay: snapshot.deathDay,
      currentBetTargetId: snapshot.currentBetTargetId,
      medicChoice: snapshot.medicChoice,
      hasReviveToken: snapshot.hasReviveToken,
      hasRumour: snapshot.hasRumour,
      clingerPartnerId: snapshot.clingerPartnerId,
      blockedVoteTargets: snapshot.blockedVoteTargets,
      secondWindPendingConversion: snapshot.secondWindPendingConversion,
      creepTargetId: snapshot.creepTargetId,
      whoreDeflectionUsed: snapshot.whoreDeflectionUsed,
      silencedDay: snapshot.silencedDay,
    );
  }

  GamePhase _mapPhase(String phase) {
    return GamePhase.values.firstWhere(
      (e) => e.name == phase,
      orElse: () => GamePhase.lobby,
    );
  }

  Team? _mapTeam(String? team) {
    if (team == null) return null;
    return Team.values.firstWhere(
      (e) => e.name == team,
      orElse: () => Team.unknown,
    );
  }
}

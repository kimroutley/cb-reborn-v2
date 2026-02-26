import 'package:cb_models/cb_models.dart';
import '../player_bridge.dart';

/// Generates dynamic, context-aware strategy intel for the player based on
/// the current game situation. Works with [PlayerGameState] / [PlayerSnapshot]
/// (the player-side models) rather than the host-side [GameState].
class PlayerStrategyEngine {
  PlayerStrategyEngine._();

  /// Categorised situational tip with a severity/type tag.
  static List<SituationTip> evaluateSituation({
    required PlayerSnapshot player,
    required PlayerGameState gameState,
  }) {
    final tips = <SituationTip>[];
    final alive = gameState.players.where((p) => p.isAlive).toList();
    final dead = gameState.players.where((p) => !p.isAlive).toList();
    final isClubStaff = player.isClubStaff;
    final phase = gameState.phase;
    final day = gameState.dayCount;

    _addPhaseAdvice(tips, phase: phase, day: day, roleId: player.roleId, isStaff: isClubStaff);
    _addRosterIntel(tips, alive: alive, dead: dead, player: player, isStaff: isClubStaff);
    _addVoteAnalysis(tips, gameState: gameState, alive: alive, player: player);
    _addPersonalStatus(tips, player: player, gameState: gameState);
    _addEndgamePressure(tips, alive: alive, isStaff: isClubStaff, phase: phase);

    tips.sort((a, b) => a.priority.compareTo(b.priority));
    return tips;
  }

  // ── Phase-aware advice ──────────────────────────────────────────────────

  static void _addPhaseAdvice(
    List<SituationTip> tips, {
    required String phase,
    required int day,
    required String roleId,
    required bool isStaff,
  }) {
    if (phase == 'night') {
      if (isStaff) {
        tips.add(const SituationTip(
          type: TipType.deception,
          text: 'Night phase active. Coordinate your kill to frame a vocal innocent — silence is your ally.',
          priority: 2,
        ));
      } else {
        tips.add(const SituationTip(
          type: TipType.survival,
          text: 'Night phase active. Stay alert — Dealers are choosing their next victim. Your fate is in their hands.',
          priority: 2,
        ));
      }
    }

    if (phase == 'day' && day == 1) {
      tips.add(const SituationTip(
        type: TipType.strategy,
        text: 'Day 1 is data-gathering. Watch who pushes for fast votes — experienced Dealers rush exiles to reduce information.',
        priority: 3,
      ));
    }

    if (phase == 'day' && day >= 3) {
      tips.add(SituationTip(
        type: TipType.warning,
        text: 'Day $day — the game is heating up. Every vote from here can decide the winner.',
        priority: 2,
      ));
    }
  }

  // ── Roster-based intel ──────────────────────────────────────────────────

  static void _addRosterIntel(
    List<SituationTip> tips, {
    required List<PlayerSnapshot> alive,
    required List<PlayerSnapshot> dead,
    required PlayerSnapshot player,
    required bool isStaff,
  }) {
    final bouncerAlive = alive.any((p) => p.roleId == RoleIds.bouncer);
    final medicAlive = alive.any((p) => p.roleId == RoleIds.medic);
    final roofiAlive = alive.any((p) => p.roleId == RoleIds.roofi);
    final bartenderAlive = alive.any((p) => p.roleId == RoleIds.bartender);

    if (isStaff) {
      if (bouncerAlive) {
        tips.add(const SituationTip(
          type: TipType.warning,
          text: 'The Bouncer is ALIVE and investigating. Blend in — every night action you take is a risk of exposure.',
          priority: 1,
        ));
      } else {
        tips.add(const SituationTip(
          type: TipType.opportunity,
          text: 'The Bouncer is DEAD. No more ID checks — you can afford bolder plays tonight.',
          priority: 3,
        ));
      }

      if (!medicAlive) {
        tips.add(const SituationTip(
          type: TipType.opportunity,
          text: 'The Medic is neutralised. Every kill you make will stick — no saves, no resurrections.',
          priority: 3,
        ));
      }

      if (roofiAlive) {
        tips.add(const SituationTip(
          type: TipType.warning,
          text: 'Roofi is active. They can block your kill and silence a teammate — watch for their targeting pattern.',
          priority: 2,
        ));
      }
    } else {
      if (!bouncerAlive) {
        tips.add(const SituationTip(
          type: TipType.warning,
          text: 'Your investigator is down. Rely on social reads and voting patterns — no more ID checks are coming.',
          priority: 1,
        ));
      }

      if (!medicAlive) {
        tips.add(const SituationTip(
          type: TipType.warning,
          text: 'No Medic protection available. Every death is permanent — vote wisely.',
          priority: 2,
        ));
      }

      if (bartenderAlive && bouncerAlive) {
        tips.add(const SituationTip(
          type: TipType.opportunity,
          text: 'Both Bouncer and Bartender are alive. Cross-referencing their intel can confirm Dealers — push for data sharing.',
          priority: 3,
        ));
      }
    }

    final deathsToday = dead.where((p) => p.deathDay != null).length;
    if (deathsToday >= 2 && dead.length >= 3) {
      tips.add(const SituationTip(
        type: TipType.strategy,
        text: 'Multiple casualties are mounting. Expect panic votes — keep your head and analyse before committing.',
        priority: 2,
      ));
    }
  }

  // ── Vote pattern analysis ─────────────────────────────────────────────

  static void _addVoteAnalysis(
    List<SituationTip> tips, {
    required PlayerGameState gameState,
    required List<PlayerSnapshot> alive,
    required PlayerSnapshot player,
  }) {
    final tally = gameState.voteTally;
    if (tally.isEmpty) return;

    final sorted = tally.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final leader = sorted.first;
    final secondVotes = sorted.length > 1 ? sorted[1].value : 0;

    if (leader.value >= 3) {
      final isMe = leader.key == player.id;
      if (isMe) {
        tips.add(SituationTip(
          type: TipType.critical,
          text: 'You have ${leader.value} votes stacked against you! Defend yourself NOW or rally allies to shift the vote.',
          priority: 0,
        ));
      } else {
        tips.add(SituationTip(
          type: TipType.strategy,
          text: '${leader.value} votes are piling on one player. Watch for last-second vote switches — Dealers manipulate pileups.',
          priority: 2,
        ));
      }
    }

    if (leader.value > 0 && (leader.value - secondVotes).abs() <= 1 && sorted.length > 1) {
      tips.add(const SituationTip(
        type: TipType.strategy,
        text: 'The vote is razor-thin. One swing can decide the exile — this is where Dealers make their move.',
        priority: 2,
      ));
    }

    final turnout = gameState.votesByVoter.length;
    final healthyTurnout = (alive.length * 0.6).ceil();
    if (turnout > 0 && turnout < healthyTurnout) {
      tips.add(SituationTip(
        type: TipType.deception,
        text: 'Low vote turnout ($turnout/${alive.length}). Quiet players are controlling information flow — call them out.',
        priority: 3,
      ));
    }
  }

  // ── Personal status tips ──────────────────────────────────────────────

  static void _addPersonalStatus(
    List<SituationTip> tips, {
    required PlayerSnapshot player,
    required PlayerGameState gameState,
  }) {
    if (player.lives > 1) {
      tips.add(SituationTip(
        type: TipType.opportunity,
        text: 'You have ${player.lives} lives remaining. Use your durability to draw fire from fragile power roles.',
        priority: 3,
      ));
    }

    if (player.silencedDay == gameState.dayCount) {
      tips.add(const SituationTip(
        type: TipType.critical,
        text: 'You were SILENCED by Roofi. Your night action was blocked — adapt your strategy.',
        priority: 0,
      ));
    }

    if (player.hasRumour) {
      tips.add(const SituationTip(
        type: TipType.warning,
        text: 'The Messy Bitch spread a rumour about you. This is public — use it to gauge who reacts suspiciously.',
        priority: 3,
      ));
    }

    if (player.tabooNames.isNotEmpty) {
      tips.add(SituationTip(
        type: TipType.critical,
        text: 'TABOO ACTIVE: ${player.tabooNames.length} words will kill you instantly if spoken. Triple-check every message.',
        priority: 0,
      ));
    }

    if (player.secondWindPendingConversion) {
      tips.add(const SituationTip(
        type: TipType.critical,
        text: 'Dealers are deciding your fate: CONVERT or EXECUTE. Your entire alliance is about to change.',
        priority: 0,
      ));
    }

    if (player.clingerPartnerId != null) {
      final partnerAlive = gameState.players.any(
        (p) => p.id == player.clingerPartnerId && p.isAlive,
      );
      if (partnerAlive) {
        tips.add(const SituationTip(
          type: TipType.warning,
          text: 'Your Clinger partner is alive. Protect them — if they die, you die too.',
          priority: 1,
        ));
      }
    }

    if (player.hasReviveToken) {
      if (gameState.dayCount >= 3) {
        tips.add(const SituationTip(
          type: TipType.warning,
          text: 'Your Revive Token is still unused on Day 3+. Don\'t die with it — use it or lose it.',
          priority: 1,
        ));
      }
    }
  }

  // ── Endgame pressure ──────────────────────────────────────────────────

  static void _addEndgamePressure(
    List<SituationTip> tips, {
    required List<PlayerSnapshot> alive,
    required bool isStaff,
    required String phase,
  }) {
    if (alive.length <= 4 && phase == 'day') {
      tips.add(const SituationTip(
        type: TipType.critical,
        text: 'ENDGAME: Few players remain. Every single vote is decisive — one mistake ends it all.',
        priority: 0,
      ));
    }

    final staffAlive = alive.where((p) => p.isClubStaff).length;
    final townAlive = alive.length - staffAlive;

    if (isStaff && staffAlive > 0 && staffAlive >= townAlive - 1) {
      tips.add(const SituationTip(
        type: TipType.opportunity,
        text: 'You are approaching PARITY. One more Party Animal down and you WIN. Play it safe and let the vote do the work.',
        priority: 0,
      ));
    }

    if (!isStaff && staffAlive > 0 && townAlive <= staffAlive + 2) {
      tips.add(const SituationTip(
        type: TipType.critical,
        text: 'Dealers are close to majority! You MUST exile a Dealer today or the game is over.',
        priority: 0,
      ));
    }
  }
}

/// A single contextual tip with type classification and priority.
class SituationTip {
  final TipType type;
  final String text;

  /// Lower = more urgent. 0 = critical, 1 = high, 2 = medium, 3 = low.
  final int priority;

  const SituationTip({
    required this.type,
    required this.text,
    required this.priority,
  });
}

enum TipType {
  critical,
  warning,
  opportunity,
  strategy,
  deception,
  survival,
}

import 'package:cb_models/cb_models.dart';

/// Context-aware strategy generator for Club Blackout.
/// Analyzes the game state to provide dynamic "What If" and "Alert" tips.
class StrategyGenerator {
  StrategyGenerator._();

  static List<String> generateTips({
    required Role role,
    GameState? state,
    Player? player,
  }) {
    final tips = <String>[];

    // 1. Base Role Tip (Always shown)
    tips.add(_getBaseTip(role.id));

    // 2. Context-Aware Alerts (If game state exists)
    if (state != null) {
      final alive = state.players.where((p) => p.isAlive).toList();
      _addPublicPatternTips(tips: tips, state: state, alive: alive);

      // Roster Checks
      if (role.alliance == Team.clubStaff) {
        if (alive.any((p) => p.role.id == RoleIds.bouncer)) {
          tips.add(
            "⚠️ ALERT: The Bouncer is currently ALIVE. They are hunting you.",
          );
        }
        if (!alive.any((p) => p.role.id == RoleIds.medic)) {
          tips.add(
            "🔥 OPPORTUNITY: The Medic is DEAD. No one can save your targets tonight.",
          );
        }
      } else if (role.alliance == Team.partyAnimals) {
        final staff = alive.where((p) => p.alliance == Team.clubStaff).length;
        if (staff > 2) {
          tips.add(
            "🚨 DANGER: Multiple Dealers are active. Coordinate with your team immediately.",
          );
        }
      }

      // "What If" scenarios
      if (role.id == RoleIds.minor && !alive.any((p) => p.role.id == RoleIds.bouncer)) {
        tips.add(
          "🛡️ WHAT IF I'M ATTACKED? Since the Bouncer is dead, your death protection is virtually unbreakable.",
        );
      }
    }

    // 3. Personal Status (If individual player exists)
    if (player != null) {
      if (player.lives > 1) {
        tips.add(
          "💎 STATUS: You have ${player.lives} lives remaining. Use them as a shield for the team.",
        );
      }
      if (player.silencedDay == state?.dayCount) {
        tips.add(
          "🔇 STATUS: You are currently SILENCED. Communicate through voting only.",
        );
      }
    }

    return tips;
  }

  static void _addPublicPatternTips({
    required List<String> tips,
    required GameState state,
    required List<Player> alive,
  }) {
    if (alive.isEmpty) {
      return;
    }

    if (state.dayVoteTally.isNotEmpty) {
      final sortedVotes = state.dayVoteTally.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final leader = sortedVotes.first;
      final secondVotes = sortedVotes.length > 1 ? sortedVotes[1].value : 0;

      if (leader.value >= 2) {
        tips.add(
          "📊 PATTERN: ${leader.value} public votes are currently stacked on one player. Expect a defense pivot or late counter-push.",
        );
      }

      if (leader.value - secondVotes <= 1 && sortedVotes.length > 1) {
        tips.add(
          "⚖️ PATTERN: The vote is razor-thin. One speech or one swing vote can flip the exile.",
        );
      }
    }

    final votesCast = state.dayVotesByVoter.length;
    final minimumHealthyTurnout = (alive.length * 0.6).ceil();
    if (votesCast > 0 && votesCast < minimumHealthyTurnout) {
      tips.add(
        "🕵️ PATTERN: Vote turnout is low ($votesCast/${alive.length}). Quiet players are controlling information flow.",
      );
    }

    final highDebtAlive = alive.where((p) => p.drinksOwed >= 3).toList();
    if (highDebtAlive.length >= 2) {
      tips.add(
        "🍸 PATTERN: ${highDebtAlive.length} live players are carrying heavy bar tabs. Penalty pressure may distort tomorrow's votes.",
      );
    }

    final deathsThisDay = state.players.where(
      (p) => !p.isAlive && p.deathDay == state.dayCount,
    );
    if (deathsThisDay.length >= 2) {
      tips.add(
        "💀 PATTERN: Multiple casualties hit Day ${state.dayCount}. Expect panic voting and overreactions.",
      );
    }
  }

  static String _getBaseTip(String roleId) {
    return _baseStrategyMap[roleId] ??
        "Survive the night and use your vote wisely during the day.";
  }

  static const Map<String, String> _baseStrategyMap = {
    RoleIds.dealer:
        'Coordination is key. Don\'t eliminate quiet players first—they might be easier to frame during the day.',
    RoleIds.medic:
        'Self-protect on Night 1 if the game feels aggressive. Save your revive for the Bouncer or Wallflower.',
    RoleIds.bouncer:
        'Check the most active talkers first. They are either Dealers trying to lead or special roles you need to confirm.',
    RoleIds.wallflower:
        'Stare and ignore. Your power is in what you see, not what you do. Only reveal when you have a direct witness account.',
    RoleIds.messyBitch:
        'Spread rumours to create smoke screens. If everyone is confused, no one can find the true killers.',
    RoleIds.sober:
        'Send suspected power roles home to keep them safe from murder, or target suspicious players to block their night action.',
    RoleIds.roofi:
        'Roof suspected Dealers to block their kill, or use it on talkative players to silence their defense for the next day.',
    RoleIds.silverFox:
        'Give alibis to your fellow Dealers, or use them on "confirmed" innocents to build trust and blend in.',
    RoleIds.whore:
        'Keep your scapegoat alive. They are your second life. If you feel the heat, ensure they are positioned to take the fall.',
    RoleIds.lightweight:
        'Your name becomes taboo. If people say it, they drink. Use this social pressure to identify those who are paying attention.',
  };
}

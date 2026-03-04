import 'package:cb_models/cb_models.dart';

class VotingAward {
  final String title;
  final String description;
  final String icon; // Emoji or icon name

  const VotingAward({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class VotingAwards {
  static VotingAward getAward(PlayerVotingStats stats) {
    if (stats.totalVotes == 0) {
      return const VotingAward(
        title: 'THE GHOST',
        description: 'You haven\'t voted yet. Are you even playing?',
        icon: '👻',
      );
    }

    final accuracy = stats.dealerVotes / stats.totalVotes;
    final percentage = (accuracy * 100).round();

    if (percentage == 0) {
      return _getZeroPercentAward();
    } else if (percentage <= 20) {
      return _getLowAccuracyAward();
    } else if (percentage <= 40) {
      return _getPoorAccuracyAward();
    } else if (percentage <= 60) {
      return _getMidAccuracyAward();
    } else if (percentage <= 80) {
      return _getHighAccuracyAward();
    } else if (percentage < 100) {
      return _getVeryHighAccuracyAward();
    } else {
      return _getPerfectScoreAward();
    }
  }

  static VotingAward _getZeroPercentAward() {
    final awards = [
      const VotingAward(
          title: 'THE DEALER\'S PET',
          description:
              '0% accuracy. You are effectively on the Dealer\'s payroll.',
          icon: '🐩'),
      const VotingAward(
          title: 'BLIND AS A BAT',
          description: 'You haven\'t found a single Dealer. Open your eyes!',
          icon: '🦇'),
      const VotingAward(
          title: 'USELESS BYSTANDER',
          description: 'You are helping absolutely no one.',
          icon: '🗿'),
      const VotingAward(
          title: 'THE SABOTEUR',
          description:
              'Are you trying to lose? Because you\'re doing a great job at it.',
          icon: '🧨'),
      const VotingAward(
          title: 'DOUBLE AGENT',
          description: 'We see you protecting the bad guys.',
          icon: '🕵️'),
    ];
    return awards[DateTime.now().millisecond % awards.length];
  }

  static VotingAward _getLowAccuracyAward() {
    final awards = [
      const VotingAward(
          title: 'MOSTLY HARMLESS',
          description:
              'You rarely hit the target. The Dealer feels safe around you.',
          icon: '🧸'),
      const VotingAward(
          title: 'STORM TROOPER',
          description: 'A lot of shots, almost no hits.',
          icon: '🔫'),
      const VotingAward(
          title: 'GUESS WORK',
          description: 'You\'re just picking names out of a hat, aren\'t you?',
          icon: '🎩'),
      const VotingAward(
          title: 'THE CONFUSED',
          description: 'You seem lost. Do you need a map?',
          icon: '🗺️'),
      const VotingAward(
          title: 'SORRY ATTEMPT',
          description: 'At least you\'re trying. Barely.',
          icon: '😿'),
    ];
    return awards[DateTime.now().millisecond % awards.length];
  }

  static VotingAward _getPoorAccuracyAward() {
    final awards = [
      const VotingAward(
          title: 'UNLUCKY GUESSER',
          description: 'Statistically, you should be doing better than this.',
          icon: '📉'),
      const VotingAward(
          title: 'THE DISTRACTION',
          description: 'You\'re making a lot of noise but catching no one.',
          icon: '📢'),
      const VotingAward(
          title: 'ALMOST USEFUL',
          description: 'You occasionally accidentally vote correctly.',
          icon: '🤷'),
      const VotingAward(
          title: 'ROOM TEMPERATURE',
          description: 'Your voting record is lukewarm at best.',
          icon: '🌡️'),
      const VotingAward(
          title: 'PARTICIPATION TROPHY',
          description: 'Thanks for showing up, I guess.',
          icon: '🏆'),
    ];
    return awards[DateTime.now().millisecond % awards.length];
  }

  static VotingAward _getMidAccuracyAward() {
    final awards = [
      const VotingAward(
          title: 'COIN FLIPPER',
          description: 'You\'re right about half the time. Pure chance?',
          icon: '🪙'),
      const VotingAward(
          title: 'MEDIOCRE AT BEST',
          description: 'Not terrible, but definitely not great.',
          icon: '😐'),
      const VotingAward(
          title: 'THE AVERAGE JOE',
          description: 'You exist. You vote. Sometimes it works.',
          icon: '🧔'),
      const VotingAward(
          title: 'ROLL OF THE DICE',
          description: 'Your strategy is basically random chaos.',
          icon: '🎲'),
      const VotingAward(
          title: 'FENCE SITTER',
          description: 'You can\'t seem to decide which side you\'re on.',
          icon: '🚧'),
    ];
    return awards[DateTime.now().millisecond % awards.length];
  }

  static VotingAward _getHighAccuracyAward() {
    final awards = [
      const VotingAward(
          title: 'DECENT DETECTIVE',
          description: 'You actually know what you\'re doing. Surprisingly.',
          icon: '🔎'),
      const VotingAward(
          title: 'THE SNIFFER',
          description: 'You can smell a rat. Most of the time.',
          icon: '👃'),
      const VotingAward(
          title: 'SHARP EYE',
          description: 'You\'re catching on. The Dealer is sweating.',
          icon: '👁️'),
      const VotingAward(
          title: 'ACTUALLY HELPFUL',
          description: 'Wow, you\'re contributing! Keep it up.',
          icon: '👏'),
      const VotingAward(
          title: 'THE THREAT',
          description: 'The bad guys should be worried about you.',
          icon: '⚠️'),
    ];
    return awards[DateTime.now().millisecond % awards.length];
  }

  static VotingAward _getVeryHighAccuracyAward() {
    final awards = [
      const VotingAward(
          title: 'SHARP SHOOTER',
          description: 'You rarely miss. Are you cheating?',
          icon: '🎯'),
      const VotingAward(
          title: 'THE INQUISITOR',
          description: 'No one escapes your judgment.',
          icon: '⚖️'),
      const VotingAward(
          title: 'DEALER\'S NIGHTMARE',
          description: 'You are the reason they can\'t sleep at night.',
          icon: '😱'),
      const VotingAward(
          title: 'PROFILER',
          description: 'You can read them like a book.',
          icon: '📖'),
      const VotingAward(
          title: 'THE EXECUTIONER',
          description: 'When you vote, people die. Usually the right ones.',
          icon: '🪓'),
    ];
    return awards[DateTime.now().millisecond % awards.length];
  }

  static VotingAward _getPerfectScoreAward() {
    final awards = [
      const VotingAward(
          title: 'WITCH HUNTER',
          description: '100% Accuracy. You don\'t miss.',
          icon: '🧙‍♀️'),
      const VotingAward(
          title: 'THE ORACLE',
          description: 'Do you see the future? Or just the code?',
          icon: '🔮'),
      const VotingAward(
          title: 'GOD MODE',
          description: 'Okay, who gave you the script?',
          icon: '⚡'),
      const VotingAward(
          title: 'PERFECT RECORD',
          description: 'Flawless victory. You are terrifying.',
          icon: '💯'),
      const VotingAward(
          title: 'THE TERMINATOR',
          description: 'You are a machine designed to destroy Dealers.',
          icon: '🤖'),
    ];
    return awards[DateTime.now().millisecond % awards.length];
  }
}

import 'dart:math';
import 'package:cb_models/cb_models.dart';

class GameNarrationController {
  GameNarrationController();

  String exportGameLog(GameState state) {
    final buffer = StringBuffer();
    buffer.writeln('=== CLUB BLACKOUT GAME LOG ===');
    buffer.writeln('Date: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Day: ${state.dayCount}');
    buffer.writeln('Phase: ${state.phase.name}');
    buffer.writeln('Players: ${state.players.length}');
    buffer.writeln('');
    buffer.writeln('=== ROSTER ===');
    for (final player in state.players) {
      buffer.writeln(
        '${player.name} - ${player.role.name} (${player.alliance.name}) - ${player.isAlive ? "Alive" : "Dead"}',
      );
    }
    buffer.writeln('');
    buffer.writeln('=== GAME HISTORY ===');
    for (final event in state.gameHistory) {
      buffer.writeln(event);
    }
    if (state.winner != null) {
      buffer.writeln('');
      buffer.writeln('=== WINNER ===');
      buffer.writeln(state.winner.toString());
    }
    return buffer.toString();
  }

  Future<String?> generateDynamicNightNarration(
    GameState state, {
    String? personalityId,
    String? voice,
    String? variationPrompt,
    bool forHostOnly = false,
  }) async {
    if (state.lastNightReport.isEmpty) {
      return null;
    }

    final random = Random();
    
    // R-rated, ironic, self-deprecating club-themed recaps
    final recaps = [
      "Alright you degenerates, listen up. While you were all making terrible life choices and spilling overpriced drinks, some actual shit went down. Here's exactly how badly you fucked up last night:\n\n{REPORT}\n\nCan we try to act like adults with functioning prefrontal cortexes tonight? Probably not, but a host can dream.",
      "Look, I don't get paid enough to babysit a bunch of messy club rats, but here we are. While you were busy dry-humping in the VIP section, the real monsters were at work. Check out this trainwreck:\n\n{REPORT}\n\nIf you could stop dying and making my shift harder, that'd be fantastic.",
      "God, you people are exhausting. I swear, running this club is like managing a daycare for sociopaths. Anyway, the carnage from last night's 'festivities' is in. Try to look surprised:\n\n{REPORT}\n\nNow wipe the glitter and blood off your faces and figure out who did this before I just kick you all out.",
      "Another night of bad decisions, worse pickups, and absolute chaos. Honestly, I expected nothing less from this crowd. Here's the damage report from your little nocturnal escapades:\n\n{REPORT}\n\nDo me a favor and aim for slightly less catastrophic failure tonight, yeah?",
      "Welcome back, survivors. Those of you who didn't end up face-down in a puddle of regrets and cheap vodka, anyway. Here is exactly what happened while you were all blacked out:\n\n{REPORT}\n\nTry to use whatever remaining brain cells you have to piece this together.",
      "I asked for one quiet night. Just one. Instead, you absolute clowns treated my club like a purge scenario. Let’s review the highlights reel of your collective failure:\n\n{REPORT}\n\nI’m docking all of this from someone’s tab.",
      "Half of you look absolutely wrecked, and the other half smell like cheap cologne and bad alibis. Here's what you missed while you were busy lowering your standards:\n\n{REPORT}\n\nPlease try not to completely destroy the venue by sunrise.",
      "Before we open the bar again, we need to address the elephant in the room—or rather, the bodies in the alley. Here’s the recap of your utterly feral behavior last night:\n\n{REPORT}\n\nI'm seriously considering turning this place into a f***ing escape room.",
      "Some people come to clubs to dance. You people apparently come to plot elaborate, poorly executed homicides. The resulting collateral damage looks like this:\n\n{REPORT}\n\nI’ve seen bachelorette parties with more tactical coordination. Get it together.",
      "Grab a Gatorade and pop some ibuprofen, because you're gonna need it. Here is the utterly depressing list of consequences from last night:\n\n{REPORT}\n\nAt this point, I'm just impressed the entire building isn't on fire."
    ];
    
    final selectedRecap = recaps[random.nextInt(recaps.length)];
    final formattedReport = state.lastNightReport.map((e) => "• $e").join('\n');
    
    return selectedRecap.replaceAll('{REPORT}', formattedReport);
  }

  Future<String?> generateCurrentStepNarrationVariation(
    GameState state, {
    String? personalityId,
  }) async {
    final step = state.currentStep;
    if (step == null || step.readAloudText.trim().isEmpty) {
      return null;
    }

    final random = Random();
    
    // Spicy, snarky club phrases to prepend/append to the action
    final prefixes = [
      "Alright listen up, you messy fucks. ",
      "Can I get some goddamn silence? ",
      "Put the cheap drinks down and pay attention. ",
      "I swear to god if you don't listen to this... ",
      "Try to focus your drunken little minds for a second. ",
      "Look up from your phones, idiots. ",
      "I'm only saying this once because I'm hungover. ",
      "Stop flirting with the bartender for ten seconds. ",
      "Eyes front, VIP section. ",
      "Try to pretend you have a working attention span. "
    ];
    
    final suffixes = [
      "\n\nDon't fuck this up.",
      "\n\nNow hurry up, I want to go home.",
      "\n\nMake it quick before someone throws up on my shoes.",
      "\n\nAnd let's try to act like we have some class, okay? Just kidding.",
      "\n\nDo your thing, you absolute disaster of a human.",
      "\n\nTry not to embarrass yourselves more than usual.",
      "\n\nI expect nothing from you and I know I'll still be disappointed.",
      "\n\nJust push the goddamn buttons so we can move on.",
      "\n\nDon't overthink it, you're not equipped for that.",
      "\n\nWhatever you choose is probably wrong anyway."
    ];

    final prefix = prefixes[random.nextInt(prefixes.length)];
    final suffix = suffixes[random.nextInt(suffixes.length)];

    return "$prefix${step.readAloudText}$suffix";
  }
}

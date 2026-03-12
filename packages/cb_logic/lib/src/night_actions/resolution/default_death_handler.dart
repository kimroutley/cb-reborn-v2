import 'package:cb_models/cb_models.dart';
import 'death_handler.dart';
import '../night_resolution_context.dart';

class DefaultDeathHandler implements DeathHandler {
  @override
  bool handle(NightResolutionContext context, Player victim) {
    final reason = context.killSources[victim.id] ?? 'murder';
    var reportMsg = 'The Dealers caught up with ${victim.name} in the alleyway. Let\'s just say it was a closed-casket kind of night.';
    var teaserMsg = 'A severely questionable scene was found out back. ${victim.name} won\'t be joining us tonight.';

    // GOD MODE: Host Shield overrides regular kills
    if (victim.hasHostShield && victim.hostShieldExpiresDay != null && victim.hostShieldExpiresDay! > context.dayCount) {
      context.addReport('Management stepped in and completely vetoed a hit tonight. Plot armor is a real thing.');
      context.addTeaser('A patron survived a very sketchy encounter thanks to the house.');
      return true; // Handled, survived
    }

    if (reason == 'attack_dog') {
      reportMsg = 'Something rabid tore ${victim.name} apart by the dumpsters.';
      teaserMsg = 'Someone forgot to feed the dog, and ${victim.name} paid the ultimate price.';
    } else if (reason == 'messy_bitch') {
      reportMsg = 'A petty vendetta escalated way too far. ${victim.name} got caught in the literal crossfire.';
      teaserMsg = 'Someone settled a score with extreme prejudice. RIP ${victim.name}.';
    }

    context.updatePlayer(victim.copyWith(
      isAlive: false,
      deathDay: context.dayCount,
      deathReason: reason,
    ));
    context.report.add(reportMsg);
    context.teasers.add(teaserMsg);

    context.events.add(GameEvent.death(
      playerId: victim.id,
      reason: reason,
      day: context.dayCount,
    ));

    // Attribute kills to specific dealers
    for (final entry in context.dealerAttacks.entries) {
      if (entry.value == victim.id) {
        context.events.add(GameEvent.kill(
          killerId: entry.key,
          victimId: victim.id,
          day: context.dayCount,
        ));
      }
    }
    return true; // Handled
  }
}

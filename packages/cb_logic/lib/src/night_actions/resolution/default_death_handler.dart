import 'package:cb_models/cb_models.dart';
import 'death_handler.dart';
import '../night_resolution_context.dart';

class DefaultDeathHandler implements DeathHandler {
  @override
  bool handle(NightResolutionContext context, Player victim) {
    final reason = context.killSources[victim.id] ?? 'murder';
    var reportMsg = 'The Dealers butchered ${victim.name} in cold blood.';
    var teaserMsg = 'A messy scene was found. ${victim.name} didn\'t make it.';

    if (reason == 'attack_dog') {
      reportMsg = 'A snarling beast tore ${victim.name} apart.';
      teaserMsg = 'Animal control was called, but too late.';
    } else if (reason == 'messy_bitch') {
      reportMsg = 'A petty vendetta ended ${victim.name}\'s night permanently.';
      teaserMsg = 'Someone settled the score with extreme prejudice.';
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

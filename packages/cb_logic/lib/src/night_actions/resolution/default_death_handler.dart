import 'package:cb_models/cb_models.dart';
import 'death_handler.dart';
import '../night_resolution_context.dart';

class DefaultDeathHandler implements DeathHandler {
  @override
  bool handle(NightResolutionContext context, Player victim) {
    context.updatePlayer(victim.copyWith(
      isAlive: false,
      deathDay: context.dayCount,
      deathReason: 'murder',
    ));
    context.report.add('The Dealers butchered ${victim.name} in cold blood.');
    context.teasers.add('A messy scene was found. ${victim.name} didn\'t make it.');
    return true; // Handled
  }
}

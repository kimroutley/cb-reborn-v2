import 'package:cb_models/cb_models.dart';
import 'death_handler.dart';
import '../night_resolution_context.dart';

class SeasonedDrinkerHandler implements DeathHandler {
  @override
  bool handle(NightResolutionContext context, Player victim) {
    final targetedByDealer = context.dealerAttacks.values.contains(victim.id);

    if (victim.role.id == RoleIds.seasonedDrinker &&
        victim.lives > 1 &&
        targetedByDealer) {
      context.updatePlayer(victim.copyWith(lives: victim.lives - 1));
      context.addPrivateMessage(victim.id,
          'That was a heavy hit, but you\'re still standing. You have ${victim.lives - 1} lives remaining.');
      context.report
          .add('Seasoned Drinker ${victim.name} lost a life but survived.');
      context.teasers.add('A seasoned patron took a hit but kept going.');
      return true; // Prevent default death
    }
    return false;
  }
}

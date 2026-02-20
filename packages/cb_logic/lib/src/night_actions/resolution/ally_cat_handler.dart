import 'package:cb_models/cb_models.dart';
import 'death_handler.dart';
import '../night_resolution_context.dart';

class AllyCatHandler implements DeathHandler {
  @override
  bool handle(NightResolutionContext context, Player victim) {
    if (victim.role.id == RoleIds.allyCat && victim.lives > 1) {
      context.updatePlayer(victim.copyWith(lives: victim.lives - 1));
      context.report
          .add('Ally Cat ${victim.name} lost a life but landed on their feet.');
      context.teasers.add('A cat-like figure escaped by a whisker.');
      return true; // Prevent default death
    }
    return false;
  }
}

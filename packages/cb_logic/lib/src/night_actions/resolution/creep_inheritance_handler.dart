import 'package:cb_models/cb_models.dart';
import 'death_handler.dart';
import '../night_resolution_context.dart';

class CreepInheritanceHandler implements DeathHandler {
  @override
  bool handle(NightResolutionContext context, Player victim) {
    final creeps = context.players.where((p) =>
        p.isAlive &&
        p.role.id == RoleIds.creep &&
        p.creepTargetId == victim.id);

    for (final creep in creeps) {
      context.updatePlayer(
        creep.copyWith(
          role: victim.role,
          alliance: victim.alliance,
          creepTargetId: null,
        ),
      );
      context.report.add(
          'The Creep ${creep.name} inherited the role of ${victim.role.name}.');
      // If inherited role requires setup, queue it so the Creep gets the step on their device
      final roleId = victim.role.id;
      if (roleId == RoleIds.medic ||
          roleId == RoleIds.clinger ||
          roleId == RoleIds.dramaQueen) {
        context.addPendingCreepSetup(creep.id, roleId);
      }
    }

    return false; // Let other handlers continue processing the victim death.
  }
}

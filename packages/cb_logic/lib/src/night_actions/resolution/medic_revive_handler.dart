import 'package:cb_models/cb_models.dart';
import 'death_handler.dart';
import '../night_resolution_context.dart';

class MedicReviveHandler implements DeathHandler {
  @override
  bool handle(NightResolutionContext context, Player victim) {
    // Find any medic who chose to revive this specific victim
    final medics = context.players.where((p) =>
        p.isAlive && p.role.id == RoleIds.medic && p.medicChoice == 'REVIVE');

    for (final medic in medics) {
      final actionKey = 'medic_act_${medic.id}_${context.dayCount}';
      final targetId = context.log[actionKey];

      if (targetId == victim.id) {
        // Successful revive!
        context.updatePlayer(medic.copyWith(hasReviveToken: false));
        context.report.add('${medic.name} used their one-time revival on ${victim.name}.');
        context.teasers.add('A miracle occurred! Someone returned from the brink.');
        
        // Return true to signify the death was handled (prevented)
        return true;
      }
    }

    return false;
  }
}

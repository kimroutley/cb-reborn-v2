import 'package:cb_models/cb_models.dart';
import '../night_action.dart';
import '../night_resolution_context.dart';

class MedicAction extends NightAction {
  @override
  ActionPhase get phase => ActionPhase.protection;

  @override
  void execute(NightResolutionContext context) {
    for (final p in context.players.where((p) => p.isAlive && p.role.id == RoleIds.medic)) {
      if (context.blockedIds.contains(p.id)) continue;

      final targetId = getTargetId(context, p.id, 'medic');
      // Only protect if chosen 'PROTECT_DAILY'
      if (targetId != null && p.medicChoice == 'PROTECT_DAILY') {
        context.protectedIds.add(targetId);
      }
    }
  }
}

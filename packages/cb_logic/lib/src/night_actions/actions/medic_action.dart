import 'package:cb_models/cb_models.dart';
import '../../scripting/step_key.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class MedicAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.medic;

  @override
  void execute(NightResolutionContext context) {
    final medics =
        context.players.where((p) => p.isAlive && p.role.id == roleId);

    for (final medic in medics) {
      if (context.redirectedActions.containsKey(medic.id) ||
          context.silencedPlayerIds.contains(medic.id)) {
        continue;
      }

      // Revive logic is handled in DeathResolutionStrategy
      if (medic.medicChoice == 'REVIVE') {
        continue;
      }

      final actionKey = StepKey.roleAction(
        roleId: roleId,
        playerId: medic.id,
        dayCount: context.dayCount,
      );
      final targetId = context.log[actionKey];

      if (targetId != null) {
        final target = context.getPlayer(targetId);
        context.protectedPlayerIds.add(targetId);
        context.addPrivateMessage(medic.id, 'You healed ${target.name}.');
        context.addReport('Medic protected ${target.name}.');
      }
    }
  }
}

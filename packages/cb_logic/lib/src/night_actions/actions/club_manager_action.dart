import 'package:cb_models/cb_models.dart';
import '../../scripting/step_key.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class ClubManagerAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.clubManager;

  @override
  void execute(NightResolutionContext context) {
    final managers =
        context.players.where((p) => p.isAlive && p.role.id == roleId);

    for (final manager in managers) {
      if (context.redirectedActions.containsKey(manager.id) ||
          context.silencedPlayerIds.contains(manager.id)) {
        continue;
      }

      final actionKey = StepKey.roleAction(
        roleId: roleId,
        playerId: manager.id,
        dayCount: context.dayCount,
      );
      final targetId = context.log[actionKey];
      if (targetId == null) {
        continue;
      }

      final target = context.getPlayer(targetId);
      context.addPrivateMessage(
          manager.id, 'Inspection complete: ${target.name} is the ${target.role.name}.');
      context.addReport('Club Manager chose to inspect ${target.name}.');
      context.updatePlayer(target.copyWith(sightedByClubManager: true));
    }
  }
}

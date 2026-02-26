import 'package:cb_models/cb_models.dart';
import '../../scripting/step_key.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class LightweightAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.lightweight;

  @override
  void execute(NightResolutionContext context) {
    final lightweights =
        context.players.where((p) => p.isAlive && p.role.id == roleId);

    for (final lightweight in lightweights) {
      if (context.redirectedActions.containsKey(lightweight.id) ||
          context.silencedPlayerIds.contains(lightweight.id)) {
        continue;
      }

      final actionKey = StepKey.roleAction(
        roleId: roleId,
        playerId: lightweight.id,
        dayCount: context.dayCount,
      );
      final targetId = context.log[actionKey];

      if (targetId != null) {
        final target = context.getPlayer(targetId);

        if (!lightweight.blockedVoteTargets.contains(targetId)) {
          context.updatePlayer(
            lightweight.copyWith(
              blockedVoteTargets: [
                ...lightweight.blockedVoteTargets,
                targetId,
              ],
            ),
          );
        }

        context.addPrivateMessage(
            lightweight.id, '${target.name} is now off your ballot. You cannot vote for them.');
        context.addReport('Lightweight chose to forbid voting for ${target.name}.');
        context.addTeaser('Someone lost a voting option...');
      }
    }
  }
}

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

        // Update ONLY the Lightweight player's blocked list
        context.updatePlayer(
          lightweight.copyWith(
            blockedVoteTargets: [...lightweight.blockedVoteTargets, targetId],
          ),
        );

        context.addPrivateMessage(
            lightweight.id, 'You can no longer vote for ${target.name}.');
        context.addReport('LW blocked vote target: ${target.name}.');
        context.addTeaser('Lightweight lost a voting option.');
      }
    }
  }
}

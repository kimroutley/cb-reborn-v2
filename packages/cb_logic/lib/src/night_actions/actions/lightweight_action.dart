import 'package:cb_models/cb_models.dart';
import '../../scripting/step_key.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class LightweightAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.lightweight;

  @override
  void execute(NightResolutionContext context) {
    final lightweights = context.players.where(
      (p) => p.isAlive && p.role.id == roleId,
    );

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
        final tabooName = target.name;

        for (final player in context.players.where((p) => p.isAlive)) {
          if (player.tabooNames.contains(tabooName)) {
            continue;
          }

          context.updatePlayer(
            player.copyWith(tabooNames: [...player.tabooNames, tabooName]),
          );
        }

        context.addPrivateMessage(
          lightweight.id,
          'You banned ${target.name}\'s name.',
        );
        context.addReport('LW banned ${target.name}\'s name.');
        context.addTeaser('A name is now FORBIDDEN.');
      }
    }
  }
}

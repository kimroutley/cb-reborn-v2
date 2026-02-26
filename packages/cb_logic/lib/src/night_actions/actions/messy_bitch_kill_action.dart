import 'package:cb_models/cb_models.dart';
import '../../scripting/step_key.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class MessyBitchKillAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.messyBitch;

  @override
  void execute(NightResolutionContext context) {
    final messyBitches =
        context.players.where((p) => p.isAlive && p.role.id == roleId);

    for (final bitch in messyBitches) {
      if (context.redirectedActions.containsKey(bitch.id) ||
          context.silencedPlayerIds.contains(bitch.id) ||
          bitch.messyBitchKillUsed) {
        continue;
      }

      final actionKey = StepKey.roleVerbAction(
        roleId: roleId,
        verb: 'kill',
        playerId: bitch.id,
        dayCount: context.dayCount,
      );
      final targetId = context.log[actionKey];

      if (targetId != null) {
        final target = context.getPlayer(targetId);
        context.killedPlayerIds.add(targetId);
        context.killSources[targetId] = 'messy_bitch';
        context.addPrivateMessage(
            bitch.id, '${target.name} has been eliminated. Your one-time kill is spent.');
        context.addTeaser('Score settled.');
        context.addReport('Messy Bitch chose to kill ${target.name}.');
        context.updatePlayer(bitch.copyWith(messyBitchKillUsed: true));
      }
    }
  }
}

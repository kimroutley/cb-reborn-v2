import 'package:cb_models/cb_models.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class BouncerAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.bouncer;

  @override
  void execute(NightResolutionContext context) {
    final bouncers =
        context.players.where((p) => p.isAlive && p.role.id == roleId);

    for (final bouncer in bouncers) {
      if (context.redirectedActions.containsKey(bouncer.id) ||
          context.silencedPlayerIds.contains(bouncer.id)) {
        continue;
      }

      final actionKey = '${roleId}_act_${bouncer.id}_${context.dayCount}';
      final targetId = context.log[actionKey];
      if (targetId == null) {
        continue;
      }

      final target = context.getPlayer(targetId);
      final isStaff = target.alliance == Team.clubStaff;

      final msg = '${target.name} is ${isStaff ? "STAFF" : "PARTY ANIMAL"}.';
      context.addPrivateMessage(bouncer.id, msg);
      context.addReport('Bouncer checked ${target.name}.');
    }
  }
}

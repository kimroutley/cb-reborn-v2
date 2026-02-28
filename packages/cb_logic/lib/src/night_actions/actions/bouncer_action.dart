import 'package:cb_models/cb_models.dart';
import '../../scripting/step_key.dart';
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

      final actionKey = StepKey.roleAction(
        roleId: roleId,
        playerId: bouncer.id,
        dayCount: context.dayCount,
      );
      final targetId = context.log[actionKey];
      if (targetId == null) {
        continue;
      }

      final target = context.getPlayer(targetId);
      final isStaff = target.alliance == Team.clubStaff;

      if (target.role.id == RoleIds.minor && !target.minorHasBeenIDd) {
        context.updatePlayer(target.copyWith(minorHasBeenIDd: true));
      }

      final allegiance = isStaff ? 'STAFF' : 'PARTY ANIMAL';
      context.addPrivateMessage(
          bouncer.id, 'Intel report: ${target.name} is $allegiance.');

      final allyCats = context.players.where(
        (p) => p.isAlive && p.role.id == RoleIds.allyCat,
      );
      for (final allyCat in allyCats) {
        context.addPrivateMessage(
          allyCat.id,
          'Ally Cat witnessed Bouncer check ${target.name}: $allegiance.',
        );
      }

      context.addReport('Bouncer checked ${target.name}.');
    }
  }
}

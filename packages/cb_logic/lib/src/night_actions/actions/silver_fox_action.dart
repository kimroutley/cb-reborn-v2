import 'package:cb_models/cb_models.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class SilverFoxAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.silverFox;

  @override
  void execute(NightResolutionContext context) {
    final silverFoxes =
        context.players.where((p) => p.isAlive && p.role.id == roleId);

    for (final fox in silverFoxes) {
      if (context.redirectedActions.containsKey(fox.id) ||
          context.silencedPlayerIds.contains(fox.id)) {
        continue;
      }

      final actionKey =
          '${roleId}_act_${fox.id}_${context.dayCount}';
      final targetId = context.log[actionKey];

      if (targetId != null) {
        final target = context.getPlayer(targetId);
        context.updatePlayer(target.copyWith(alibiDay: context.dayCount));
        context.addPrivateMessage(fox.id, 'Alibi provided for ${target.name}.');
        context.addReport('Fox shielded ${target.name}.');
        context.addTeaser('${target.name} has an alibi.');
      }
    }
  }
}

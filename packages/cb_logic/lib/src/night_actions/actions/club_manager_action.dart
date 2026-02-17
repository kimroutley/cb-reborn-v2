import 'package:cb_models/cb_models.dart';
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

      final actionKey = '${roleId}_act_${manager.id}_${context.dayCount}';
      final targetId = context.log[actionKey];
      if (targetId == null) {
        continue;
      }

      final target = context.getPlayer(targetId);
      context.addPrivateMessage(
          manager.id, '${target.name} is ${target.role.name}.');
      context.addReport('Manager file-checked ${target.name}.');
      context.updatePlayer(target.copyWith(sightedByClubManager: true));
    }
  }
}

import 'package:cb_models/cb_models.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class DealerAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.dealer;

  @override
  void execute(NightResolutionContext context) {
    final dealers =
        context.players.where((p) => p.isAlive && p.role.id == roleId);

    for (final dealer in dealers) {
      if (context.redirectedActions.containsKey(dealer.id) ||
          context.silencedPlayerIds.contains(dealer.id)) {
        continue;
      }

      final actionKey = '${roleId}_act_${dealer.id}_${context.dayCount}';
      final targetId = context.log[actionKey];

      if (targetId != null) {
        context.killedPlayerIds.add(targetId);
        context.dealerAttacks[dealer.id] = targetId;
        context.addReport(
            '${dealer.name} made a move on ${context.getPlayer(targetId).name}.');
      }
    }
  }
}

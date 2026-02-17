import 'package:cb_models/cb_models.dart';
import '../../scripting/step_key.dart';
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

      final actionKey = StepKey.roleAction(
        roleId: roleId,
        playerId: dealer.id,
        dayCount: context.dayCount,
      );
      final targetId = context.log[actionKey];

      if (targetId != null) {
        final target = context.getPlayer(targetId);
        context.killedPlayerIds.add(targetId);
        context.dealerAttacks[dealer.id] = targetId;
        context.addPrivateMessage(dealer.id, 'Target acquired.');

        context.addReport('Dealer target: ${target.name}.');
      }
    }
  }
}

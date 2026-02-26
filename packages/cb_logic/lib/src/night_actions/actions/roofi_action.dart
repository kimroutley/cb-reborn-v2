import 'package:cb_models/cb_models.dart';
import '../../scripting/step_key.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class RoofiAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.roofi;

  @override
  void execute(NightResolutionContext context) {
    final roofis = context.players.where(
      (p) => p.isAlive && p.role.id == roleId,
    );

    for (final roofi in roofis) {
      // Pre-emptive actions cannot be blocked or redirected in the same night
      final actionKey = StepKey.roleAction(
        roleId: roleId,
        playerId: roofi.id,
        dayCount: context.dayCount,
      );
      final targetId = context.log[actionKey];

      if (targetId != null) {
        final target = context.getPlayer(targetId);
        context.silencedPlayerIds.add(targetId);

        // Special rule: if Roofi targets the only living Dealer,
        // the Dealer kill is blocked for this night.
        final livingDealers = context.players
            .where((p) => p.isAlive && p.role.id == RoleIds.dealer)
            .toList();
        if (target.role.id == RoleIds.dealer &&
            livingDealers.length == 1 &&
            livingDealers.first.id == targetId) {
          final blockedVictimId = context.dealerAttacks[targetId];
          if (blockedVictimId != null) {
            context.dealerAttacks.remove(targetId);
            if (!context.dealerAttacks.values.contains(blockedVictimId)) {
              context.killedPlayerIds.remove(blockedVictimId);
            }
            final blockedVictim = context.getPlayer(blockedVictimId);
            context.addReport(
              'Roofi blocked ${target.name}\'s kill on ${blockedVictim.name}.',
            );
          }
        }

        context.addPrivateMessage(roofi.id, 'You silenced ${target.name}.');
        context.addReport('Roofi silenced ${target.name}.');
      }
    }
  }
}

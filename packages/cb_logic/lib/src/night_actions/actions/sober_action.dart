import 'package:cb_models/cb_models.dart';
import '../../scripting/step_key.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class SoberAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.sober;

  @override
  void execute(NightResolutionContext context) {
    final sobers =
        context.players.where((p) => p.isAlive && p.role.id == roleId);

    for (final sober in sobers) {
      // Pre-emptive actions cannot be blocked or redirected in the same night
      final actionKey = StepKey.roleAction(
        roleId: roleId,
        playerId: sober.id,
        dayCount: context.dayCount,
      );
      final targetId = context.log[actionKey];

      if (targetId != null) {
        // Sober both blocks and protects
        context.redirectedActions[targetId] = 'none';
        context.protectedPlayerIds.add(targetId);

        final target = context.getPlayer(targetId);
        context.addPrivateMessage(
            sober.id, 'You blocked ${target.name}. Their night action has been neutralised.');
        context.addReport('Sober chose to block ${target.name}.');
      }
    }
  }
}

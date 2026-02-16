import 'package:cb_models/cb_models.dart';
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

      final actionKey =
          '${RoleIds.messyBitch}_kill_${bitch.id}_${context.dayCount}';
      final targetId = context.log[actionKey];

      if (targetId != null) {
        context.killedPlayerIds.add(targetId);
        context.addReport('The Messy Bitch decided to settle a score tonight.');
        context.updatePlayer(bitch.copyWith(messyBitchKillUsed: true));
      }
    }
  }
}

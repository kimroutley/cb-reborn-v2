import 'package:cb_models/cb_models.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class WhoreAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.whore;

  @override
  void execute(NightResolutionContext context) {
    final whores =
        context.players.where((p) => p.isAlive && p.role.id == roleId);

    for (final whore in whores) {
      if (context.redirectedActions.containsKey(whore.id) ||
          context.silencedPlayerIds.contains(whore.id)) {
        continue;
      }

      // Whore's deflection target is set during the night,
      // but the deflection itself is resolved during the day vote.
      // Here, we just record their choice.
      final actionKey =
          '${roleId}_act_${whore.id}_${context.dayCount}';
      final targetId = context.log[actionKey];

      if (targetId != null && targetId != whore.id) {
        final target = context.getPlayer(targetId);
        context.updatePlayer(whore.copyWith(whoreDeflectionTargetId: targetId));
        context.addPrivateMessage(whore.id, 'Scapegoat set: ${target.name}.');
        context.addReport('Whore set scapegoat: ${target.name}.');
      }
    }
  }
}

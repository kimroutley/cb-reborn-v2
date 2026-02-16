import 'package:cb_models/cb_models.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class RoofiAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.roofi;

  @override
  void execute(NightResolutionContext context) {
    final roofis =
        context.players.where((p) => p.isAlive && p.role.id == roleId);

    for (final roofi in roofis) {
      // Pre-emptive actions cannot be blocked or redirected in the same night
      final actionKey =
          '${roleId}_act_${roofi.id}_${context.dayCount}';
      final targetId = context.log[actionKey];

      if (targetId != null) {
        context.silencedPlayerIds.add(targetId);
        context.addReport('${roofi.name} silenced ${context.getPlayer(targetId).name}.');
        context.addTeaser('${context.getPlayer(targetId).name} looks a bit dazed.');
      }
    }
  }
}

import 'package:cb_models/cb_models.dart';
import '../../scripting/step_key.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class BartenderAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.bartender;

  @override
  void execute(NightResolutionContext context) {
    final bartenders =
        context.players.where((p) => p.isAlive && p.role.id == roleId);

    for (final bartender in bartenders) {
      if (context.redirectedActions.containsKey(bartender.id) ||
          context.silencedPlayerIds.contains(bartender.id)) {
        continue;
      }

      final actionKey = StepKey.roleAction(
        roleId: roleId,
        playerId: bartender.id,
        dayCount: context.dayCount,
      );
      final selection = context.log[actionKey];
      if (selection == null || !selection.contains(',')) {
        continue;
      }

      final ids = selection
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (ids.length < 2) {
        continue;
      }

      final first = context.getPlayer(ids[0]);
      final second = context.getPlayer(ids[1]);
      final isAligned = first.alliance == second.alliance;
      final msg = isAligned
          ? '${first.name} and ${second.name} are on the SAME side.'
          : '${first.name} and ${second.name} are on DIFFERENT sides.';
      context.addPrivateMessage(bartender.id, msg);
      context.addReport('Bartender chose to compare ${first.name} & ${second.name}.');
    }
  }
}

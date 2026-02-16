import '../night_action_strategy.dart';
import '../night_resolution_context.dart';
import 'death_handler.dart';
import 'second_wind_handler.dart';
import 'seasoned_drinker_handler.dart';
import 'medic_revive_handler.dart';
import 'clinger_bond_handler.dart';
import 'default_death_handler.dart';

class DeathResolutionStrategy implements NightActionStrategy {
  final List<DeathHandler> _handlers;

  @override
  String get roleId => '__death_resolution__';

  DeathResolutionStrategy([List<DeathHandler>? handlers])
      : _handlers = handlers ??
            [
              MedicReviveHandler(),
              SecondWindHandler(),
              SeasonedDrinkerHandler(),
              ClingerBondHandler(),
              DefaultDeathHandler(),
            ];

  @override
  void execute(NightResolutionContext context) {
    final resolvedIds = <String>{};

    // Continue as long as there are pending deaths not yet resolved
    while (context.killedPlayerIds.length > resolvedIds.length) {
      final targetId = context.killedPlayerIds
          .firstWhere((id) => !resolvedIds.contains(id));
      resolvedIds.add(targetId);

      if (context.protectedPlayerIds.contains(targetId)) {
        final victim = context.getPlayer(targetId);
        context.addReport('A murder attempt on ${victim.name} was thwarted.');
        context.addTeaser(
            'A patron barely escaped a close encounter with "the staff".');
        continue;
      }

      final victim = context.getPlayer(targetId);

      for (final handler in _handlers) {
        if (handler.handle(context, victim)) {
          break; // Stop after first successful handler
        }
      }
    }
  }
}

import 'package:cb_models/cb_models.dart';
import '../night_resolution_context.dart';
import 'death_handler.dart';
import 'second_wind_handler.dart';
import 'seasoned_drinker_handler.dart';
import 'default_death_handler.dart';

class DeathResolutionStrategy {
  final List<DeathHandler> _handlers;

  DeathResolutionStrategy([List<DeathHandler>? handlers])
      : _handlers = handlers ?? [
          SecondWindHandler(),
          SeasonedDrinkerHandler(),
          DefaultDeathHandler(),
        ];

  void execute(NightResolutionContext context) {
    for (final targetId in context.murderTargets) {
      if (context.protectedIds.contains(targetId)) {
        final victim = context.getPlayer(targetId);
        context.report.add('A murder attempt on ${victim.name} was thwarted.');
        context.teasers.add('A patron barely escaped a close encounter with "the staff".');
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

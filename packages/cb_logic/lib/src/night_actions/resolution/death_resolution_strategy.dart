import 'package:cb_models/cb_models.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';
import 'death_handler.dart';
import 'second_wind_handler.dart';
import 'seasoned_drinker_handler.dart';
import 'ally_cat_handler.dart';
import 'minor_protection_handler.dart';
import 'medic_revive_handler.dart';
import 'clinger_bond_handler.dart';
import 'creep_inheritance_handler.dart';
import 'drama_queen_death_handler.dart';
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
              AllyCatHandler(),
              MinorProtectionHandler(),
              ClingerBondHandler(),
              CreepInheritanceHandler(),
              DramaQueenDeathHandler(),
              DefaultDeathHandler(),
            ];

  @override
  void execute(NightResolutionContext context) {
    final resolvedIds = <String>{};

    // Continue as long as there are pending deaths not yet resolved
    while (context.killedPlayerIds.length > resolvedIds.length) {
      final targetId =
          context.killedPlayerIds.firstWhere((id) => !resolvedIds.contains(id));
      resolvedIds.add(targetId);

      if (context.protectedPlayerIds.contains(targetId)) {
        final victim = context.getPlayer(targetId);

        // Wallflower is virtually impossible to detect
        if (victim.role.id != RoleIds.wallflower) {
          context.addReport('A murder attempt on ${victim.name} was thwarted.');
          context.addTeaser(
              'A patron barely escaped a close encounter with "the staff".');
        }

        // Notify Medic if their protection was triggered
        final medics = context.players.where((p) =>
            p.isAlive &&
            p.role.id == RoleIds.medic &&
            p.medicChoice != 'REVIVE');

        for (final medic in medics) {
          final actionKey = 'medic_act_${medic.id}_${context.dayCount}';
          final protectedId = context.log[actionKey];
          if (protectedId == targetId) {
            context.addPrivateMessage(medic.id,
                'Your medical expertise was vital tonight. You successfully shielded your patient from a lethal encounter.');
          }
        }
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

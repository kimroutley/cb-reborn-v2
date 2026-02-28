import 'package:cb_models/cb_models.dart';
import 'death_handler.dart';
import '../night_resolution_context.dart';

class ClingerBondHandler implements DeathHandler {
  @override
  bool handle(NightResolutionContext context, Player victim) {
    // If the victim was someone's partner, trigger the bond
    final clingers = context.players.where((p) =>
        p.isAlive &&
        p.role.id == RoleIds.clinger &&
        p.clingerPartnerId == victim.id);

    for (final clinger in clingers) {
      final isDealerMurder = victim.deathReason == 'murder' ||
          context.dealerAttacks.values.contains(victim.id);

      if (isDealerMurder) {
        // Freed as Attack Dog!
        final attackDogRole = roleCatalogMap[RoleIds.attackDog];
        context.updatePlayer(clinger.copyWith(
          role: attackDogRole ?? clinger.role,
          alliance: Team.neutral,
          clingerFreedAsAttackDog: true,
        ));
        context.addPrivateMessage(clinger.id,
            'Your partner has been taken. The leash is off. You are now the Attack Dog.');
        context.report.add(
            '${clinger.name} witnessed the murder of their partner and has snapped! They are now an Attack Dog.');
        context.teasers.add(
            'A witness to last night\'s violence has been transformed by rage.');
      } else {
        // Die of a broken heart
        context.killedPlayerIds.add(clinger.id);
        context.report.add(
            '${clinger.name} could not live without ${victim.name} and died of a broken heart.');
        // Note: Adding to killedPlayerIds will be handled by the next iteration of DeathResolutionStrategy
      }
    }

    return false; // Always return false so DefaultDeathHandler can still run for the victim
  }
}

import 'package:cb_models/cb_models.dart';
import '../night_action_strategy.dart';
import '../night_resolution_context.dart';

class AttackDogAction implements NightActionStrategy {
  @override
  String get roleId => RoleIds.attackDog;

  @override
  void execute(NightResolutionContext context) {
    final attackDogs = context.players.where((p) =>
        p.isAlive &&
        p.role.id == RoleIds.clinger &&
        p.clingerFreedAsAttackDog &&
        !p.clingerAttackDogUsed);

    for (final dog in attackDogs) {
      if (context.redirectedActions.containsKey(dog.id) ||
          context.silencedPlayerIds.contains(dog.id)) {
        continue;
      }

      final actionKey = '${roleId}_act_${dog.id}_${context.dayCount}';
      final targetId = context.log[actionKey];

      if (targetId != null) {
        final target = context.getPlayer(targetId);
        context.killedPlayerIds.add(targetId);
        context.addPrivateMessage(dog.id, 'Dog released on ${target.name}.');
        context.addTeaser('Dog found prey.');
        context.addReport('Dog attacked ${target.name}.');
        context.updatePlayer(dog.copyWith(clingerAttackDogUsed: true));
      }
    }
  }
}

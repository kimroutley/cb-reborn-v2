import 'package:cb_models/cb_models.dart';
import '../../day_actions/resolution/drama_queen_swap.dart';
import '../night_resolution_context.dart';
import 'death_handler.dart';
import 'default_death_handler.dart';

class DramaQueenDeathHandler implements DeathHandler {
  DramaQueenDeathHandler({DefaultDeathHandler? defaultDeathHandler})
      : _defaultDeathHandler = defaultDeathHandler ?? DefaultDeathHandler();

  final DefaultDeathHandler _defaultDeathHandler;

  @override
  bool handle(NightResolutionContext context, Player victim) {
    if (victim.role.id != RoleIds.dramaQueen) {
      return false;
    }

    final handled = _defaultDeathHandler.handle(context, victim);
    if (!handled) {
      return false;
    }

    final updatedVictim = context.getPlayer(victim.id);
    final deathReason = updatedVictim.deathReason;
    if (deathReason == null) {
      return true;
    }

    final resolution = resolveDramaQueenSwaps(
      players: context.players,
      votesByVoter: const {},
      triggeringDeathReasons: {deathReason},
    );

    if (resolution.lines.isNotEmpty) {
      for (final player in resolution.players) {
        context.updatePlayer(player);
      }
      for (final line in resolution.lines) {
        context.addReport(line);
      }
    }

    return true;
  }
}

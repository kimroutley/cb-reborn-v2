import 'package:cb_models/cb_models.dart';
import '../night_action.dart';
import '../night_resolution_context.dart';

class SoberAction extends NightAction {
  @override
  ActionPhase get phase => ActionPhase.preemptive;

  @override
  void execute(NightResolutionContext context) {
    for (final p in context.players.where((p) => p.isAlive && p.role.id == RoleIds.sober)) {
      final targetId = getTargetId(context, p.id, 'sober');
      if (targetId != null) {
        context.blockedIds.add(targetId);
        context.protectedIds.add(targetId);

        final target = context.getPlayer(targetId);
        context.report.add('${p.name} sent ${target.name} home.');
        context.teasers.add('${target.name} was seen leaving the club early.');

        // Also update player state if needed (e.g. soberAbilityUsed)
        // Original code didn't update soberAbilityUsed, so I won't either unless needed.
      }
    }
  }
}

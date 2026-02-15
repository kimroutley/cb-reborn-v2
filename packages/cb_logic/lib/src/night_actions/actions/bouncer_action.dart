import 'package:cb_models/cb_models.dart';
import '../night_action.dart';
import '../night_resolution_context.dart';

class BouncerAction extends NightAction {
  @override
  ActionPhase get phase => ActionPhase.investigation;

  @override
  void execute(NightResolutionContext context) {
    for (final p in context.players.where((p) => p.isAlive && p.role.id == RoleIds.bouncer)) {
      if (context.blockedIds.contains(p.id)) continue;

      final targetId = getTargetId(context, p.id, 'bouncer');
      if (targetId != null) {
        final target = context.getPlayer(targetId);
        final isStaff = target.alliance == Team.clubStaff;

        context.addPrivateMessage(p.id, 'ID CHECK: ${target.name} is ${isStaff ? "STAFF" : "NOT STAFF"}.');
        context.report.add('${p.name} checked ${target.name}\'s ID.');
        context.teasers.add('Someone\'s ID was carefully scrutinized by the Bouncer.');
      }
    }
  }
}

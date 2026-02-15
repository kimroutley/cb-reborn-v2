import 'package:cb_models/cb_models.dart';
import '../night_action.dart';
import '../night_resolution_context.dart';

class RoofiAction extends NightAction {
  @override
  ActionPhase get phase => ActionPhase.preemptive;

  @override
  void execute(NightResolutionContext context) {
    for (final p in context.players.where((p) => p.isAlive && p.role.id == RoleIds.roofi)) {
      final targetId = getTargetId(context, p.id, 'roofi');
      if (targetId != null) {
        context.silencedIds.add(targetId);

        // Roofi also blocks if they hit the ONLY active dealer
        // Note: we must check blockedIds as Sober runs before Roofi?
        // Original code: Sober and Roofi are in same loop. Sober is processed first inside the loop if player has role Sober.
        // But since we iterate over players, the order depends on player list order?
        // Wait, original code:
        /*
        for (final p in currentPlayers.where((p) => p.isAlive)) {
           // check sober
           // check roofi
        }
        */
        // So a player can be BOTH Sober and Roofi? No, unique roles.
        // Order of execution between Sober and Roofi doesn't matter unless one targets the other.
        // If Sober targets Roofi, Roofi is blocked.
        // Original code checks `log['sober_act_${p.id}']` then adds to blockedIds.
        // Then checks `log['roofi_act_${p.id}']`.
        // It does NOT check if `p` (the actor) is blocked. So Pre-emptive actions are NOT blockable by other pre-emptive actions in the same phase in the original code?
        // Wait, "Process Pre-emptive actions (Sober, Roofi)". It iterates all players.
        // If Sober blocks Roofi, does Roofi act?
        // Original code:
        /*
          final targetId = log['sober_act_${p.id}'];
          if (targetId != null) { blockedIds.add(targetId); ... }

          final roofiTarget = log['roofi_act_${p.id}'];
          if (roofiTarget != null) { ... }
        */
        // It does NOT check if `p.id` is in `blockedIds` before processing Roofi action.
        // So Sober CANNOT block Roofi from acting in the same night in the original code!
        // Wait, if Sober targets Roofi, Roofi is added to `blockedIds`.
        // But the loop continues to process Roofi's action because it doesn't check `blockedIds.contains(p.id)`.

        // HOWEVER, later phases (Investigative, Murder) DO check `!blockedIds.contains(p.id)`.

        // So my implementation of separate classes must preserve this behavior.
        // SoberAction runs. RoofiAction runs. Neither checks if actor is blocked.

        final target = context.getPlayer(targetId);

        // Special logic: Roofi blocks if they hit the ONLY active dealer
        final activeDealers = context.players.where((pl) =>
            pl.isAlive &&
            pl.role.id == RoleIds.dealer &&
            !context.blockedIds.contains(pl.id)); // Uses blockedIds populated by Sober so far?

        // In original code, `blockedIds` is populated sequentially as we iterate players.
        // If Sober is P1 and Roofi is P2. P1 acts, blocks P2.
        // Then P2 acts (Roofi logic runs). It calculates activeDealers.
        // If P2 (Roofi) targets a Dealer (P3).
        // `activeDealers` check: P3 is Dealer. Is P3 blocked?
        // If Sober (P1) targeted P3, then P3 is blocked.

        if (activeDealers.length == 1 &&
            activeDealers.first.id == targetId) {
          context.blockedIds.add(targetId);
        }

        context.report.add('${p.name} drugged ${target.name}.');
        context.teasers.add('${target.name} looks a bit dazed.');
      }
    }
  }
}

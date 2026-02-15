import 'package:cb_models/cb_models.dart';
import 'night_resolution_context.dart';

enum ActionPhase {
  preemptive, // Sober, Roofi
  investigation, // Bouncer
  murder, // Dealer
  protection, // Medic
}

abstract class NightAction {
  // Returns the phase this action belongs to
  ActionPhase get phase;

  // The priority within the phase (lower is earlier)
  int get priority => 0;

  void execute(NightResolutionContext context);

  // Helper to find targets from log
  String? getTargetId(NightResolutionContext context, String actorId, String prefix) {
    return context.log['${prefix}_act_$actorId'];
  }
}

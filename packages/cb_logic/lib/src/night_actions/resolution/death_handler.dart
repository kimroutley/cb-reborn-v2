import 'package:cb_models/cb_models.dart';
import '../night_resolution_context.dart';

abstract class DeathHandler {
  /// Returns true if the handler successfully processed the death (e.g., prevented it or modified state),
  /// stopping further handlers from running.
  bool handle(NightResolutionContext context, Player victim);
}

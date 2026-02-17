import 'night_resolution_context.dart';

/// A strategy for resolving a specific night action or interaction.
abstract class NightActionStrategy {
  /// The role ID this strategy applies to.
  String get roleId;

  /// Executes the action within the given [context].
  void execute(NightResolutionContext context);
}

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cb_models/cb_models.dart';
import 'persistence/persistence_service.dart';

part 'games_night_provider.g.dart';

/// Provider for managing Games Night sessions.
@Riverpod(keepAlive: true)
class GamesNight extends _$GamesNight {
  @override
  GamesNightRecord? build() {
    // Load active session on provider initialization
    _loadActiveSession();
    return null;
  }

  Future<void> _loadActiveSession() async {
    final service = PersistenceService.instance;
    final activeSession = await service.loadActiveSession();
    if (activeSession != null) {
      state = activeSession;
    }
  }

  /// Start a new Games Night session.
  Future<void> startSession(String sessionName) async {
    final service = PersistenceService.instance;

    final newSession = GamesNightRecord(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      sessionName: sessionName,
      startedAt: DateTime.now(),
      endedAt: null,
      isActive: true,
    );

    await service.saveGamesNightRecord(newSession);
    state = newSession;
  }

  /// End the current active session.
  Future<void> endSession() async {
    if (state == null) return;

    final service = PersistenceService.instance;
    await service.endSession(state!.id);

    // Reload to get updated state
    final sessions = await service.loadAllSessions();
    final updatedSession = sessions.firstWhere(
      (s) => s.id == state!.id,
    );

    state = updatedSession;
  }

  /// Clear the active session from state (for navigation/UI purposes).
  void clearActiveSession() {
    state = null;
  }

  /// Refresh the current session from persistence.
  Future<void> refreshSession() async {
    if (state == null) return;

    final service = PersistenceService.instance;
    final sessions = await service.loadAllSessions();

    try {
      final updatedSession = sessions.firstWhere((s) => s.id == state!.id);
      state = updatedSession;
    } catch (_) {
      // Session no longer exists
      state = null;
    }
  }
}

/// Interface for analytics provider.
abstract class AnalyticsProvider {
  Future<void> setAnalyticsCollectionEnabled(bool enabled);
  Future<void> logScreenView({String? screenName, String? screenClass});
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });
}

/// Analytics service for tracking game events.
class AnalyticsService {
  AnalyticsService._();

  static AnalyticsProvider? _provider;
  static bool _enabled = true;

  /// Set the analytics provider.
  static void setProvider(AnalyticsProvider provider) {
    _provider = provider;
  }

  /// Enable/disable analytics.
  static Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _provider?.setAnalyticsCollectionEnabled(enabled);
  }

  /// Log screen view.
  static Future<void> logScreenView(String screenName) async {
    if (!_enabled) return;
    await _provider?.logScreenView(screenName: screenName);
  }

  /// Log game started event.
  static Future<void> logGameStarted({
    required int playerCount,
    required String gameStyle,
    required String syncMode,
  }) async {
    if (!_enabled) return;
    await _provider?.logEvent(
      name: 'game_start',
      parameters: {
        'player_count': playerCount,
        'game_style': gameStyle,
        'sync_mode': syncMode,
      },
    );
  }

  /// Log game completed event.
  static Future<void> logGameCompleted({
    required String winner,
    required int dayCount,
    required Duration duration,
  }) async {
    if (!_enabled) return;
    await _provider?.logEvent(
      name: 'game_complete',
      parameters: {
        'winner': winner,
        'day_count': dayCount,
        'duration_minutes': duration.inMinutes,
      },
    );
  }

  /// Log role assigned event.
  static Future<void> logRoleAssigned(String roleId) async {
    if (!_enabled) return;
    await _provider?.logEvent(
      name: 'role_assigned',
      parameters: {'role_id': roleId},
    );
  }

  /// Log night action event.
  static Future<void> logNightAction(String roleId, String actionType) async {
    if (!_enabled) return;
    await _provider?.logEvent(
      name: 'night_action',
      parameters: {'role_id': roleId, 'action_type': actionType},
    );
  }

  /// Log vote cast event.
  static Future<void> logVoteCast() async {
    if (!_enabled) return;
    await _provider?.logEvent(name: 'vote_cast');
  }

  /// Log player death event.
  static Future<void> logPlayerDeath(String roleId, String causeOfDeath) async {
    if (!_enabled) return;
    await _provider?.logEvent(
      name: 'player_death',
      parameters: {'role_id': roleId, 'cause_of_death': causeOfDeath},
    );
  }

  /// Log error event.
  static Future<void> logError(String error, {String? stackTrace}) async {
    if (!_enabled) return;
    await _provider?.logEvent(
      name: 'app_error',
      parameters: {
        'error': error,
        if (stackTrace != null) 'stack_trace': stackTrace,
      },
    );
  }
}

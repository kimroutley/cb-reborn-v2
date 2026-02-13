import 'package:cb_logic/cb_logic.dart';
import 'package:cb_logic/src/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAnalyticsProvider implements AnalyticsProvider {
  final List<String> screenViews = [];
  final List<Map<String, dynamic>> events = [];
  bool collectionEnabled = true;

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> logScreenView({String? screenName, String? screenClass}) async {
    if (screenName != null) screenViews.add(screenName);
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    events.add({
      'name': name,
      if (parameters != null) 'parameters': parameters,
    });
  }
}

void main() {
  group('AnalyticsService', () {
    late MockAnalyticsProvider mockProvider;

    setUp(() {
      mockProvider = MockAnalyticsProvider();
      AnalyticsService.setProvider(mockProvider);
      // Ensure enabled state is reset to true for testing logging
      AnalyticsService.setEnabled(true);
    });

    test('setEnabled passes through to provider', () async {
      await AnalyticsService.setEnabled(false);
      expect(mockProvider.collectionEnabled, isFalse);

      await AnalyticsService.setEnabled(true);
      expect(mockProvider.collectionEnabled, isTrue);
    });

    test('logScreenView logs to provider', () async {
      await AnalyticsService.logScreenView('TestScreen');
      expect(mockProvider.screenViews, contains('TestScreen'));
    });

    test('logScreenView does not log when disabled', () async {
      await AnalyticsService.setEnabled(false);
      await AnalyticsService.logScreenView('TestScreen');
      expect(mockProvider.screenViews, isEmpty);
    });

    test('logGameStarted logs correct event', () async {
      await AnalyticsService.logGameStarted(
        playerCount: 5,
        gameStyle: 'Chaos',
        syncMode: 'Offline',
      );

      expect(mockProvider.events.length, 1);
      final event = mockProvider.events.first;
      expect(event['name'], 'game_start');
      expect(event['parameters'], {
        'player_count': 5,
        'game_style': 'Chaos',
        'sync_mode': 'Offline',
      });
    });

    test('logGameCompleted logs correct event', () async {
      await AnalyticsService.logGameCompleted(
        winner: 'Club Staff',
        dayCount: 3,
        duration: const Duration(minutes: 15),
      );

      expect(mockProvider.events.length, 1);
      final event = mockProvider.events.first;
      expect(event['name'], 'game_complete');
      expect(event['parameters'], {
        'winner': 'Club Staff',
        'day_count': 3,
        'duration_minutes': 15,
      });
    });

    test('logRoleAssigned logs correct event', () async {
      await AnalyticsService.logRoleAssigned('werewolf');

      expect(mockProvider.events.length, 1);
      final event = mockProvider.events.first;
      expect(event['name'], 'role_assigned');
      expect(event['parameters'], {'role_id': 'werewolf'});
    });

    test('logNightAction logs correct event', () async {
      await AnalyticsService.logNightAction('seer', 'inspect');

      expect(mockProvider.events.length, 1);
      final event = mockProvider.events.first;
      expect(event['name'], 'night_action');
      expect(event['parameters'], {
        'role_id': 'seer',
        'action_type': 'inspect',
      });
    });

    test('logVoteCast logs correct event', () async {
      await AnalyticsService.logVoteCast();

      expect(mockProvider.events.length, 1);
      final event = mockProvider.events.first;
      expect(event['name'], 'vote_cast');
      expect(event.containsKey('parameters'), isFalse);
    });

    test('logPlayerDeath logs correct event', () async {
      await AnalyticsService.logPlayerDeath('villager', 'mauled');

      expect(mockProvider.events.length, 1);
      final event = mockProvider.events.first;
      expect(event['name'], 'player_death');
      expect(event['parameters'], {
        'role_id': 'villager',
        'cause_of_death': 'mauled',
      });
    });

    test('logError logs correct event', () async {
      await AnalyticsService.logError('Something went wrong', stackTrace: 'stack...');

      expect(mockProvider.events.length, 1);
      final event = mockProvider.events.first;
      expect(event['name'], 'app_error');
      expect(event['parameters'], {
        'error': 'Something went wrong',
        'stack_trace': 'stack...',
      });
    });

    test('logError works without stackTrace', () async {
      await AnalyticsService.logError('Simple error');

      expect(mockProvider.events.length, 1);
      final event = mockProvider.events.first;
      expect(event['name'], 'app_error');
      expect(event['parameters'], {
        'error': 'Simple error',
      });
    });
  });
}

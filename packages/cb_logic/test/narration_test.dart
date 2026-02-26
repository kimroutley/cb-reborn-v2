import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockGeminiNarrationService extends Mock implements GeminiNarrationService {}

void main() {
  group('Dual-Track Night Narration', () {
    late ProviderContainer container;
    late MockGeminiNarrationService mockGeminiService;

    setUp(() {
      mockGeminiService = MockGeminiNarrationService();
      container = ProviderContainer(
        overrides: [
          geminiNarrationServiceProvider.overrideWithValue(mockGeminiService),
        ],
      );

      // Setup default mock responses
      when(() => mockGeminiService.hasApiKey).thenReturn(true);
      when(() => mockGeminiService.generateNightNarration(
            lastNightReport: any(named: 'lastNightReport'),
            forHostOnly: false,
            dayCount: any(named: 'dayCount'),
            aliveCount: any(named: 'aliveCount'),
            voice: any(named: 'voice'),
            variationPrompt: any(named: 'variationPrompt'),
            model: any(named: 'model'),
            isMature: any(named: 'isMature'),
          )).thenAnswer((_) async => 'Player-safe narration.');
      when(() => mockGeminiService.generateNightNarration(
            lastNightReport: any(named: 'lastNightReport'),
            forHostOnly: true,
            dayCount: any(named: 'dayCount'),
            aliveCount: any(named: 'aliveCount'),
            voice: any(named: 'voice'),
            variationPrompt: any(named: 'variationPrompt'),
            model: any(named: 'model'),
            isMature: any(named: 'isMature'),
          )).thenAnswer((_) async => 'Host-spicy narration.');
    });

    test(
        'generateDynamicNightNarration calls Gemini service with correct forHostOnly flag',
        () async {
      final controller = container.read(gameProvider.notifier);
      controller.state = controller.state.copyWith(lastNightReport: ['Someone died.']);

      // Act
      await controller.generateDynamicNightNarration(forHostOnly: false);
      await controller.generateDynamicNightNarration(forHostOnly: true);

      // Assert
      verify(() => mockGeminiService.generateNightNarration(
            lastNightReport: any(named: 'lastNightReport'),
            forHostOnly: false,
            dayCount: any(named: 'dayCount'),
            aliveCount: any(named: 'aliveCount'),
            voice: any(named: 'voice'),
            variationPrompt: any(named: 'variationPrompt'),
            model: any(named: 'model'),
            isMature: any(named: 'isMature'),
          )).called(1);

      verify(() => mockGeminiService.generateNightNarration(
            lastNightReport: any(named: 'lastNightReport'),
            forHostOnly: true,
            dayCount: any(named: 'dayCount'),
            aliveCount: any(named: 'aliveCount'),
            voice: any(named: 'voice'),
            variationPrompt: any(named: 'variationPrompt'),
            model: any(named: 'model'),
            isMature: any(named: 'isMature'),
          )).called(1);
    });

    test('dispatches only mechanical host recap when AI is disabled', () {
      // Arrange
      when(() => mockGeminiService.hasApiKey).thenReturn(false);
      final gameNotifier = container.read(gameProvider.notifier);
      gameNotifier.loadTestGameSandbox();
      gameNotifier.startGame();
      // Simulate a dealer action to ensure a report is generated
      final dealer = gameNotifier.state.players.firstWhere((p) => p.role.id == RoleIds.dealer);
      final target = gameNotifier.state.players.firstWhere((p) => p.id != dealer.id);
      gameNotifier.state = gameNotifier.state.copyWith(
        phase: GamePhase.night,
        actionLog: {'dealer_act_${dealer.id}_1': target.id},
      );

      // Act
      gameNotifier.advancePhase(); // Night -> Day transition

      // Assert
      final bulletins = gameNotifier.state.bulletinBoard;
      final hostRecap = bulletins.where((b) => b.title == 'NIGHT RECAP (HOST)');
      
      expect(hostRecap, isNotEmpty, reason: 'Should have a mechanical host recap.');
      expect(hostRecap.first.isHostOnly, isTrue);
      expect(hostRecap.first.content, contains('butchered'));

      final playerTeaser = bulletins.where((b) => b.title == 'NIGHT RECAP' && !b.isHostOnly);
      expect(playerTeaser, isNotEmpty, reason: 'Should have a public teaser recap.');

      final aiRecaps = bulletins.where((b) => b.title.contains('AI NARRATOR'));
      expect(aiRecaps, isEmpty, reason: 'Should not have any AI recaps when AI is off.');
    });
  });
}

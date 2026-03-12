import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('GameNarrationController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    test(
        'generateDynamicNightNarration returns static template randomly with report',
        () async {
      final controller = container.read(gameProvider.notifier);
      controller.state =
          controller.state.copyWith(lastNightReport: ['Someone died.']);

      // Act
      final result1 = await controller.generateDynamicNightNarration();
      
      // Assert
      expect(result1, isNotNull);
      expect(result1!.contains('Someone died.'), isTrue);
    });

    test('generateDynamicNightNarration returns null if no lastNightReport', () async {
      final controller = container.read(gameProvider.notifier);
      controller.state =
          controller.state.copyWith(lastNightReport: []);

      // Act
      final result = await controller.generateDynamicNightNarration();
      
      // Assert
      expect(result, isNull);
    });

    test('issues step updates properly without AI dependencies', () async {
      // Arrange
      final gameNotifier = container.read(gameProvider.notifier);
      gameNotifier.loadTestGameSandbox();
      
      // Simulate a dealer action to ensure a report is generated
      final dealer = gameNotifier.state.players
          .firstWhere((p) => p.role.id == RoleIds.dealer);
      final target =
          gameNotifier.state.players.firstWhere((p) => p.id != dealer.id);
      
      gameNotifier.state = gameNotifier.state.copyWith(
        phase: GamePhase.night,
        actionLog: {'dealer_act_${dealer.id}_1': target.id},
        scriptQueue: [],
        scriptIndex: 0,
      );

      // Act
      gameNotifier.advancePhase(); // Night -> Day transition

      // Assert
      final bulletins = gameNotifier.state.bulletinBoard;
      final hostRecap =
          bulletins.where((b) => b.title == 'NIGHT RESOLUTION (HOST)');

      expect(hostRecap, isNotEmpty,
          reason: 'Should have a mechanical host recap.');
      expect(hostRecap.first.isHostOnly, isTrue);

      final playerTeaser =
          bulletins.where((b) => b.title == 'NIGHT RECAP' && !b.isHostOnly);
      expect(playerTeaser, isNotEmpty,
          reason: 'Should have a public teaser recap.');
    });
  });
}

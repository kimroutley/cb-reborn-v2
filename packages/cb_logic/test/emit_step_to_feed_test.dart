import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:riverpod/riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late Game game;

  setUp(() {
    container = ProviderContainer();
    game = container.read(gameProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('Game.emitStepToFeed', () {
    test('does nothing when currentStep is null', () {
      final stateBefore = container.read(gameProvider);
      expect(stateBefore.currentStep, isNull);
      expect(stateBefore.feedEvents, isEmpty);

      game.emitStepToFeed();

      final stateAfter = container.read(gameProvider);
      expect(stateAfter.feedEvents, isEmpty);
    });

    test('emits narrative event when readAloudText is present', () {
      _addMockPlayers(game, 4);
      game.startGame();

      final state = container.read(gameProvider);
      final currentStep = state.currentStep;
      expect(currentStep, isNotNull);
      expect(currentStep!.readAloudText, isNotEmpty);

      final initialEventsCount = state.feedEvents.length;

      game.emitStepToFeed();

      final updatedState = container.read(gameProvider);
      expect(updatedState.feedEvents.length, greaterThan(initialEventsCount));

      final narrativeEvent = updatedState.feedEvents
          .lastWhere((e) => e.type == FeedEventType.narrative);
      expect(narrativeEvent.title, currentStep.title);
      expect(narrativeEvent.content, currentStep.readAloudText);
      expect(narrativeEvent.stepId, currentStep.id);
    });

    test('emits directive event when instructionText is present', () {
      _addMockPlayers(game, 4);
      game.startGame();

      final currentStep = container.read(gameProvider).currentStep;
      expect(currentStep!.instructionText, isNotEmpty);

      final initialEventsCount = container.read(gameProvider).feedEvents.length;

      game.emitStepToFeed();

      final updatedState = container.read(gameProvider);
      expect(updatedState.feedEvents.length, greaterThan(initialEventsCount));

      final directiveEvent = updatedState.feedEvents
          .lastWhere((e) => e.type == FeedEventType.directive);
      expect(directiveEvent.title, 'HOST NOTES');
      expect(directiveEvent.content, currentStep.instructionText);
      expect(directiveEvent.stepId, currentStep.id);
    });

    test('emits action event when actionType is interactive', () {
      _addMockPlayers(game, 12);
      game.startGame();

      bool found = false;
      for (int i = 0; i < 20; i++) {
        final state = container.read(gameProvider);
        final step = state.currentStep;
        if (step == null) break;

        if (_isInteractiveAction(step.actionType)) {
          found = true;
          game.emitStepToFeed();

          final updatedState = container.read(gameProvider);
          final actionEvent = updatedState.feedEvents
              .lastWhere((e) => e.type == FeedEventType.action);
          expect(actionEvent.stepId, step.id);
          expect(actionEvent.actionType, step.actionType);
          expect(actionEvent.options, step.options);
          break;
        }
        game.advancePhase();
      }
      expect(found, true, reason: 'Should have found an interactive step');
    });

    test(
        'emits all three events for a complex step (narrative, directive, and action)',
        () {
      _addMockPlayers(game, 12);
      game.startGame();

      bool found = false;
      for (int i = 0; i < 20; i++) {
        final state = container.read(gameProvider);
        final step = state.currentStep;
        if (step == null) break;

        if (step.readAloudText.isNotEmpty &&
            step.instructionText.isNotEmpty &&
            _isInteractiveAction(step.actionType)) {
          found = true;
          final initialEventsCount = state.feedEvents.length;
          game.emitStepToFeed();

          final updatedState = container.read(gameProvider);
          final addedEvents =
              updatedState.feedEvents.sublist(initialEventsCount);

          expect(
              addedEvents.any((e) => e.type == FeedEventType.narrative), true);
          expect(
              addedEvents.any((e) => e.type == FeedEventType.directive), true);
          expect(addedEvents.any((e) => e.type == FeedEventType.action), true);
          break;
        }
        game.advancePhase();
      }
      expect(found, true, reason: 'Should have found a complex step');
    });

    test('timestamp and baseId are consistent across events from the same call',
        () {
      _addMockPlayers(game, 12);
      game.startGame();

      bool found = false;
      for (int i = 0; i < 20; i++) {
        final state = container.read(gameProvider);
        final step = state.currentStep;
        if (step == null) break;

        if (step.readAloudText.isNotEmpty && step.instructionText.isNotEmpty) {
          found = true;
          final initialEventsCount = state.feedEvents.length;
          game.emitStepToFeed();

          final updatedState = container.read(gameProvider);
          final addedEvents =
              updatedState.feedEvents.sublist(initialEventsCount);
          expect(addedEvents.length, greaterThanOrEqualTo(2));

          final firstEvent = addedEvents[0];
          final secondEvent = addedEvents[1];

          final id1 = firstEvent.id.split('_')[0];
          final id2 = secondEvent.id.split('_')[0];
          expect(id1, id2);
          expect(firstEvent.timestamp, secondEvent.timestamp);
          break;
        }
        game.advancePhase();
      }
      expect(found, true);
    });

    test('emitCurrentStepNarrationVariationToFeed adds AI narrative event',
        () async {
      _addMockPlayers(game, 6);
      game.startGame();

      final before = container.read(gameProvider);
      expect(before.currentStep, isNotNull);

      final success = await game.emitCurrentStepNarrationVariationToFeed();
      expect(success, true);

      final after = container.read(gameProvider);
      expect(after.feedEvents.length, greaterThan(before.feedEvents.length));

      final aiEvent = after.feedEvents.last;
      expect(aiEvent.type, FeedEventType.narrative);
      expect(aiEvent.title, contains('AI VARIATION'));
      expect(aiEvent.content.trim(), isNotEmpty);
      expect(aiEvent.stepId, before.currentStep!.id);
    });

    test('emitCurrentStepNarrationVariationToFeed returns false when no step',
        () async {
      final success = await game.emitCurrentStepNarrationVariationToFeed();
      expect(success, false);
    });
  });
}

void _addMockPlayers(Game game, int count) {
  final names = [
    'Alice',
    'Bob',
    'Charlie',
    'Diana',
    'Eve',
    'Frank',
    'Grace',
    'Hank',
    'Ivy',
    'Jack',
    'Kelly',
    'Liam'
  ];
  for (var i = 0; i < count && i < names.length; i++) {
    game.addPlayer(names[i]);
  }
}

bool _isInteractiveAction(ScriptActionType type) {
  return type == ScriptActionType.selectPlayer ||
      type == ScriptActionType.selectTwoPlayers ||
      type == ScriptActionType.binaryChoice ||
      type == ScriptActionType.confirm ||
      type == ScriptActionType.optional ||
      type == ScriptActionType.multiSelect;
}

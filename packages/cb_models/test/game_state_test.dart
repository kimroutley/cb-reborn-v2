import 'dart:convert';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameState Tests', () {
    const testRole = Role(
      id: 'medic',
      name: 'Medic',
      type: 'protective',
      description: 'Can save one person each night.',
      nightPriority: 10,
      assetPath: 'assets/medic.png',
      colorHex: '#FFFFFF',
    );

    final testPlayer = Player(
      id: 'p1',
      name: 'Test Player',
      role: testRole,
      alliance: Team.partyAnimals,
    );

    const testStep = ScriptStep(
      id: 'intro',
      title: 'Welcome',
      readAloudText: 'Hello everyone',
      instructionText: 'Sit down',
    );

    test('Default values are correct', () {
      const gameState = GameState();

      expect(gameState.players, isEmpty);
      expect(gameState.phase, GamePhase.lobby);
      expect(gameState.dayCount, 1);
      expect(gameState.scriptQueue, isEmpty);
      expect(gameState.scriptIndex, 0);
      expect(gameState.actionLog, isEmpty);
      expect(gameState.lastNightReport, isEmpty);
      expect(gameState.dayVoteTally, isEmpty);
      expect(gameState.privateMessages, isEmpty);
      expect(gameState.bulletinBoard, isEmpty);
      expect(gameState.syncMode, SyncMode.local);
      expect(gameState.gameStyle, GameStyle.chaos);
      expect(gameState.tieBreakStrategy, TieBreakStrategy.peaceful);
      expect(gameState.eyesOpen, isTrue);
    });

    test('Serialization (toJson/fromJson) works correctly', () {
      final gameState = GameState(
        players: [testPlayer],
        phase: GamePhase.night,
        dayCount: 2,
        scriptQueue: [testStep],
        scriptIndex: 0,
        actionLog: {'medic_choice': 'p2'},
        lastNightReport: ['Player 2 was saved'],
        dayVoteTally: {'p1': 3},
        winner: Team.partyAnimals,
        privateMessages: {
          'p1': ['You saved p2'],
        },
        gameHistory: ['Game started'],
        bulletinBoard: [
          BulletinEntry(
            id: 'b1',
            title: 'News',
            content: 'Nothing happened',
            timestamp: DateTime(2023, 1, 1),
            type: 'announcement',
          ),
        ],
      );

      final jsonMap = gameState.toJson();
      // Simulate full serialization cycle to ensure nested objects are converted
      final jsonString = jsonEncode(jsonMap);
      final decodedMap = jsonDecode(jsonString);

      final decodedState = GameState.fromJson(decodedMap);

      expect(decodedState.players.length, 1);
      expect(decodedState.players.first.id, testPlayer.id);
      expect(decodedState.phase, GamePhase.night);
      expect(decodedState.dayCount, 2);
      expect(decodedState.scriptQueue.length, 1);
      expect(decodedState.scriptQueue.first.id, testStep.id);
      expect(decodedState.actionLog['medic_choice'], 'p2');
      expect(decodedState.lastNightReport.first, 'Player 2 was saved');
      expect(decodedState.dayVoteTally['p1'], 3);
      expect(decodedState.winner, Team.partyAnimals);
      expect(decodedState.privateMessages['p1']?.first, 'You saved p2');
      expect(decodedState.gameHistory.first, 'Game started');
      expect(decodedState.bulletinBoard.first.id, 'b1');
    });

    test('currentStep getter returns correct step', () {
      final gameState = GameState(scriptQueue: [testStep], scriptIndex: 0);

      expect(gameState.currentStep, isNotNull);
      expect(gameState.currentStep!.id, testStep.id);
    });

    test('currentStep getter returns null when index out of bounds', () {
      final gameState = GameState(
        scriptQueue: [testStep],
        scriptIndex: 1, // Out of bounds
      );

      expect(gameState.currentStep, isNull);
    });

    test('currentStep getter returns null when queue is empty', () {
      const gameState = GameState(scriptQueue: [], scriptIndex: 0);

      expect(gameState.currentStep, isNull);
    });

    test('copyWith updates state correctly', () {
      const gameState = GameState();
      final updatedState = gameState.copyWith(
        phase: GamePhase.day,
        dayCount: 5,
        players: [testPlayer],
      );

      expect(updatedState.phase, GamePhase.day);
      expect(updatedState.dayCount, 5);
      expect(updatedState.players.length, 1);
      expect(updatedState.players.first, testPlayer);

      // Original state should remain unchanged
      expect(gameState.phase, GamePhase.lobby);
      expect(gameState.dayCount, 1);
      expect(gameState.players, isEmpty);
    });
  });
}

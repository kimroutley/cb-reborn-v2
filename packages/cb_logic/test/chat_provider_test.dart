import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  late ProviderContainer container;
  late Chat chatNotifier;

  setUp(() {
    container = ProviderContainer();
    chatNotifier = container.read(chatProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('ChatProvider', () {
    test('initial state is empty', () {
      final messages = container.read(chatProvider);
      expect(messages, isEmpty);
    });

    test('addMessage appends to state', () {
      final msg = ChatMessage(
        id: '1',
        playerId: 'p1',
        playerName: 'P1',
        message: 'Hello',
        timestamp: DateTime.now(),
      );
      chatNotifier.addMessage(msg);
      final messages = container.read(chatProvider);
      expect(messages.length, 1);
      expect(messages.first, equals(msg));
    });

    test('sendMessage creates user message', () {
      chatNotifier.sendMessage('p1', 'P1', 'Hello world');
      final messages = container.read(chatProvider);
      expect(messages.length, 1);
      final msg = messages.first;
      expect(msg.playerId, 'p1');
      expect(msg.playerName, 'P1');
      expect(msg.message, 'Hello world');
      expect(msg.isSystem, false);
      expect(msg.timestamp, isNotNull);
      expect(msg.id, isNotEmpty);
    });

    test('sendMessage ignores empty or whitespace string', () {
      chatNotifier.sendMessage('p1', 'P1', '');
      expect(container.read(chatProvider), isEmpty);

      chatNotifier.sendMessage('p1', 'P1', '   ');
      expect(container.read(chatProvider), isEmpty);
    });

    test('sendSystemMessage creates system message', () {
      chatNotifier.sendSystemMessage('System alert');
      final messages = container.read(chatProvider);
      expect(messages.length, 1);
      final msg = messages.first;
      expect(msg.playerId, 'system');
      expect(msg.playerName, 'System');
      expect(msg.message, 'System alert');
      expect(msg.isSystem, true);
    });

    test('clearMessages resets state', () {
      chatNotifier.sendMessage('p1', 'P1', 'Hello');
      expect(container.read(chatProvider), isNotEmpty);

      chatNotifier.clearMessages();
      expect(container.read(chatProvider), isEmpty);
    });
  });
}

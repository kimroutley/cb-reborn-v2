import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cb_models/cb_models.dart';

part 'chat_provider.g.dart';

/// Chat provider managing in-game messages.
@Riverpod(keepAlive: true)
class Chat extends _$Chat {
  @override
  List<ChatMessage> build() {
    return [];
  }

  /// Add a chat message.
  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  /// Send a player message.
  void sendMessage(String playerId, String playerName, String message) {
    if (message.trim().isEmpty) return;
    final chatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      playerId: playerId,
      playerName: playerName,
      message: message.trim(),
      timestamp: DateTime.now(),
    );
    addMessage(chatMessage);
  }

  /// Send a system message.
  void sendSystemMessage(String message) {
    final chatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      playerId: 'system',
      playerName: 'System',
      message: message,
      timestamp: DateTime.now(),
      isSystem: true,
    );
    addMessage(chatMessage);
  }

  /// Clear all messages.
  void clearMessages() {
    state = [];
  }
}

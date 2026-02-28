import 'package:cb_models/cb_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_provider.g.dart';

@Riverpod(keepAlive: true)
class Chat extends _$Chat {
  @override
  List<ChatMessage> build() => const [];

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void sendMessage(String playerId, String playerName, String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    addMessage(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        playerId: playerId,
        playerName: playerName,
        message: trimmedText,
        timestamp: DateTime.now(),
      ),
    );
  }

  void sendSystemMessage(String text) {
    addMessage(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        playerId: 'system',
        playerName: 'System',
        message: text,
        timestamp: DateTime.now(),
        isSystem: true,
      ),
    );
  }

  void clearMessages() {
    state = const [];
  }
}
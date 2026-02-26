import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';

/// In-game chat widget for player communication.
class ChatWidget extends ConsumerStatefulWidget {
  final String playerId;
  final String playerName;

  const ChatWidget({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  ConsumerState<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends ConsumerState<ChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    ref
        .read(chatProvider.notifier)
        .sendMessage(widget.playerId, widget.playerName, _controller.text);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final messages = ref.watch(chatProvider);

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.chat, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Chat', style: textTheme.labelLarge!),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CBTextField(
                    controller: _controller,
                    textStyle: textTheme.bodyMedium!,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: textTheme.bodySmall!,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send, color: scheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isSystem)
            Icon(Icons.info_outline, size: 16, color: scheme.tertiary)
          else
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 6, right: 8),
              decoration: BoxDecoration(color: scheme.primary),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!message.isSystem)
                  Text(
                    message.playerName,
                    style: textTheme.labelSmall!.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                Text(
                  message.message,
                  style: message.isSystem
                      ? textTheme.bodySmall!.copyWith(
                          color: scheme.tertiary,
                          fontStyle: FontStyle.italic,
                        )
                      : textTheme.bodyMedium!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticService.selection();
    ref.read(chatProvider.notifier).sendMessage(
          widget.playerId,
          widget.playerName,
          text,
        );
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final messages = ref.watch(chatProvider);

    return CBGlassTile(
      padding: EdgeInsets.zero,
      borderColor: scheme.primary.withValues(alpha: 0.3),
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(CBRadius.md)),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: CBSpace.x3),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.forum_rounded,
                      size: 18, color: scheme.primary),
                ),
                const SizedBox(width: CBSpace.x3),
                Text(
                  'MISSION COMS',
                  style: textTheme.labelLarge!.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: scheme.primary,
                    shadows: CBColors.textGlow(scheme.primary, intensity: 0.3),
                  ),
                ),
                const Spacer(),
                CBBadge(
                  text: '${messages.length} TRANSLATIONS',
                  color: scheme.primary,
                ),
              ],
            ),
          ),

          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.3),
                  CBColors.transparent
                ],
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(CBSpace.x4),
              physics: const BouncingScrollPhysics(),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return CBFadeSlide(
                  delay: const Duration(milliseconds: 50),
                  child: _MessageBubble(
                    message: message,
                    isMe: message.playerId == widget.playerId,
                  ),
                );
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(CBSpace.x3, CBSpace.x2, CBSpace.x3, CBSpace.x3),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.15))),
              color: scheme.surfaceContainerLowest.withValues(alpha: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CBTextField(
                    controller: _controller,
                    hintText: 'DISPATCH ENCRYPTED SIGNAL...',
                    textStyle: textTheme.bodyMedium!,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: CBSpace.x2),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send_rounded, color: scheme.primary),
                  tooltip: 'Send Signal',
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
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    if (message.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: CBSpace.x3),
          padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.tertiary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(CBRadius.pill),
            border: Border.all(color: scheme.tertiary.withValues(alpha: 0.2)),
          ),
          child: Text(
            message.message.toUpperCase(),
            style: textTheme.labelSmall!.copyWith(
              color: scheme.tertiary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final accent = isMe ? scheme.primary : scheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: CBSpace.x3),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CBSpace.x2, vertical: CBSpace.x1),
            child: Text(
              (isMe ? 'YOU' : message.playerName).toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: accent.withValues(alpha: 0.7),
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? accent.withValues(alpha: 0.15)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(CBRadius.md),
                topRight: const Radius.circular(CBRadius.md),
                bottomLeft: Radius.circular(isMe ? CBRadius.md : 4),
                bottomRight: Radius.circular(isMe ? 4 : CBRadius.md),
              ),
              border: Border.all(
                color: isMe
                    ? accent.withValues(alpha: 0.4)
                    : scheme.outlineVariant.withValues(alpha: 0.2),
                width: 1.2,
              ),
            ),
            child: Text(
              message.message,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

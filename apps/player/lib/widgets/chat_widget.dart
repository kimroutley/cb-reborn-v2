import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_theme/cb_theme.dart';

import '../active_bridge.dart';

/// In-game chat widget for player communication.
/// Uses the active bridge (cloud/local) for bulletin board and sending messages.
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
  final bool _autoScroll = true;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final bridgeState = ref.read(activeBridgeProvider).state;
    final player = bridgeState.myPlayerSnapshot;
    if (player == null) return;

    ref.read(activeBridgeProvider).actions.sendBulletin(
          title: player.roleName.isNotEmpty ? player.roleName : widget.playerName,
          floatContent: text,
          roleId: player.roleId.isNotEmpty ? player.roleId : null,
        );

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100, // Buffer for new item
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final bridgeState = ref.watch(activeBridgeProvider).state;
    final messages = bridgeState.bulletinBoard;
    final players = bridgeState.players;

    ref.listen(activeBridgeProvider.select((b) => b.state.bulletinBoard.length),
        (prev, next) {
      if (next > (prev ?? 0) && _autoScroll) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.5), // Glass-like background
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          // Messages List
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is UserScrollNotification) {
                  // If user manually scrolls, we could disable auto-scroll
                  // but for now we keep it simple.
                }
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final entry = messages[index];

                  // specialized handling for system/phase announcements
                  if (entry.type == 'system' || entry.type == 'phase') {
                    final isNight =
                        entry.content.toUpperCase().contains('NIGHT');
                    return CBFeedSeparator(
                      label: entry.content,
                      color: entry.type == 'system'
                          ? scheme.error
                          : (isNight ? scheme.secondary : scheme.primary),
                      isCinematic: true,
                    );
                  }

                  // Resolve sender details from bridge state (PlayerSnapshot)
                  bool isMe = entry.title == widget.playerName;
                  Color bubbleColor = scheme.primary;
                  String? avatarAsset;
                  CBMessageStyle style = CBMessageStyle.standard;

                  if (entry.roleId == null) {
                    avatarAsset = 'assets/roles/host_avatar.png';
                    style = CBMessageStyle.narrative;
                    bubbleColor = scheme.secondary;
                  } else {
                    try {
                      final senderPlayer = players
                          .firstWhere((p) => p.roleId == entry.roleId);
                      if (senderPlayer.id == widget.playerId) {
                        isMe = true;
                      }
                      bubbleColor =
                          CBColors.fromHex(senderPlayer.roleColorHex);
                      avatarAsset = 'assets/roles/${senderPlayer.roleId}.png';
                    } catch (_) {
                      // Fallback if role lookup fails
                    }
                  }

                  return CBMessageBubble(
                    sender: entry.title,
                    message: entry.content,
                    color: bubbleColor,
                    isSender: isMe,
                    avatarAsset: avatarAsset,
                    style: style,
                    isPrismatic: entry.roleId == null, // Host messages shine
                  );
                },
              ),
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(
                  top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CBTextField(
                    controller: _controller,
                    hintText: 'Type your message...',
                    textStyle: textTheme.bodyMedium!,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Send message',
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send_rounded, color: scheme.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cb_logic/cb_logic.dart';

/// In-game chat widget for player communication.
/// Connected to the shared GameState bulletin board.
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

    final gameState = ref.read(gameProvider);
    String? roleId;

    // Attempt to find the player's role ID for proper avatar display
    try {
      final player =
          gameState.players.firstWhere((p) => p.id == widget.playerId);
      roleId = player.role.id;
    } catch (_) {
      // Player might not be fully initialized or in lobby without role
    }

    ref.read(gameProvider.notifier).postBulletin(
          title: widget.playerName,
          content: text,
          roleId: roleId, // Important: Host Feed uses this to show avatar
          type: 'chat',
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

    // Watch shared game state instead of local chat provider
    final gameState = ref.watch(gameProvider);
    final messages = gameState.bulletinBoard;

    // Listen for new messages to auto-scroll
    ref.listen(gameProvider.select((s) => s.bulletinBoard.length),
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

                  // Resolve sender details
                  bool isMe = entry.title == widget.playerName;
                  Color bubbleColor = scheme.primary;
                  String? avatarAsset;
                  CBMessageStyle style = CBMessageStyle.standard;

                  if (entry.roleId == null) {
                    // Host message
                    avatarAsset = 'assets/roles/host_avatar.png';
                    style = CBMessageStyle.narrative;

                    // Resolve color based on personality in GameState
                    final pid = gameState.hostPersonalityId;
                    if (pid == 'the_ice_queen') {
                      bubbleColor = scheme.tertiary;
                    } else if (pid == 'protocol_9') {
                      bubbleColor = scheme.error;
                    } else if (pid == 'blood_sport_promoter') {
                      bubbleColor = scheme.secondary;
                    } else {
                      bubbleColor = scheme.secondary;
                    }
                  } else {
                    // Player message
                    try {
                      // We need to find the player by roleId to match Host logic
                      final senderPlayer = gameState.players
                          .firstWhere((p) => p.role.id == entry.roleId);

                      // Check if it's actually me (by player ID)
                      if (senderPlayer.id == widget.playerId) {
                        isMe = true;
                      }

                      bubbleColor =
                          CBColors.fromHex(senderPlayer.role.colorHex);
                      avatarAsset = 'assets/roles/${senderPlayer.role.id}.png';
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

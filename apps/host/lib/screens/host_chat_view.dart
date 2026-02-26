import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sheets/message_context_sheet.dart';

/// Host-side chat view showing bulletin board messages and ghost chat
/// from dead players, allowing the host to send narrative messages.
///
/// Uses [CBGlassTile] for the container and [CBMessageBubble] for messages
/// to mirror the Player App's chat aesthetics.
class HostChatView extends ConsumerStatefulWidget {
  final GameState gameState;

  const HostChatView({super.key, required this.gameState});

  @override
  ConsumerState<HostChatView> createState() => _HostChatViewState();
}

class _HostChatViewState extends ConsumerState<HostChatView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _liveScrollController = ScrollController();
  final ScrollController _ghostScrollController = ScrollController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _liveScrollController.dispose();
    _ghostScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _sendNarrativeMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(gameProvider.notifier).postBulletin(
      title: 'HOST',
      content: text,
      type: 'chat',
      roleId: null,
    );

    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_liveScrollController.hasClients) {
        _liveScrollController.animateTo(
          _liveScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<String> _extractGhostMessages() {
    final messages = <String>[];
    for (final entry in widget.gameState.privateMessages.entries) {
      for (final msg in entry.value) {
        if (msg.startsWith('[GHOST]') && !messages.contains(msg)) {
          messages.add(msg);
        }
      }
    }
    return messages;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final messages = widget.gameState.bulletinBoard;
    final ghostMessages = _extractGhostMessages();
    final deadCount =
        widget.gameState.players.where((p) => !p.isAlive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CBSectionHeader(
          title: 'COMMS CHANNEL',
          icon: Icons.chat_bubble_outline_rounded,
          color: scheme.secondary,
        ),
        const SizedBox(height: 12),

        // Tab bar
        CBGlassTile(
          borderColor: scheme.secondary.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: scheme.secondary.withValues(alpha: 0.4)),
            ),
            labelStyle: textTheme.labelSmall!.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
            unselectedLabelStyle: textTheme.labelSmall!.copyWith(
              fontWeight: FontWeight.w500,
            ),
            labelColor: scheme.secondary,
            unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.4),
            tabs: [
              const Tab(text: 'LIVE FEED'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('GHOST COMMS'),
                    if (ghostMessages.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: scheme.tertiary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${ghostMessages.length}',
                          style: textTheme.labelSmall!.copyWith(
                            color: scheme.onTertiary,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Live Feed
              _buildLiveFeed(scheme, textTheme, messages),
              // Tab 2: Ghost Comms
              _buildGhostFeed(scheme, textTheme, ghostMessages, deadCount),
            ],
          ),
        ),

        const SizedBox(height: 8),
        CBGlassTile(
          borderColor: scheme.secondary.withValues(alpha: 0.25),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: CBTextField(
                  controller: _controller,
                  textStyle: textTheme.bodyMedium!,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Send narrative message...',
                    hintStyle: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendNarrativeMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendNarrativeMessage,
                icon: Icon(Icons.send_rounded, color: scheme.secondary),
                tooltip: 'Send narrative',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveFeed(
    ColorScheme scheme,
    TextTheme textTheme,
    List<BulletinEntry> messages,
  ) {
    return CBGlassTile(
      borderColor: scheme.secondary.withValues(alpha: 0.25),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: messages.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'NO TRANSMISSIONS YET.',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.3),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                controller: _liveScrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final entry = messages[index];
                  final isHost = entry.roleId == null &&
                      (entry.title == 'HOST' || entry.type != 'chat');

                  String senderName = entry.title;
                  String? avatarAsset;

                  if (isHost) {
                    senderName = 'HOST';
                    avatarAsset = 'assets/roles/host_avatar.png';
                  } else {
                    try {
                      final player = widget.gameState.players.firstWhere(
                        (p) => p.role.id == entry.roleId,
                      );
                      senderName = player.name;
                      avatarAsset = 'assets/roles/${player.role.id}.png';
                    } catch (_) {}
                  }

                  if (isHost) {
                    return CBMessageBubble(
                      sender: senderName,
                      message: entry.content,
                      style: CBMessageStyle.narrative,
                      color: scheme.secondary,
                      isSender: true,
                      isCompact: true,
                      isPrismatic: true,
                    );
                  }

                  return CBMessageBubble(
                    sender: senderName,
                    message: entry.content,
                    style: CBMessageStyle.standard,
                    color: scheme.primary,
                    isSender: false,
                    isCompact: true,
                    avatarAsset: avatarAsset,
                    onTap: () => showMessageContextActions(
                      context,
                      playerName: senderName,
                      message: entry.content,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildGhostFeed(
    ColorScheme scheme,
    TextTheme textTheme,
    List<String> ghostMessages,
    int deadCount,
  ) {
    return CBGlassTile(
      borderColor: scheme.tertiary.withValues(alpha: 0.25),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Ghost count header
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.tertiary.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(
                    color: scheme.tertiary.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_outline_rounded,
                      color: scheme.tertiary, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    '$deadCount GHOST${deadCount == 1 ? '' : 'S'} ACTIVE',
                    style: textTheme.labelSmall!.copyWith(
                      color: scheme.tertiary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ghostMessages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_off_rounded,
                              color:
                                  scheme.onSurface.withValues(alpha: 0.15),
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'SPECTATOR CHANNEL SILENT.',
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurface
                                    .withValues(alpha: 0.3),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _ghostScrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: ghostMessages.length,
                      itemBuilder: (context, index) {
                        final msg = ghostMessages[index];
                        final ghostPrefix = RegExp(r'^\[GHOST\]\s*');
                        final cleaned =
                            msg.replaceFirst(ghostPrefix, '');
                        final colonIdx = cleaned.indexOf(':');
                        final sender = colonIdx > 0
                            ? cleaned.substring(0, colonIdx).trim()
                            : 'GHOST';
                        final body = colonIdx > 0
                            ? cleaned.substring(colonIdx + 1).trim()
                            : cleaned;

                        return CBMessageBubble(
                          sender: sender,
                          message: body,
                          style: CBMessageStyle.whisper,
                          color: scheme.tertiary,
                          isSender: false,
                          isCompact: true,
                          tags: [
                            CBMiniTag(
                              text: 'GHOST',
                              color: scheme.tertiary,
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

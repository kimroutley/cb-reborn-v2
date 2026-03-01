import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sheets/message_context_sheet.dart';

/// Host-side chat view showing the entire group chat: all bulletin messages
/// (including host-only and hostIntel) plus ghost chat from dead players.
/// Players see only player-safe entries on all platforms (including browsers).
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
  String? _targetRoleId;

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
    HapticService.selection();

    ref.read(gameProvider.notifier).postBulletin(
      title: 'HOST',
      content: text,
      type: 'chat',
      roleId: null,
      targetRoleId: _targetRoleId,
    );

    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_liveScrollController.hasClients) {
        _liveScrollController.animateTo(
          _liveScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CBFadeSlide(
          child: CBSectionHeader(
            title: 'COMMS CHANNEL',
            icon: Icons.chat_bubble_outline_rounded,
            color: scheme.secondary,
          ),
        ),
        const SizedBox(height: CBSpace.x4),

        CBFadeSlide(
          delay: const Duration(milliseconds: 100),
          child: CBGlassTile(
            borderColor: scheme.secondary.withValues(alpha: 0.2),
            padding: const EdgeInsets.symmetric(
                horizontal: CBSpace.x1, vertical: CBSpace.x1),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(CBRadius.sm),
                border:
                    Border.all(color: scheme.secondary.withValues(alpha: 0.4)),
              ),
              labelStyle: textTheme.labelSmall!.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
              unselectedLabelStyle: textTheme.labelSmall!.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
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
                        const SizedBox(width: CBSpace.x2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: CBSpace.x2, vertical: CBSpace.x1),
                          decoration: BoxDecoration(
                            color: scheme.tertiary,
                            borderRadius: BorderRadius.circular(CBRadius.xs),
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
        ),
        const SizedBox(height: CBSpace.x4),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildLiveFeed(scheme, textTheme, messages),
              _buildGhostFeed(scheme, textTheme, ghostMessages, deadCount),
            ],
          ),
        ),

        const SizedBox(height: CBSpace.x4),
        CBFadeSlide(
          delay: const Duration(milliseconds: 200),
          child: _buildTargetRoleChips(scheme, textTheme),
        ),
        const SizedBox(height: CBSpace.x2),
        CBFadeSlide(
          delay: const Duration(milliseconds: 300),
          child: CBGlassTile(
            borderColor: scheme.secondary.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: CBSpace.x2),
            child: Row(
              children: [
                Expanded(
                  child: CBTextField(
                    controller: _controller,
                    hintText: 'SEND NARRATIVE MESSAGE...',
                    textStyle: textTheme.bodyMedium!,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'SEND NARRATIVE MESSAGE...',
                      hintStyle: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.4),
                        letterSpacing: 0.5,
                      ),
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendNarrativeMessage(),
                  ),
                ),
                const SizedBox(width: CBSpace.x2),
                IconButton(
                  onPressed: _sendNarrativeMessage,
                  icon: Icon(Icons.send_rounded, color: scheme.secondary, size: 20),
                  tooltip: 'Send narrative message',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetRoleChips(ColorScheme scheme, TextTheme textTheme) {
    final playersWithRole = widget.gameState.players
        .where((p) => p.role.id != 'unassigned')
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: CBSpace.x2),
            child: CBFilterChip(
              label: 'EVERYONE',
              selected: _targetRoleId == null,
              onSelected: () {
                HapticService.selection();
                setState(() => _targetRoleId = null);
              },
              color: scheme.secondary,
              dense: true,
            ),
          ),
          ...playersWithRole.map((player) {
            final selected = _targetRoleId == player.role.id;
            final roleColor = CBColors.fromHex(player.role.colorHex);
            return Padding(
              padding: const EdgeInsets.only(right: CBSpace.x2),
              child: CBFilterChip(
                label: player.name,
                selected: selected,
                onSelected: () {
                  HapticService.selection();
                  setState(() =>
                      _targetRoleId = selected ? null : player.role.id);
                },
                color: roleColor,
                dense: true,
              ),
            );
          }),
        ],
      ),
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
        borderRadius: BorderRadius.circular(CBRadius.md),
        child: messages.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(CBSpace.x6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 48, color: scheme.onSurface.withValues(alpha: 0.1)),
                      const SizedBox(height: CBSpace.x4),
                      Text(
                        'NO TRANSMISSIONS LOGGED.',
                        style: textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.3),
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: CBSpace.x2),
                      Text(
                        'START A GAME TO SEE LIVE COMMUNICATIONS.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.2),
                          fontSize: 9,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                controller: _liveScrollController,
                padding: const EdgeInsets.symmetric(vertical: CBSpace.x2, horizontal: CBSpace.x4),
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

                  final isPrevSameSender = index > 0 &&
                      messages[index - 1].roleId == entry.roleId;
                  final isNextSameSender = index < messages.length - 1 &&
                      messages[index + 1].roleId == entry.roleId;

                  CBMessageGroupPosition groupPos = CBMessageGroupPosition.single;
                  if (isPrevSameSender && isNextSameSender) {
                    groupPos = CBMessageGroupPosition.middle;
                  } else if (isPrevSameSender && !isNextSameSender) {
                    groupPos = CBMessageGroupPosition.bottom;
                  } else if (!isPrevSameSender && isNextSameSender) {
                    groupPos = CBMessageGroupPosition.top;
                  }

                  return CBMessageBubble(
                    sender: senderName.toUpperCase(),
                    message: entry.content,
                    style: isHost ? CBMessageStyle.narrative : CBMessageStyle.standard,
                    color: isHost ? scheme.secondary : CBColors.fromHex(widget.gameState.players.firstWhere((p) => p.role.id == entry.roleId, orElse: () => Player(id: '', name: '', roleId: 'unassigned', roleName: '', roleColorHex: CBColors.primary.toHexString(), isBot: false, isAlive: true, alliance: Team.unknown)).roleColorHex),
                    isSender: isHost, // Host messages appear on the right
                    isCompact: true,
                    avatarAsset: avatarAsset,
                    groupPosition: groupPos,
                    onTap: () {
                      HapticService.light();
                      showMessageContextActions(
                        context,
                        playerName: senderName,
                        message: entry.content,
                      );
                    },
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
        borderRadius: BorderRadius.circular(CBRadius.md),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: CBSpace.x2),
              decoration: BoxDecoration(
                color: scheme.tertiary.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(
                    color: scheme.tertiary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_outline_rounded,
                      color: scheme.tertiary, size: 16),
                  const SizedBox(width: CBSpace.x2),
                  Text(
                    '$deadCount OPERATIVE${deadCount == 1 ? '' : 'S'} ELIMINATED',
                    style: textTheme.labelSmall!.copyWith(
                      color: scheme.tertiary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ghostMessages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(CBSpace.x6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_off_rounded,
                              color:
                                  scheme.onSurface.withValues(alpha: 0.15),
                              size: 48,
                            ),
                            const SizedBox(height: CBSpace.x4),
                            Text(
                              'SPECTATOR CHANNEL SILENT.',
                              style: textTheme.labelLarge?.copyWith(
                                color: scheme.onSurface
                                    .withValues(alpha: 0.3),
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: CBSpace.x2),
                            Text(
                              'NO TRANSMISSIONS FROM ELIMINATED OPERATIVES.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.2),
                                fontSize: 9,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _ghostScrollController,
                      padding: const EdgeInsets.symmetric(vertical: CBSpace.x2, horizontal: CBSpace.x4),
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

                        // Ghost messages are always from 'outside' the live game context, hence isSender: false
                        return CBMessageBubble(
                          sender: sender.toUpperCase(),
                          message: body,
                          style: CBMessageStyle.whisper,
                          color: scheme.tertiary,
                          isSender: false,
                          isCompact: true,
                          avatarAsset: 'assets/roles/ghost.png', // Assuming a ghost avatar exists
                          tags: [
                            CBMiniTag(
                              text: 'SPECTATOR',
                              color: scheme.tertiary,
                            ),
                          ],
                           onTap: () {
                              HapticService.light();
                              showMessageContextActions(
                                context,
                                playerName: sender,
                                message: body,
                              );
                            },
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

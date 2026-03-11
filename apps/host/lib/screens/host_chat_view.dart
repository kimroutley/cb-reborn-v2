import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_settings.dart';
import 'dashboard_view.dart';

/// A shared view for the host to see the group chat (The Lounge).
/// Used in both the Lobby (as a tab) and the Game screen (as the main feed).
class HostChatView extends ConsumerStatefulWidget {
  final GameState gameState;
  final bool showHeader;
  final bool showRoster;

  const HostChatView({
    super.key,
    required this.gameState,
    this.showHeader = true,
    this.showRoster = true,
  });

  @override
  ConsumerState<HostChatView> createState() => _HostChatViewState();
}

class _HostChatViewState extends ConsumerState<HostChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _targetRoleId;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticService.selection();

    ref.read(gameProvider.notifier).postBulletin(
          title: 'HOST',
          content: text,
          roleId: null,
          type: 'chat',
          targetRoleId: _targetRoleId,
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

  Widget _buildRosterStrip(ColorScheme scheme, TextTheme textTheme) {
    if (widget.gameState.players.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: CBSpace.x3),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.gameState.players.length,
        itemBuilder: (context, index) {
          final player = widget.gameState.players[index];
          final roleColor = player.role.id != 'unassigned'
              ? CBColors.fromHex(player.role.colorHex)
              : scheme.primary;

          return Padding(
            padding: const EdgeInsets.only(right: CBSpace.x2),
            child: CBCompactPlayerChip(
              name: player.name,
              color: roleColor,
              assetPath: player.role.id != 'unassigned'
                  ? player.role.assetPath
                  : null,
              isDisabled: !player.isAlive,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTargetRoleChips(ColorScheme scheme, TextTheme textTheme) {
    final playersWithRole = widget.gameState.players
        .where((p) => p.role.id != 'unassigned')
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (playersWithRole.isEmpty) return const SizedBox.shrink();

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
              color: scheme.primary,
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
                  setState(
                      () => _targetRoleId = selected ? null : player.role.id);
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final messages = widget.gameState.bulletinBoard;

    final ghostMessages = widget.gameState.privateMessages.entries
        .where((e) => e.value.any((m) => m.startsWith('[GHOST] ')))
        .expand((e) {
          final playerId = e.key;
          final player = widget.gameState.players.cast<Player?>().firstWhere(
                (p) => p?.id == playerId,
                orElse: () => null,
              );
          return e.value
              .where((m) => m.startsWith('[GHOST] '))
              .map((m) => BulletinEntry(
                    id: 'ghost_${m.hashCode}',
                    title: player?.name ?? 'GHOST',
                    content: m.replaceFirst('[GHOST] ', ''),
                    type: 'ghostChat',
                    timestamp: DateTime.now(),
                    roleId: player?.role.id,
                    isHostOnly: true,
                  ));
        })
        .toList();

    final allMessages = [...messages, ...ghostMessages]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          CBSectionHeader(
            title: 'THE LOUNGE',
            icon: Icons.chat_bubble_outline_rounded,
            color: scheme.primary,
          ),
          const SizedBox(height: CBSpace.x4),
        ],
        if (widget.showRoster) _buildRosterStrip(scheme, textTheme),
        Expanded(
          child: allMessages.isEmpty
              ? Center(
                  child: CBFadeSlide(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined,
                            size: 48,
                            color: scheme.onSurface.withValues(alpha: 0.1)),
                        const SizedBox(height: CBSpace.x4),
                        Text(
                          'NO MESSAGES YET',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.3),
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: CBSpace.x4, vertical: CBSpace.x4),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    BulletinFeed(
                      entries: allMessages,
                      itemBuilder: (context, i, entry, groupPosition) {
                        final isHost = entry.roleId == null &&
                            (entry.title == 'HOST' || entry.type != 'chat');

                        if (entry.type == 'system' || entry.type == 'phase') {
                          final isNight =
                              entry.content.toUpperCase().contains('NIGHT');
                          final phaseColor =
                              isNight ? scheme.secondary : scheme.primary;
                          return CBFadeSlide(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: CBSpace.x3),
                              child: CBFeedSeparator(
                                label: entry.content.toUpperCase(),
                                color: entry.type == 'system'
                                    ? scheme.error
                                    : phaseColor,
                              ),
                            ),
                          );
                        }

                        if (entry.type == 'hostIntel') {
                          final isOverride = entry.title.contains('OVERRIDE');
                          final isPhase = entry.title.contains('PHASE');
                          final intelColor = isOverride
                              ? scheme.error
                              : isPhase
                                  ? scheme.secondary
                                  : CBColors.alertOrange;
                          return CBFadeSlide(
                            child: CBMessageBubble(
                              sender: 'SYSTEM: ${entry.title.toUpperCase()}',
                              message: entry.content,
                              timestamp: entry.timestamp,
                              style: CBMessageStyle.system,
                              color: intelColor,
                              isSender: false,
                              groupPosition: groupPosition,
                            ),
                          );
                        }

                        if (entry.type == 'ghostChat') {
                          return CBFadeSlide(
                            child: CBMessageBubble(
                              sender: '${entry.title.toUpperCase()} (GHOST)',
                              message: entry.content,
                              timestamp: entry.timestamp,
                              style: CBMessageStyle.whisper, // or standard
                              color: scheme.tertiary,
                              isSender: false,
                              avatarAsset: null,
                              groupPosition: groupPosition,
                            ),
                          );
                        }

                        if (entry.type == 'dayRecap') {
                          final payload =
                              DayRecapCardPayload.tryParse(entry.content);
                          if (payload != null) {
                            return CBFadeSlide(
                              child: CBDayRecapCard(
                                title: (payload.hostTitle.isNotEmpty
                                        ? payload.hostTitle
                                        : 'DAY ${payload.day} RECAP (HOST)')
                                    .toUpperCase(),
                                bullets: payload.hostBullets
                                    .map((b) => b.toUpperCase())
                                    .toList(),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        String senderName = entry.title;
                        String? avatarAsset;
                        Color bubbleColor = scheme.primary;
                        List<Widget>? bubbleTags;

                        if (isHost) {
                          senderName = 'HOST';
                          avatarAsset = 'assets/roles/host_avatar.png';
                          final personalityId = ref
                              .watch(hostSettingsProvider)
                              .hostPersonalityId;
                          if (personalityId == 'the_ice_queen') {
                            bubbleColor = scheme.tertiary;
                          } else if (personalityId == 'protocol_9') {
                            bubbleColor = scheme.error;
                          } else {
                            bubbleColor = scheme.secondary;
                          }
                        } else if (entry.roleId != null) {
                          try {
                            final player = widget.gameState.players.firstWhere(
                              (p) => p.role.id == entry.roleId,
                            );
                            senderName = player.name;
                            avatarAsset = 'assets/roles/${player.role.id}.png';
                            bubbleColor =
                                CBColors.fromHex(player.role.colorHex);

                            final tags = <Widget>[];
                            if (!player.isAlive) {
                              tags.add(CBMiniTag(
                                  text: 'ELIMINATED', color: scheme.error));
                            }
                            if (player.isShadowBanned) {
                              tags.add(CBMiniTag(
                                  text: 'SHADOWED', color: scheme.tertiary));
                            }
                            if (player.isSinBinned) {
                              tags.add(CBMiniTag(
                                  text: 'SIN BIN', color: scheme.error));
                            }
                            if (player.isMuted) {
                              tags.add(CBMiniTag(
                                  text: 'MUTED', color: scheme.secondary));
                            }

                            if (tags.isNotEmpty) {
                              bubbleTags = tags;
                            }
                          } catch (_) {}
                        }

                        if (entry.isHostOnly && entry.type != 'hostIntel') {
                          final isSpicy = entry.title.contains('SPICY');
                          bubbleTags = [
                            ...?bubbleTags,
                            CBMiniTag(
                              text: isSpicy ? 'SPICY' : 'CLASSIFIED',
                              color: isSpicy
                                  ? scheme.error
                                  : CBColors.alertOrange,
                            ),
                          ];
                        }

                        return CBFadeSlide(
                          child: CBMessageBubble(
                            sender: senderName.toUpperCase(),
                            message: entry.content,
                            timestamp: entry.timestamp,
                            style: isHost
                                ? CBMessageStyle.narrative
                                : CBMessageStyle.standard,
                            color: bubbleColor,
                            isSender: isHost,
                            avatarAsset: avatarAsset,
                            groupPosition: groupPosition,
                            onAvatarTap: null,
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
        const SizedBox(height: CBSpace.x2),
        _buildTargetRoleChips(scheme, textTheme),
        CBChatInput(
          controller: _controller,
          onSend: _onSend,
          onAddAttachment: () {
            HapticService.selection();
            showModalBottomSheet(
              context: context,
              backgroundColor: scheme.surface,
              isScrollControlled: true,
              builder: (ctx) => ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: DashboardView(
                          gameState: widget.gameState,
                          onAction: ref.read(gameProvider.notifier).advancePhase,
                          onAddMock: ref.read(gameProvider.notifier).addBot,
                          eyesOpen: widget.gameState.eyesOpen,
                          onToggleEyes: ref.read(gameProvider.notifier).toggleEyes,
                          onBack: () {}, // Handled differently if needed
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          hintText: _targetRoleId != null ? 'Private broadcast...' : 'Host transmission...',
          prefixIcon: _targetRoleId != null ? Icon(Icons.lock_rounded, size: 16, color: scheme.error) : null,
        ),
      ],
    );
  }
}


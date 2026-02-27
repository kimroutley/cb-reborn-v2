import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_settings.dart';
import '../sheets/message_context_sheet.dart';
import 'role_detail_dialog.dart';

class HostMainFeed extends ConsumerStatefulWidget {
  final GameState gameState;

  const HostMainFeed({
    super.key,
    required this.gameState,
  });

  @override
  ConsumerState<HostMainFeed> createState() => _HostMainFeedState();
}

class _HostMainFeedState extends ConsumerState<HostMainFeed> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _onSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(gameProvider.notifier).postBulletin(
      title: 'HOST',
      content: text,
      roleId: null, // Indicates a message from the host
      type: 'chat',
    );

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Use the unified bulletinBoard for the feed
    final messages = widget.gameState.bulletinBoard;

    // Interleave Ghost Chat for Host only
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

    // Listen for new messages to trigger haptics
    ref.listen(gameProvider.select((s) => s.bulletinBoard), (previous, next) {
      if (next.isNotEmpty && next.length > (previous?.length ?? 0)) {
        final last = next.last;
        // Trigger haptics for system messages or host messages
        if (last.type == 'system' || last.roleId == null) {
          HapticService.heavy();
        } else {
          HapticService.light();
        }
        
        // Auto-scroll to show new message
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: scheme.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'NO COMMS YET',
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: allMessages.length,
            itemBuilder: (context, index) {
              final entry = allMessages[index];
              final isHost = entry.roleId == null &&
                  (entry.title == 'HOST' || entry.type != 'chat');

              if (entry.type == 'system' || entry.type == 'phase') {
                final isNight = entry.content.toUpperCase().contains('NIGHT');
                final phaseColor = isNight ? scheme.secondary : scheme.primary;
                return CBFeedSeparator(
                  label: entry.content,
                  isCinematic: true,
                  color: entry.type == 'system' ? scheme.error : phaseColor,
                );
              }

              // Host-only intel entries (actions, phase changes, overrides)
              if (entry.type == 'hostIntel') {
                final isOverride = entry.title.contains('OVERRIDE');
                final isPhase = entry.title.contains('PHASE');
                final intelColor = isOverride
                    ? scheme.error
                    : isPhase
                        ? scheme.secondary
                        : CBColors.alertOrange;
                final intelIcon = isOverride
                    ? Icons.gavel_rounded
                    : isPhase
                        ? Icons.change_circle_rounded
                        : Icons.visibility_rounded;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: CBGlassTile(
                    borderColor: intelColor.withValues(alpha: 0.25),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(intelIcon,
                            size: 14, color: intelColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: textTheme.labelSmall?.copyWith(
                                  color: intelColor,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  fontSize: 8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entry.content,
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CBMiniTag(
                          text: 'HOST ONLY',
                          color: intelColor,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Ghost Chat interweaving for Host
              if (entry.type == 'ghostChat') {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: CBGlassTile(
                    borderColor: scheme.tertiary.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.blur_on_rounded,
                            size: 14, color: scheme.tertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.title.toUpperCase()} (GHOST LOUNGE)',
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.tertiary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  fontSize: 8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entry.content,
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CBMiniTag(
                          text: 'GHOSTED',
                          color: scheme.tertiary,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Day Recap cards (host prefers spicy host version)
              if (entry.type == 'dayRecapHost' || entry.type == 'dayRecap') {
                // For host-only entries, parse host payload
                if (entry.type == 'dayRecapHost') {
                  final payload =
                      DayRecapHostPayload.tryParse(entry.content);
                  if (payload != null) {
                    return CBDayRecapCard(
                      title: payload.title.isNotEmpty
                          ? payload.title
                          : 'DAY ${payload.day} RECAP (HOST)',
                      bullets: payload.bullets,
                      accentColor: CBColors.alertOrange,
                      tagText: 'HOST ONLY',
                      tagColor: CBColors.alertOrange,
                    );
                  }
                }
                // Public recap fallback (or if host parse failed)
                final payload =
                    DayRecapCardPayload.tryParse(entry.content);
                if (payload != null) {
                  return CBDayRecapCard(
                    title: payload.title.isNotEmpty
                        ? payload.title
                        : 'DAY ${payload.day} RECAP',
                    bullets: payload.bullets,
                  );
                }
                // Final fallback
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: CBGlassTile(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Text(
                      'RECAP UNAVAILABLE',
                      style: textTheme.labelSmall?.copyWith(
                        color:
                            scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                );
              }

              // Resolve sender name (Host sees Player Name)
              String senderName = entry.title;
              String? avatarAsset;
              Color bubbleColor = scheme.primary;
              List<Widget>? bubbleTags;
              String? senderPlayerId;

              if (isHost) {
                senderName = 'HOST';
                avatarAsset = 'assets/roles/host_avatar.png'; // Assuming this exists
                final personalityId = ref.watch(hostSettingsProvider).hostPersonalityId;
                if (personalityId == 'the_ice_queen') {
                  bubbleColor = scheme.tertiary; // Colder glow
                } else if (personalityId == 'protocol_9') {
                  bubbleColor = scheme.error; // Corrupted / antagonistic AI
                } else if (personalityId == 'blood_sport_promoter') {
                  bubbleColor = scheme.secondary; // High energy
                } else {
                  bubbleColor = scheme.secondary;
                }
              } else if (entry.roleId != null) {
                try {
                  final player = widget.gameState.players.firstWhere(
                    (p) => p.role.id == entry.roleId,
                  );
                  senderPlayerId = player.id;
                  senderName = player.name; // Host sees Player's real name
                  avatarAsset = 'assets/roles/${player.role.id}.png';
                  bubbleColor = CBColors.fromHex(player.role.colorHex);

                  final tags = <Widget>[];
                  if (!player.isAlive) {
                    tags.add(CBMiniTag(text: 'DEAD', color: scheme.error));
                  }
                  if (player.isShadowBanned) {
                    tags.add(CBMiniTag(text: 'GHOSTED', color: scheme.tertiary));
                  }
                  if (player.isSinBinned) {
                    tags.add(CBMiniTag(text: 'SIN BIN', color: scheme.error));
                  }
                  if (player.isMuted) {
                    tags.add(CBMiniTag(text: 'MUTED', color: scheme.secondary));
                  }

                  if (tags.isNotEmpty) {
                    bubbleTags = tags;
                  }
                } catch (_) {
                  // Player not found, use default title
                }
              }

              // Resolve role for avatar tap
              Role? tappableRole;
              if (entry.roleId != null) {
                tappableRole = roleCatalogMap[entry.roleId];
              }

              // Tag all host-only entries (e.g. spicy recap) so the host can distinguish them
              if (entry.isHostOnly && entry.type != 'hostIntel') {
                final isSpicy = entry.title.contains('SPICY');
                bubbleTags = [
                  ...?bubbleTags,
                  CBMiniTag(
                    text: isSpicy ? 'SPICY' : 'HOST ONLY',
                    color: isSpicy ? scheme.error : CBColors.alertOrange,
                  ),
                ];
              }

              return CBMessageBubble(
                sender: senderName,
                message: entry.content,
                style: isHost ? CBMessageStyle.narrative : CBMessageStyle.standard,
                color: bubbleColor,
                isSender: isHost,
                isCompact: true,
                isPrismatic: isHost || entry.type == 'system',
                avatarAsset: avatarAsset,
                tags: bubbleTags,
                onAvatarTap: tappableRole != null
                    ? () => showRoleDetailDialog(context, tappableRole!)
                    : null,
                onTap: isHost || senderPlayerId == null ? null : () => showMessageContextActions(
                  context,
                  playerName: senderName,
                  message: entry.content,
                  onSinBin: () {
                    ref.read(gameProvider.notifier).setSinBin(senderPlayerId!, true);
                  },
                  onMute: () {
                    ref.read(gameProvider.notifier).togglePlayerMute(senderPlayerId!, true);
                  },
                ),
              );
            },
          ),
        ),

        // Narrative Entry Area
        CBPanel(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          borderColor: scheme.primary.withValues(alpha: 0.3),
          child: Row(
            children: [
              Expanded(
                child: CBTextField(
                  controller: _controller,
                  hintText: 'Send public message...',
                  textStyle: textTheme.bodyMedium!,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _onSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _onSend,
                icon: Icon(Icons.send_rounded, color: scheme.primary),
                tooltip: 'Send Message',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

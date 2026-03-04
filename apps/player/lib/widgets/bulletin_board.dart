import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../player_bridge.dart';
import '../utils/voting_awards.dart';

class CBBulletinBoard extends ConsumerStatefulWidget {
  final List<BulletinEntry> entries;

  const CBBulletinBoard({super.key, required this.entries});

  @override
  ConsumerState<CBBulletinBoard> createState() => _CBBulletinBoardState();
}

class _CBBulletinBoardState extends ConsumerState<CBBulletinBoard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(CBBulletinBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries.length > oldWidget.entries.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (widget.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(CBSpace.x8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mark_chat_unread_outlined,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'NO RECENT UPDATES',
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 24),
      itemCount: widget.entries.length,
      itemBuilder: (context, index) {
        final entry = widget.entries[index];
        final role = entry.roleId != null
            ? roleCatalog.firstWhere((r) => r.id == entry.roleId,
                orElse: () => roleCatalog.first)
            : null;

        final color =
            role != null ? CBColors.fromHex(role.colorHex) : scheme.primary;

        return CBMessageBubble(
          sender: role?.name ?? entry.title,
          message: entry.content,
          style: entry.type == 'system'
              ? CBMessageStyle.system
              : CBMessageStyle.standard,
          color: color,
          avatarAsset: role?.assetPath,
          onAvatarTap: () => _showVotingStats(context, entry.roleId),
        );
      },
    );
  }

  void _showVotingStats(BuildContext context, String? roleId) {
    if (roleId == null) return;
    final state = ref.read(playerBridgeProvider);

    PlayerSnapshot? player;
    try {
      player = state.players.firstWhere((p) => p.roleId == roleId);
    } catch (_) {
      player = null;
    }

    if (player == null) return;

    final stats = state.playerStats[player.id] ?? const PlayerVotingStats();
    final award = VotingAwards.getAward(stats);

    showThemedDialog(
      context: context,
      child: _buildAwardDialog(context, player, award, stats),
    );
  }

  Widget _buildAwardDialog(BuildContext context, PlayerSnapshot player,
      VotingAward award, PlayerVotingStats stats) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final roleColor = CBColors.fromHex(player.roleColorHex);

    final accuracy = stats.totalVotes > 0
        ? ((stats.dealerVotes / stats.totalVotes) * 100).round()
        : 0;

    return CBPanel(
      borderColor: roleColor.withValues(alpha: 0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              CBRoleAvatar(
                assetPath: 'assets/images/roles/${player.roleId}.webp',
                color: roleColor,
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name.toUpperCase(),
                      style: CBTypography.h3.copyWith(color: roleColor),
                    ),
                    Text(
                      player.roleName.toUpperCase(),
                      style: CBTypography.micro.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Award Title
          Text(
            award.title,
            style: CBTypography.h2.copyWith(
              color: CBColors.brightYellow,
              shadows: CBColors.textGlow(CBColors.brightYellow),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Icon
          Text(
            award.icon,
            style: const TextStyle(fontSize: 48),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            award.description,
            style: CBTypography.body.copyWith(color: scheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Stats
          CBPanel(
            borderColor: scheme.outline.withValues(alpha: 0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('ACCURACY', '$accuracy%'),
                _buildStatItem('VOTES', '${stats.totalVotes}'),
                _buildStatItem('HITS', '${stats.dealerVotes}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: CBTypography.h3.copyWith(color: CBColors.neonBlue),
        ),
        Text(
          label,
          style: CBTypography.micro.copyWith(
            color: CBColors.textBright.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

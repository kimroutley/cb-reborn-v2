import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/custom_drawer.dart';

class PlayerStat {
  final String playerName;
  final int gamesPlayed;
  final int gamesWon;
  final Map<String, int> rolesPlayed;

  PlayerStat({
    required this.playerName,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.rolesPlayed = const {},
  });

  double get winRate => gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0;

  String get mainRole {
    if (rolesPlayed.isEmpty) return 'N/A';
    final id =
        rolesPlayed.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return roleCatalogMap[id]?.name ?? id;
  }

  PlayerStat copyWith(
      {int? gamesPlayed, int? gamesWon, Map<String, int>? rolesPlayed}) {
    return PlayerStat(
      playerName: playerName,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      rolesPlayed: rolesPlayed ?? this.rolesPlayed,
    );
  }
}

class HallOfFameScreen extends ConsumerStatefulWidget {
  const HallOfFameScreen({super.key});

  @override
  ConsumerState<HallOfFameScreen> createState() => _HallOfFameScreenState();
}

class _HallOfFameScreenState extends ConsumerState<HallOfFameScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PlayerStat> _stats = [];
  Map<String, int> _roleUnlockCounts = const {};
  Set<String> _unlockedAwardIds = const {};
  int _recentUnlockCount = 0;
  String? _expandedRoleId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    PersistenceService? service;
    try {
      service = PersistenceService.instance;
    } catch (e) {
      debugPrint('PersistenceService init failed: $e');
    }

    final records = service?.loadGameRecords() ?? const <GameRecord>[];
    final Map<String, PlayerStat> playerStats = {};

    for (var record in records) {
      for (var player in record.roster) {
        final stat = playerStats.putIfAbsent(
            player.name, () => PlayerStat(playerName: player.name));
        final roles = Map<String, int>.from(stat.rolesPlayed);
        roles.update(player.roleId, (v) => v + 1, ifAbsent: () => 1);
        playerStats[player.name] = stat.copyWith(
          gamesPlayed: stat.gamesPlayed + 1,
          gamesWon: record.winner == player.alliance
              ? stat.gamesWon + 1
              : stat.gamesWon,
          rolesPlayed: roles,
        );
      }
    }

    if (service != null) await service.rebuildRoleAwardProgresses();
    final allProgress = service?.roleAwards.loadRoleAwardProgresses() ??
        const <PlayerRoleAwardProgress>[];
    final unlockCounts = <String, int>{};
    final unlockIds = <String>{};
    for (final p in allProgress) {
      if (!p.isUnlocked) continue;
      final def = roleAwardDefinitionById(p.awardId);
      if (def == null) continue;
      unlockIds.add(p.awardId);
      unlockCounts[def.roleId] = (unlockCounts[def.roleId] ?? 0) + 1;
    }
    final recentUnlocks =
        service?.loadRecentRoleAwardUnlocks(limit: 10) ?? const [];

    setState(() {
      _stats = playerStats.values.toList()
        ..sort((a, b) {
          final w = b.winRate.compareTo(a.winRate);
          if (w != 0) return w;
          return b.gamesWon.compareTo(a.gamesWon);
        });
      _roleUnlockCounts = unlockCounts;
      _unlockedAwardIds = unlockIds;
      _recentUnlockCount = recentUnlocks.length;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBPrismScaffold(
      title: 'HALL OF FAME',
      drawer: const CustomDrawer(),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _isLoading ? null : _loadStats,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: _isLoading
          ? const Center(child: CBBreathingSpinner())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: CBGlassTile(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    borderColor: scheme.primary.withValues(alpha: 0.3),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.4),
                            width: 1.5),
                      ),
                      labelStyle: textTheme.labelSmall!.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                      unselectedLabelStyle: textTheme.labelSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                      labelColor: scheme.primary,
                      unselectedLabelColor:
                          scheme.onSurface.withValues(alpha: 0.4),
                      tabs: [
                        const Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.leaderboard_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('RANKINGS'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.military_tech_rounded, size: 16),
                              const SizedBox(width: 8),
                              const Text('AWARDS'),
                              if (_recentUnlockCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: scheme.tertiary,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: CBColors.circleGlow(scheme.tertiary, intensity: 0.3),
                                  ),
                                  child: Text(
                                    '$_recentUnlockCount',
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
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildLeaderboard(scheme, textTheme),
                      _buildAwardsTab(scheme, textTheme),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLeaderboard(ColorScheme scheme, TextTheme textTheme) {
    if (_stats.isEmpty) {
      return Center(
        child: CBFadeSlide(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: CBGlassTile(
              isPrismatic: true,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 64, color: scheme.primary.withValues(alpha: 0.2)),
                  const SizedBox(height: 24),
                  Text(
                    'NO DATA FOUND',
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'COMPLETE A SESSION TO ENTER THE ARCHIVES.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      height: 1.4,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: scheme.primary,
      backgroundColor: scheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
        physics: const BouncingScrollPhysics(),
        itemCount: _stats.length,
        itemBuilder: (context, index) {
          final stat = _stats[index];
          return CBFadeSlide(
            delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LeaderboardCard(stat: stat, rank: index, scheme: scheme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAwardsTab(ColorScheme scheme, TextTheme textTheme) {
    final totalUnlocked = _roleUnlockCounts.values.fold(0, (sum, v) => sum + v);
    final totalAwards = allRoleAwardDefinitions().length;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: scheme.tertiary,
      backgroundColor: scheme.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
        physics: const BouncingScrollPhysics(),
        children: [
          CBFadeSlide(
            child: CBGlassTile(
              isPrismatic: totalUnlocked > 0,
              padding: const EdgeInsets.all(20),
              borderColor: scheme.tertiary.withValues(alpha: 0.4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.tertiary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.workspace_premium_rounded,
                        size: 24, color: scheme.tertiary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalUnlocked / $totalAwards UNLOCKED',
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.tertiary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value:
                                totalAwards > 0 ? totalUnlocked / totalAwards : 0,
                            minHeight: 6,
                            backgroundColor:
                                scheme.onSurface.withValues(alpha: 0.08),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(scheme.tertiary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const CBFeedSeparator(label: 'FIELD OPERATIVES'),
          const SizedBox(height: 12),
          ...roleCatalog.map((role) {
            final index = roleCatalog.indexOf(role);
            return CBFadeSlide(
              delay: Duration(milliseconds: 30 * index.clamp(0, 15)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RoleAwardCard(
                  role: role,
                  unlockCount: _roleUnlockCounts[role.id] ?? 0,
                  unlockedAwardIds: _unlockedAwardIds,
                  isExpanded: _expandedRoleId == role.id,
                  onToggle: () {
                    HapticService.selection();
                    setState(() => _expandedRoleId =
                        _expandedRoleId == role.id ? null : role.id);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final PlayerStat stat;
  final int rank;
  final ColorScheme scheme;

  const _LeaderboardCard({
    required this.stat,
    required this.rank,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (Color rankColor, IconData? icon) = switch (rank) {
      0 => (scheme.tertiary, Icons.emoji_events_rounded),
      1 => (const Color(0xFFC0C0C0), Icons.workspace_premium_rounded),
      2 => (const Color(0xFFCD7F32), Icons.military_tech_rounded),
      _ => (scheme.primary.withValues(alpha: 0.4), null),
    };

    return CBGlassTile(
      isPrismatic: rank == 0,
      borderColor: rankColor.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: 0.1),
              border: Border.all(color: rankColor.withValues(alpha: 0.4), width: 1.5),
              boxShadow: rank < 3 ? CBColors.circleGlow(rankColor, intensity: 0.2) : null,
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: rankColor, size: 22)
                  : Text(
                      '${rank + 1}',
                      style: textTheme.labelMedium?.copyWith(
                        color: rankColor,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'RobotoMono',
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.playerName.toUpperCase(),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontFamily: 'RobotoMono',
                    color: rank < 3 ? rankColor : scheme.onSurface,
                    shadows: rank < 3
                        ? CBColors.textGlow(rankColor, intensity: 0.3)
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MiniStat(label: 'TRIALS', value: '${stat.gamesPlayed}'),
                    const SizedBox(width: 16),
                    _MiniStat(label: 'CLEARED', value: '${stat.gamesWon}'),
                    const SizedBox(width: 16),
                    _MiniStat(label: 'PREFERENCE', value: stat.mainRole),
                  ],
                ),
              ],
            ),
          ),
          CBBadge(
            text: '${stat.winRate.toStringAsFixed(0)}%',
            color: rankColor,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.3),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w800,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _RoleAwardCard extends StatelessWidget {
  final Role role;
  final int unlockCount;
  final Set<String> unlockedAwardIds;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _RoleAwardCard({
    required this.role,
    required this.unlockCount,
    required this.unlockedAwardIds,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final roleColor = CBColors.fromHex(role.colorHex);
    final awards = roleAwardsForRoleId(role.id);
    final hasAwards = awards.isNotEmpty;

    return CBGlassTile(
      onTap: hasAwards ? onToggle : null,
      borderColor: roleColor.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CBRoleAvatar(
                assetPath: role.assetPath,
                color: roleColor,
                size: 40,
                breathing: isExpanded,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name.toUpperCase(),
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: roleColor,
                        shadows: CBColors.textGlow(roleColor, intensity: 0.3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (hasAwards)
                      Row(
                        children: awards.map((a) {
                          final isUnlocked =
                              unlockedAwardIds.contains(a.awardId);
                          final tc = _tierColor(a.tier, scheme);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isUnlocked
                                    ? tc
                                    : scheme.onSurface.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: isUnlocked
                                      ? tc.withValues(alpha: 0.8)
                                      : scheme.outlineVariant
                                          .withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                                boxShadow: isUnlocked
                                    ? [
                                        BoxShadow(
                                            color: tc.withValues(alpha: 0.4),
                                            blurRadius: 6)
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Text(
                        'CLASSIFIED ARCHIVES',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.3),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasAwards && unlockCount > 0)
                CBBadge(text: '$unlockCount', color: roleColor),
              if (hasAwards)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: scheme.onSurface.withValues(alpha: 0.3),
                    size: 24,
                  ),
                ),
            ],
          ),

          if (isExpanded && hasAwards) ...[
            const SizedBox(height: 20),
            Divider(color: roleColor.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 16),
            ...awards.map((award) {
              final isUnlocked = unlockedAwardIds.contains(award.awardId);
              final tc = _tierColor(award.tier, scheme);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AwardTile(
                  award: award,
                  isUnlocked: isUnlocked,
                  tierColor: tc,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Color _tierColor(RoleAwardTier tier, ColorScheme scheme) => switch (tier) {
        RoleAwardTier.rookie => scheme.primary,
        RoleAwardTier.pro => scheme.secondary,
        RoleAwardTier.legend => scheme.tertiary,
        RoleAwardTier.bonus => scheme.error,
      };
}

class _AwardTile extends StatelessWidget {
  final RoleAwardDefinition award;
  final bool isUnlocked;
  final Color tierColor;

  const _AwardTile({
    required this.award,
    required this.isUnlocked,
    required this.tierColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tierName = switch (award.tier) {
      RoleAwardTier.rookie => 'ROOKIE',
      RoleAwardTier.pro => 'VETERAN',
      RoleAwardTier.legend => 'ELITE',
      RoleAwardTier.bonus => 'SECRET',
    };

    return CBGlassTile(
      padding: const EdgeInsets.all(12),
      isPrismatic: isUnlocked,
      borderColor: isUnlocked
          ? tierColor.withValues(alpha: 0.4)
          : scheme.outlineVariant.withValues(alpha: 0.15),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? tierColor.withValues(alpha: 0.1)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border.all(
                color: isUnlocked
                    ? tierColor.withValues(alpha: 0.5)
                    : scheme.outlineVariant.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              isUnlocked
                  ? Icons.emoji_events_rounded
                  : Icons.lock_outline_rounded,
              color: isUnlocked
                  ? tierColor
                  : scheme.onSurface.withValues(alpha: 0.2),
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  award.title.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: isUnlocked
                        ? scheme.onSurface
                        : scheme.onSurface.withValues(alpha: 0.4),
                    shadows: isUnlocked
                        ? CBColors.textGlow(tierColor, intensity: 0.2)
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  award.description.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          CBMiniTag(text: tierName, color: tierColor),
        ],
      ),
    );
  }
}

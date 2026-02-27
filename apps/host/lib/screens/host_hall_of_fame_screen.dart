import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_destinations.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';

class HostHallOfFameScreen extends ConsumerStatefulWidget {
  const HostHallOfFameScreen({super.key});

  @override
  ConsumerState<HostHallOfFameScreen> createState() =>
      _HostHallOfFameScreenState();
}

class _HostHallOfFameScreenState extends ConsumerState<HostHallOfFameScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  GameStats _stats = const GameStats();
  Map<String, int> _roleUnlockCounts = const {};
  Set<String> _unlockedAwardIds = const {};
  int _recentUnlockCount = 0;
  String? _expandedRoleId;
  List<_PlayerStat> _playerStats = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    PersistenceService? service;
    try {
      service = PersistenceService.instance;
    } catch (_) {}

    final stats = service?.computeStats() ?? const GameStats();

    // Build player stats from game records
    final records = service?.loadGameRecords() ?? const <GameRecord>[];
    final Map<String, _PlayerStat> playerStatMap = {};
    for (final record in records) {
      for (final player in record.roster) {
        final stat = playerStatMap.putIfAbsent(
            player.name, () => _PlayerStat(playerName: player.name));
        final roles = Map<String, int>.from(stat.rolesPlayed);
        roles.update(player.roleId, (v) => v + 1, ifAbsent: () => 1);
        playerStatMap[player.name] = stat.copyWith(
          gamesPlayed: stat.gamesPlayed + 1,
          gamesWon: record.winner == player.alliance
              ? stat.gamesWon + 1
              : stat.gamesWon,
          rolesPlayed: roles,
        );
      }
    }
    final sortedPlayerStats = playerStatMap.values.toList()
      ..sort((a, b) {
        final w = b.winRate.compareTo(a.winRate);
        if (w != 0) return w;
        return b.gamesWon.compareTo(a.gamesWon);
      });

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

    if (mounted) {
      setState(() {
        _stats = stats;
        _playerStats = sortedPlayerStats;
        _roleUnlockCounts = unlockCounts;
        _unlockedAwardIds = unlockIds;
        _recentUnlockCount = recentUnlocks.length;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBPrismScaffold(
      title: 'HALL OF FAME',
      drawer:
          const CustomDrawer(currentDestination: HostDestination.hallOfFame),
      actions: [
        const SimulationModeBadgeAction(),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _isLoading ? null : _loadData,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: _isLoading
          ? const Center(child: CBBreathingLoader())
          : Column(
              children: [
                // Tab Bar
                CBFadeSlide(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: CBGlassTile(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      borderColor: scheme.primary.withValues(alpha: 0.3),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: scheme.primary.withValues(alpha: 0.4)),
                        ),
                        labelStyle: textTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                        unselectedLabelStyle: textTheme.labelSmall,
                        labelColor: scheme.primary,
                        unselectedLabelColor:
                            scheme.onSurface.withValues(alpha: 0.4),
                        tabs: [
                          const Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.leaderboard_rounded, size: 16),
                                SizedBox(width: 6),
                                Text('LEADERBOARD'),
                              ],
                            ),
                          ),
                          const Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.insights_rounded, size: 16),
                                SizedBox(width: 6),
                                Text('STATS'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.emoji_events_rounded,
                                    size: 16),
                                const SizedBox(width: 6),
                                const Text('AWARDS'),
                                if (_recentUnlockCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: scheme.tertiary,
                                      borderRadius: BorderRadius.circular(8),
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
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: CBFadeSlide(
                    delay: const Duration(milliseconds: 100),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLeaderboardTab(scheme, textTheme),
                        _buildOverviewTab(scheme, textTheme),
                        _buildAwardsTab(scheme, textTheme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ─── LEADERBOARD TAB ──────────────────────────────────────

  Widget _buildLeaderboardTab(ColorScheme scheme, TextTheme textTheme) {
    if (_playerStats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CBGlassTile(
            isPrismatic: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 48, color: scheme.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'NO RECORDS YET',
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Host a complete game to populate the leaderboard.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _playerStats.length,
        itemBuilder: (context, index) {
          final stat = _playerStats[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LeaderboardCard(stat: stat, rank: index, scheme: scheme),
          );
        },
      ),
    );
  }

  // ─── OVERVIEW TAB ──────────────────────────────────────────

  Widget _buildOverviewTab(ColorScheme scheme, TextTheme textTheme) {
    final totalUnlocks = _roleUnlockCounts.values.fold(0, (sum, v) => sum + v);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Quick stat cards
          Row(
            children: [
              Expanded(
                child: _QuickStatCard(
                  icon: Icons.videogame_asset_rounded,
                  value: '${_stats.totalGames}',
                  label: 'GAMES HOSTED',
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickStatCard(
                  icon: Icons.emoji_events_rounded,
                  value: '$totalUnlocks',
                  label: 'AWARDS WON',
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickStatCard(
                  icon: Icons.people_alt_rounded,
                  value: '${_roleUnlockCounts.keys.length}',
                  label: 'ROLES TRACKED',
                  color: scheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // How awards work explainer
          CBGlassTile(
            borderColor: scheme.secondary.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: scheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'HOW AWARDS WORK',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.secondary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ExplainerRow(
                  color: scheme.primary,
                  tier: 'ROOKIE',
                  desc: 'Play your first game as any role.',
                ),
                _ExplainerRow(
                  color: scheme.secondary,
                  tier: 'PRO',
                  desc: 'Win or survive multiple games in a role.',
                ),
                _ExplainerRow(
                  color: scheme.tertiary,
                  tier: 'LEGEND',
                  desc: 'Master a role with consistent victories.',
                ),
                _ExplainerRow(
                  color: scheme.error,
                  tier: 'BONUS',
                  desc: 'Grind deep with extended play and survival records.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Every role has awards
          CBGlassTile(
            borderColor: scheme.primary.withValues(alpha: 0.2),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 16, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'ALL 22 ROLES HAVE AWARDS',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Every role in Club Blackout has 5 unique awards across 4 tiers. '
                  'Unlock them by playing, surviving, and winning as each role. '
                  'Tap the Awards tab to browse the full catalog.',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── AWARDS TAB ───────────────────────────────────────────

  Widget _buildAwardsTab(ColorScheme scheme, TextTheme textTheme) {
    final totalUnlocked = _roleUnlockCounts.values.fold(0, (sum, v) => sum + v);
    final totalAwards = allRoleAwardDefinitions().length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Progress bar
          CBGlassTile(
            isPrismatic: totalUnlocked > 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            borderColor: scheme.tertiary.withValues(alpha: 0.4),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded,
                    size: 22, color: scheme.tertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalUnlocked / $totalAwards AWARDS UNLOCKED',
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.tertiary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value:
                              totalAwards > 0 ? totalUnlocked / totalAwards : 0,
                          minHeight: 4,
                          backgroundColor:
                              scheme.onSurface.withValues(alpha: 0.1),
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
          const SizedBox(height: 16),

          // Role award cards (reuse same pattern)
          ...roleCatalog.map((role) {
            final roleColor = CBColors.fromHex(role.colorHex);
            final awards = roleAwardsForRoleId(role.id);
            final unlockCount = _roleUnlockCounts[role.id] ?? 0;
            final isExpanded = _expandedRoleId == role.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CBGlassTile(
                onTap: awards.isNotEmpty
                    ? () => setState(
                        () => _expandedRoleId = isExpanded ? null : role.id)
                    : null,
                borderColor: roleColor.withValues(alpha: 0.4),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CBRoleAvatar(
                          assetPath: role.assetPath,
                          color: roleColor,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role.name.toUpperCase(),
                                style: textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  shadows: CBColors.textGlow(roleColor,
                                      intensity: 0.3),
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (awards.isNotEmpty)
                                Row(
                                  children: awards.map((a) {
                                    final u =
                                        _unlockedAwardIds.contains(a.awardId);
                                    final tc = _tierColor(a.tier, scheme);
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: u
                                              ? tc
                                              : scheme.onSurface
                                                  .withValues(alpha: 0.1),
                                          border: Border.all(
                                            color: u
                                                ? tc.withValues(alpha: 0.8)
                                                : scheme.outlineVariant
                                                    .withValues(alpha: 0.2),
                                          ),
                                          boxShadow: u
                                              ? [
                                                  BoxShadow(
                                                      color: tc.withValues(
                                                          alpha: 0.4),
                                                      blurRadius: 4)
                                                ]
                                              : null,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                )
                              else
                                Text(
                                  'AWARDS COMING SOON',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 8,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (awards.isNotEmpty && unlockCount > 0)
                          CBBadge(text: '$unlockCount', color: roleColor),
                        if (awards.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: scheme.onSurface.withValues(alpha: 0.3),
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    if (isExpanded && awards.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ...awards.map((award) {
                        final isU = _unlockedAwardIds.contains(award.awardId);
                        final tc = _tierColor(award.tier, scheme);
                        final tierName = switch (award.tier) {
                          RoleAwardTier.rookie => 'ROOKIE',
                          RoleAwardTier.pro => 'PRO',
                          RoleAwardTier.legend => 'LEGEND',
                          RoleAwardTier.bonus => 'BONUS',
                        };

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CBGlassTile(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            isPrismatic: isU,
                            borderColor: isU
                                ? tc.withValues(alpha: 0.5)
                                : scheme.outlineVariant.withValues(alpha: 0.15),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isU
                                        ? tc.withValues(alpha: 0.15)
                                        : scheme.surfaceContainerHighest,
                                    border: Border.all(
                                      color: isU
                                          ? tc.withValues(alpha: 0.6)
                                          : scheme.outlineVariant
                                              .withValues(alpha: 0.2),
                                    ),
                                    boxShadow: isU
                                        ? [
                                            BoxShadow(
                                                color:
                                                    tc.withValues(alpha: 0.2),
                                                blurRadius: 6)
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    isU
                                        ? Icons.emoji_events_rounded
                                        : Icons.lock_outline_rounded,
                                    color: isU
                                        ? tc
                                        : scheme.onSurface
                                            .withValues(alpha: 0.15),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        award.title.toUpperCase(),
                                        style: textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                          color: isU
                                              ? scheme.onSurface
                                              : scheme.onSurface
                                                  .withValues(alpha: 0.35),
                                          shadows: isU
                                              ? CBColors.textGlow(tc,
                                                  intensity: 0.2)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        award.description,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.45),
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CBMiniTag(text: tierName, color: tc),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            );
          }),
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

// ─── PLAYER STAT MODEL ─────────────────────────────────────

class _PlayerStat {
  final String playerName;
  final int gamesPlayed;
  final int gamesWon;
  final Map<String, int> rolesPlayed;

  _PlayerStat({
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

  _PlayerStat copyWith({
    int? gamesPlayed,
    int? gamesWon,
    Map<String, int>? rolesPlayed,
  }) {
    return _PlayerStat(
      playerName: playerName,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      rolesPlayed: rolesPlayed ?? this.rolesPlayed,
    );
  }
}

// ─── LEADERBOARD CARD ──────────────────────────────────────

class _LeaderboardCard extends StatelessWidget {
  final _PlayerStat stat;
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
      1 => (CBColors.coolGrey, Icons.military_tech_rounded),
      2 => (scheme.secondary, Icons.military_tech_outlined),
      _ => (scheme.primary.withValues(alpha: 0.5), null),
    };

    return CBGlassTile(
      isPrismatic: rank == 0,
      borderColor: rankColor.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: 0.15),
              border: Border.all(color: rankColor.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: rankColor, size: 20)
                  : Text(
                      '#${rank + 1}',
                      style: textTheme.labelSmall?.copyWith(
                        color: rankColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.playerName.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    shadows: rank < 3
                        ? CBColors.textGlow(rankColor, intensity: 0.3)
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MiniStat(label: 'PLAYED', value: '${stat.gamesPlayed}'),
                    const SizedBox(width: 16),
                    _MiniStat(label: 'WON', value: '${stat.gamesWon}'),
                    const SizedBox(width: 16),
                    _MiniStat(label: 'MAIN', value: stat.mainRole),
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
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 7,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          value,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── HELPER WIDGETS ────────────────────────────────────────

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CBGlassTile(
      isPrismatic: true,
      borderColor: color.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
              fontFamily: 'RobotoMono',
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1.0,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplainerRow extends StatelessWidget {
  final Color color;
  final String tier;
  final String desc;

  const _ExplainerRow({
    required this.color,
    required this.tier,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CBMiniTag(text: tier, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              desc,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

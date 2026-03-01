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
    } catch (e) {
      debugPrint('PersistenceService init failed: $e');
    }

    final stats = service?.computeStats() ?? const GameStats();

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
          tooltip: 'REFRESH DATA',
          onPressed: _isLoading ? null : () {
            HapticService.selection();
            _loadData();
          },
          icon: const Icon(Icons.refresh_rounded, size: 24),
        ),
      ],
      body: _isLoading
          ? const Center(child: CBBreathingSpinner())
          : Column(
              children: [
                CBFadeSlide(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
                    child: CBGlassTile(
                      padding: const EdgeInsets.symmetric(
                          horizontal: CBSpace.x2, vertical: CBSpace.x2),
                      borderColor: scheme.primary.withValues(alpha: 0.3),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(CBRadius.sm),
                          border: Border.all(
                              color: scheme.primary.withValues(alpha: 0.4), width: 1.5),
                        ),
                        labelStyle: textTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 10,
                        ),
                        unselectedLabelStyle: textTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          fontSize: 10,
                        ),
                        labelColor: scheme.primary,
                        unselectedLabelColor:
                            scheme.onSurface.withValues(alpha: 0.4),
                        tabs: [
                          const Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.leaderboard_rounded, size: 18),
                                SizedBox(width: CBSpace.x2),
                                Text('RANKINGS'),
                              ],
                            ),
                          ),
                          const Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.insights_rounded, size: 18),
                                SizedBox(width: CBSpace.x2),
                                Text('OVERVIEW'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.military_tech_rounded,
                                    size: 18),
                                const SizedBox(width: CBSpace.x2),
                                const Text('AWARDS'),
                                if (_recentUnlockCount > 0) ...[
                                  const SizedBox(width: CBSpace.x2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: CBSpace.x2, vertical: CBSpace.x1),
                                    decoration: BoxDecoration(
                                      color: scheme.tertiary,
                                      borderRadius: BorderRadius.circular(CBRadius.xs),
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
                const SizedBox(height: CBSpace.x2),
                Expanded(
                  child: CBFadeSlide(
                    delay: const Duration(milliseconds: 100),
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
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

  Widget _buildLeaderboardTab(ColorScheme scheme, TextTheme textTheme) {
    if (_playerStats.isEmpty) {
      return Center(
        child: CBFadeSlide(
          child: Padding(
            padding: const EdgeInsets.all(CBSpace.x8),
            child: CBGlassTile(
              isPrismatic: true,
              padding: const EdgeInsets.all(CBSpace.x8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.leaderboard_outlined,
                      size: CBSpace.x16, color: scheme.primary.withValues(alpha: 0.2)),
                  const SizedBox(height: CBSpace.x4),
                  Text(
                    'NO OPERATIVE DATA',
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: CBSpace.x2),
                  Text(
                    'HOST A SESSION TO POPULATE THE RANKINGS.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                        height: 1.4,
                        letterSpacing: 0.5,
                        fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: scheme.primary,
      backgroundColor: scheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, CBSpace.x12),
        physics: const BouncingScrollPhysics(),
        itemCount: _playerStats.length,
        itemBuilder: (context, index) {
          final stat = _playerStats[index];
          return CBFadeSlide(
            delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: CBSpace.x3),
              child: _LeaderboardCard(stat: stat, rank: index, scheme: scheme, textTheme: textTheme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(ColorScheme scheme, TextTheme textTheme) {
    final totalUnlocks = _roleUnlockCounts.values.fold(0, (sum, v) => sum + v);
    final totalAwardsDefined = allRoleAwardDefinitions().length;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: scheme.tertiary,
      backgroundColor: scheme.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, CBSpace.x12),
        physics: const BouncingScrollPhysics(),
        children: [
          CBFadeSlide(
            child: Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.videogame_asset_rounded,
                    value: '${_stats.totalGames}',
                    label: 'MISSIONS HOSTED',
                    color: scheme.primary,
                    textTheme: textTheme,
                  ),
                ),
                const SizedBox(width: CBSpace.x3),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.military_tech_rounded,
                    value: '$totalUnlocks',
                    label: 'AWARDS EARNED',
                    color: scheme.secondary,
                    textTheme: textTheme,
                  ),
                ),
                const SizedBox(width: CBSpace.x3),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.people_alt_rounded,
                    value: '${_playerStats.length}',
                    label: 'UNIQUE OPERATIVES',
                    color: scheme.tertiary,
                    textTheme: textTheme,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: CBSpace.x6),
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: CBPanel(
              borderColor: scheme.secondary.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(CBSpace.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CBSectionHeader(
                    title: 'AWARD PROTOCOLS',
                    icon: Icons.info_outline_rounded,
                    color: scheme.secondary,
                  ),
                  const SizedBox(height: CBSpace.x4),
                  _ExplainerRow(
                    color: scheme.primary,
                    tier: 'ROOKIE',
                    desc: 'ENGAGE IN YOUR FIRST MISSION WITH ANY ROLE.',
                    textTheme: textTheme,
                  ),
                  _ExplainerRow(
                    color: scheme.secondary,
                    tier: 'VETERAN',
                    desc: 'ACHIEVE MULTIPLE VICTORIES OR SURVIVALS IN A ROLE.',
                    textTheme: textTheme,
                  ),
                  _ExplainerRow(
                    color: scheme.tertiary,
                    tier: 'ELITE',
                    desc: 'DEMONSTRATE MASTERY WITH CONSISTENT ROLE SUCCESS.',
                    textTheme: textTheme,
                  ),
                  _ExplainerRow(
                    color: scheme.error,
                    tier: 'CLASSIFIED',
                    desc: 'UNCOVER HIDDEN ACHIEVEMENTS THROUGH EXTENSIVE PLAY.',
                    textTheme: textTheme,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: CBSpace.x6),
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: CBPanel(
              borderColor: scheme.primary.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(CBSpace.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CBSectionHeader(
                    title: 'ROLE ARCHIVES',
                    icon: Icons.assignment_ind_rounded,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: CBSpace.x4),
                  Text(
                    'ALL ${allRoleAwardDefinitions().length} ROLES IN CLUB BLACKOUT HAVE ${allRoleAwardDefinitions().length ~/ roleCatalog.length} UNIQUE ACCOLADES ACROSS 4 TIERS. '
                    'OPERATIVES UNLOCK THEM BY PLAYING, SURVIVING, AND WINNING AS EACH ROLE. '
                    'ACCESS THE AWARDS TAB FOR THE FULL CATALOG.'.toUpperCase(),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      height: 1.6,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwardsTab(ColorScheme scheme, TextTheme textTheme) {
    final totalUnlocked = _roleUnlockCounts.values.fold(0, (sum, v) => sum + v);
    final totalAwards = allRoleAwardDefinitions().length;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: scheme.tertiary,
      backgroundColor: scheme.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, CBSpace.x12),
        physics: const BouncingScrollPhysics(),
        children: [
          CBFadeSlide(
            child: CBGlassTile(
              isPrismatic: totalUnlocked > 0,
              padding: const EdgeInsets.all(CBSpace.x5),
              borderColor: scheme.tertiary.withValues(alpha: 0.4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(CBSpace.x3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.tertiary.withValues(alpha: 0.1),
                    ),
                    child: Icon(Icons.military_tech_rounded,
                        size: 24, color: scheme.tertiary),
                  ),
                  const SizedBox(width: CBSpace.x4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalUnlocked / $totalAwards ARCHIVES UNLOCKED'.toUpperCase(),
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.tertiary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontFamily: 'RobotoMono',
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: CBSpace.x2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(CBRadius.xs),
                          child: LinearProgressIndicator(
                            value:
                                totalAwards > 0 ? totalUnlocked / totalAwards : 0,
                            minHeight: CBSpace.x2,
                            backgroundColor:
                                scheme.onSurface.withValues(alpha: 0.08),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(scheme.tertiary.withValues(alpha: 0.7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: CBSpace.x6),
          const CBFeedSeparator(label: 'OPERATIVE ROLES'),
          const SizedBox(height: CBSpace.x4),

          if (roleCatalog.isEmpty)
            CBFadeSlide(
              delay: const Duration(milliseconds: 100),
              child: CBPanel(
                padding: const EdgeInsets.all(CBSpace.x6),
                borderColor: scheme.outlineVariant.withValues(alpha: 0.2),
                child: Column(
                  children: [
                    Icon(Icons.assignment_ind_outlined,
                        size: CBSpace.x16, color: scheme.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: CBSpace.x4),
                    Text(
                      "NO ROLE ARCHIVES AVAILABLE.".toUpperCase(),
                      textAlign: TextAlign.center,
                      style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                    ),
                    const SizedBox(height: CBSpace.x2),
                    Text(
                      'ENSURE GAME DATA IS LOADED AND ROLES ARE DEFINED.'.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.3),
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...roleCatalog.asMap().entries.map((entry) {
              final index = entry.key;
              final role = entry.value;
              final roleColor = CBColors.fromHex(role.colorHex);
              final awards = roleAwardsForRoleId(role.id);
              final unlockCount = _roleUnlockCounts[role.id] ?? 0;
              final isExpanded = _expandedRoleId == role.id;

              return CBFadeSlide(
                delay: Duration(milliseconds: 50 * index.clamp(0, 15) + 100),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: CBSpace.x3),
                  child: CBGlassTile(
                    onTap: awards.isNotEmpty
                        ? () {
                          HapticService.selection();
                          setState(
                              () => _expandedRoleId = isExpanded ? null : role.id);
                        }
                        : null,
                    borderColor: roleColor.withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(CBSpace.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CBRoleAvatar(
                              assetPath: role.assetPath,
                              color: roleColor,
                              size: 44,
                              breathing: isExpanded,
                            ),
                            const SizedBox(width: CBSpace.x3),
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
                                      shadows: CBColors.textGlow(roleColor,
                                          intensity: 0.3),
                                    ),
                                  ),
                                  const SizedBox(height: CBSpace.x1),
                                  if (awards.isNotEmpty)
                                    Row(
                                      children: awards.map((a) {
                                        final u =
                                            _unlockedAwardIds.contains(a.awardId);
                                        final tc = _tierColor(a.tier, scheme);
                                        return Padding(
                                          padding: const EdgeInsets.only(right: CBSpace.x1),
                                          child: Container(
                                            width: CBSpace.x2 + 2,
                                            height: CBSpace.x2 + 2,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: u
                                                  ? tc
                                                  : scheme.onSurface
                                                      .withValues(alpha: 0.05),
                                              border: Border.all(
                                                color: u
                                                    ? tc.withValues(alpha: 0.8)
                                                    : scheme.outlineVariant
                                                        .withValues(alpha: 0.2),
                                                width: 1.5,
                                              ),
                                              boxShadow: u
                                                  ? [
                                                      BoxShadow(
                                                          color: tc.withValues(
                                                              alpha: 0.4),
                                                          blurRadius: CBSpace.x1)
                                                    ]
                                                  : null,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  else
                                    Text(
                                      'CLASSIFIED ARCHIVE'.toUpperCase(),
                                      style: textTheme.labelSmall?.copyWith(
                                        color: scheme.onSurface.withValues(alpha: 0.3),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (awards.isNotEmpty && unlockCount > 0)
                              CBBadge(text: '$unlockCount', color: roleColor, icon: Icons.military_tech_rounded),
                            if (awards.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: CBSpace.x2),
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
                        if (isExpanded && awards.isNotEmpty) ...[
                          const SizedBox(height: CBSpace.x4),
                          Divider(color: roleColor.withValues(alpha: 0.1), height: 1),
                          const SizedBox(height: CBSpace.x4),
                          ...awards.map((award) {
                            final isU = _unlockedAwardIds.contains(award.awardId);
                            final tc = _tierColor(award.tier, scheme);
                            final tierName = switch (award.tier) {
                              RoleAwardTier.rookie => 'ROOKIE',
                              RoleAwardTier.pro => 'VETERAN',
                              RoleAwardTier.legend => 'ELITE',
                              RoleAwardTier.bonus => 'CLASSIFIED',
                            };

                            return Padding(
                              padding: const EdgeInsets.only(bottom: CBSpace.x3),
                              child: CBGlassTile(
                                padding: const EdgeInsets.all(CBSpace.x3),
                                isPrismatic: isU,
                                borderColor: isU
                                    ? tc.withValues(alpha: 0.5)
                                    : scheme.outlineVariant.withValues(alpha: 0.15),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isU
                                            ? tc.withValues(alpha: 0.15)
                                            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        border: Border.all(
                                          color: isU
                                              ? tc.withValues(alpha: 0.6)
                                              : scheme.outlineVariant
                                                  .withValues(alpha: 0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        isU
                                            ? Icons.emoji_events_rounded
                                            : Icons.lock_outline_rounded,
                                        color: isU
                                            ? tc
                                            : scheme.onSurface
                                                .withValues(alpha: 0.2),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: CBSpace.x3),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            award.title.toUpperCase(),
                                            style: textTheme.labelSmall?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.0,
                                              color: isU
                                                  ? scheme.onSurface
                                                  : scheme.onSurface
                                                      .withValues(alpha: 0.4),
                                              shadows: isU
                                                  ? CBColors.textGlow(tc,
                                                      intensity: 0.2)
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(height: CBSpace.x1),
                                          Text(
                                            award.description.toUpperCase(),
                                            style: textTheme.labelSmall?.copyWith(
                                              color: scheme.onSurface
                                                  .withValues(alpha: 0.5),
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
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
  final TextTheme textTheme;

  const _LeaderboardCard({
    required this.stat,
    required this.rank,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final (Color rankColor, IconData? icon) = switch (rank) {
      0 => (scheme.tertiary, Icons.emoji_events_rounded),
      1 => (const Color(0xFFC0C0C0), Icons.workspace_premium_rounded),
      2 => (const Color(0xFFCD7F32), Icons.military_tech_rounded),
      _ => (scheme.primary.withValues(alpha: 0.4), null),
    };

    return CBGlassTile(
      isPrismatic: rank == 0,
      borderColor: rankColor.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(CBSpace.x4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: 0.1),
              border: Border.all(color: rankColor.withValues(alpha: 0.4), width: 2),
              boxShadow: rank < 3 ? CBColors.circleGlow(rankColor, intensity: 0.3) : null,
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: rankColor, size: 24)
                  : Text(
                      '${rank + 1}',
                      style: textTheme.headlineSmall?.copyWith(
                        color: rankColor,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'RobotoMono',
                        shadows: CBColors.textGlow(rankColor, intensity: 0.2),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: CBSpace.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.playerName.toUpperCase(),
                  style: textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontFamily: 'RobotoMono',
                    color: rank < 3 ? rankColor : scheme.onSurface,
                    shadows: rank < 3
                        ? CBColors.textGlow(rankColor, intensity: 0.3)
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CBSpace.x2),
                Row(
                  children: [
                    _MiniStat(label: 'MISSIONS', value: '${stat.gamesPlayed}', scheme: scheme, textTheme: textTheme),
                    const SizedBox(width: CBSpace.x4),
                    _MiniStat(label: 'CLEARED', value: '${stat.gamesWon}', scheme: scheme, textTheme: textTheme),
                    const SizedBox(width: CBSpace.x4),
                    _MiniStat(label: 'PREFERENCE', value: stat.mainRole, scheme: scheme, textTheme: textTheme),
                  ],
                ),
              ],
            ),
          ),
          CBBadge(
            text: '${stat.winRate.toStringAsFixed(0)}%',
            color: rankColor,
            icon: Icons.track_changes_rounded,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: CBSpace.x1),
        Text(
          value.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.5,
            fontFamily: 'RobotoMono',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final TextTheme textTheme;

  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CBGlassTile(
      isPrismatic: true,
      borderColor: color.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(CBSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(CBSpace.x2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: CBSpace.x3),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontFamily: 'RobotoMono',
              shadows: CBColors.textGlow(color, intensity: 0.3),
            ),
          ),
          const SizedBox(height: CBSpace.x2),
          Text(
            label.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1.0,
              fontSize: 9,
              fontWeight: FontWeight.w700,
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
  final TextTheme textTheme;

  const _ExplainerRow({
    required this.color,
    required this.tier,
    required this.desc,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: CBSpace.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: CBSpace.x3,
            height: CBSpace.x3,
            margin: const EdgeInsets.only(top: CBSpace.x1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: CBSpace.x1),
              ],
            ),
          ),
          const SizedBox(width: CBSpace.x3),
          CBMiniTag(text: tier.toUpperCase(), color: color),
          const SizedBox(width: CBSpace.x3),
          Expanded(
            child: Text(
              desc.toUpperCase(),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
                height: 1.4,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

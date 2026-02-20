import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/custom_drawer.dart';

// Reusing PlayerStat definition from Host app for consistency
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

  double get winPercentage =>
      gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0;

  String get mostPlayedRole {
    if (rolesPlayed.isEmpty) {
      return 'N/A';
    }
    final roleId =
        rolesPlayed.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final role = roleCatalogMap[roleId];
    return role?.name ?? roleId;
  }

  PlayerStat copyWith({
    int? gamesPlayed,
    int? gamesWon,
    Map<String, int>? rolesPlayed,
  }) {
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

class _HallOfFameScreenState extends ConsumerState<HallOfFameScreen> {
  List<PlayerStat> _stats = [];
  Map<String, int> _roleUnlockCounts = const {};
  Set<String> _unlockedAwardIds = const {};
  int _recentUnlockCount = 0;
  bool _persistenceReady = true;
  String? _selectedAwardRoleId;
  RoleAwardTier? _selectedAwardTier;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    PersistenceService? service;
    try {
      service = PersistenceService.instance;
    } catch (_) {
      service = null;
    }

    final records = service?.loadGameRecords() ?? const <GameRecord>[];
    final Map<String, PlayerStat> playerStats = {};

    for (var record in records) {
      for (var player in record.roster) {
        final stat = playerStats.putIfAbsent(
            player.name, () => PlayerStat(playerName: player.name));

        final roles = Map<String, int>.from(stat.rolesPlayed);
        roles.update(player.roleId, (value) => value + 1, ifAbsent: () => 1);

        playerStats[player.name] = stat.copyWith(
          gamesPlayed: stat.gamesPlayed + 1,
          gamesWon: record.winner == player.alliance
              ? stat.gamesWon + 1
              : stat.gamesWon,
          rolesPlayed: roles,
        );
      }
    }

    if (service != null) {
      await service.rebuildRoleAwardProgresses();
    }
    final allProgress = service?.loadRoleAwardProgresses() ??
        const <PlayerRoleAwardProgress>[];
    final unlockedCounts = <String, int>{};
    final unlockedAwardIds = <String>{};
    for (final progress in allProgress) {
      if (!progress.isUnlocked) {
        continue;
      }
      final definition = roleAwardDefinitionById(progress.awardId);
      if (definition == null) {
        continue;
      }
      unlockedAwardIds.add(progress.awardId);
      unlockedCounts[definition.roleId] =
          (unlockedCounts[definition.roleId] ?? 0) + 1;
    }

    final recentUnlocks =
        service?.loadRecentRoleAwardUnlocks(limit: 10) ??
            const <PlayerRoleAwardProgress>[];

    setState(() {
      _stats = playerStats.values.toList()
        ..sort(_comparePlayerStats);
      _roleUnlockCounts = unlockedCounts;
      _unlockedAwardIds = unlockedAwardIds;
      _recentUnlockCount = recentUnlocks.length;
      _persistenceReady = service != null;
      _isLoading = false;
    });
  }

  String _tierLabel(RoleAwardTier tier) {
    switch (tier) {
      case RoleAwardTier.rookie:
        return 'Rookie';
      case RoleAwardTier.pro:
        return 'Pro';
      case RoleAwardTier.legend:
        return 'Legend';
      case RoleAwardTier.bonus:
        return 'Bonus';
    }
  }

  int _comparePlayerStats(PlayerStat a, PlayerStat b) {
    final winPct = b.winPercentage.compareTo(a.winPercentage);
    if (winPct != 0) return winPct;

    final wins = b.gamesWon.compareTo(a.gamesWon);
    if (wins != 0) return wins;

    final played = b.gamesPlayed.compareTo(a.gamesPlayed);
    if (played != 0) return played;

    return a.playerName.toLowerCase().compareTo(b.playerName.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final awardCoverage = const RoleAwardProgressService().buildCoverageSummary();
    final visibleRoles = roleCatalog
        .where((role) {
          if (_selectedAwardRoleId != null && role.id != _selectedAwardRoleId) {
            return false;
          }
          if (_selectedAwardTier == null) {
            return true;
          }
          return roleAwardsForRoleId(role.id)
              .any((definition) => definition.tier == _selectedAwardTier);
        })
        .toList(growable: false);

    return CBPrismScaffold(
      title: 'HALL OF FAME',
      drawer: const CustomDrawer(),
      actions: [
        IconButton(
          tooltip: 'Refresh Hall of Fame',
          onPressed: _isLoading ? null : _loadStats,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: _isLoading
          ? const Center(child: CBBreathingLoader())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 16, bottom: 32, left: 16, right: 16),
                children: [
                  if (_stats.isEmpty)
                    CBGlassTile(
                      isPrismatic: true,
                      borderColor: scheme.primary.withValues(alpha: 0.4),
                      child: Text(
                        'No game records found. Play a game to enter the Hall of Fame!',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  else
                    ...List.generate(
                      _stats.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildProfileCard(_stats[index], index, scheme),
                      ),
                    ),
                  const SizedBox(height: 12),
                  CBSectionHeader(
                    title: 'ROLE AWARDS',
                    icon: Icons.emoji_events_rounded,
                    color: scheme.primary,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Role ladders finalized: ${awardCoverage.rolesWithDefinitions}/${awardCoverage.totalRoles} • Recent unlocks: $_recentUnlockCount',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  if (!_persistenceReady)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Career records are not initialized yet. Showing award catalog only.',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  _buildRoleAwardFilters(scheme, visibleRoles.length),
                  const SizedBox(height: 16),
                  ...visibleRoles
                      .map((role) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildRoleAwardCard(role, scheme),
                          )),
                ],
              ),
            ),
    );
  }

  Widget _buildRoleAwardFilters(ColorScheme scheme, int visibleRoleCount) {
    final roleOptions = [...roleCatalog]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FILTERS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: scheme.primary,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedAwardRoleId,
                  decoration: const InputDecoration(
                    labelText: 'ROLE',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('ALL ROLES'),
                    ),
                    ...roleOptions.map(
                      (role) => DropdownMenuItem<String?>(
                        value: role.id,
                        child: Text(role.name.toUpperCase()),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAwardRoleId = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<RoleAwardTier?>(
                  initialValue: _selectedAwardTier,
                  decoration: const InputDecoration(
                    labelText: 'TIER',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<RoleAwardTier?>(
                      value: null,
                      child: Text('ALL TIERS'),
                    ),
                    ...RoleAwardTier.values.map(
                      (tier) => DropdownMenuItem<RoleAwardTier?>(
                        value: tier,
                        child: Text(_tierLabel(tier).toUpperCase()),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAwardTier = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'SHOWING $visibleRoleCount OF ${roleCatalog.length} ROLES.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleAwardCard(Role role, ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    final hasFinalized = hasFinalizedRoleAwards(role.id);
    final roleAwardDefinitions = roleAwardsForRoleId(role.id)
        .where(
          (definition) =>
              _selectedAwardTier == null ||
              definition.tier == _selectedAwardTier,
        )
        .toList(growable: false);
    final placeholderText =
        roleAwardPlaceholderRegistry[role.id] ?? awardsComingSoonLabel;
    final unlockCount = _roleUnlockCounts[role.id] ?? 0;
    final visibleUnlockCount = roleAwardDefinitions
        .where((definition) => _unlockedAwardIds.contains(definition.awardId))
        .length;
    final descriptor = hasFinalized
        ? roleAwardDefinitions.isEmpty
            ? 'NO AWARDS MATCH CURRENT FILTERS.'
            : '${roleAwardDefinitions.length} AWARDS • $visibleUnlockCount UNLOCKS (TOTAL: $unlockCount)'
        : placeholderText.toUpperCase();

    final roleColor = CBColors.fromHex(role.colorHex);

    return CBGlassTile(
      onTap: () {
        // Future: Navigation to detailed role award ladder
      },
      borderColor: roleColor.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CBRoleAvatar(
                assetPath: role.assetPath,
                color: roleColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name.toUpperCase(),
                      style: textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        shadows: CBColors.textGlow(roleColor, intensity: 0.3),
                      ),
                    ),
                    Text(
                      role.type.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: roleColor.withValues(alpha: 0.7),
                        fontSize: 9,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasFinalized && unlockCount > 0)
                CBBadge(text: '$unlockCount', color: roleColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            descriptor,
            style: textTheme.labelSmall?.copyWith(
              color: hasFinalized ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(PlayerStat stat, int index, ColorScheme scheme) {
    Color rankColor;
    IconData? rankIcon;

    switch (index) {
      case 0:
        rankColor = scheme.tertiary; // Gold/Yellow for 1st place
        rankIcon = Icons.emoji_events_rounded;
        break;
      case 1:
        rankColor = CBColors.coolGrey; // Silver for 2nd place
        rankIcon = Icons.military_tech_rounded;
        break;
      case 2:
        rankColor = scheme.secondary; // Bronze/Secondary for 3rd place
        rankIcon = Icons.military_tech_outlined;
        break;
      default:
        rankColor = scheme.primary.withValues(alpha: 0.55);
    }

    return CBGlassTile(
      borderColor: rankColor.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (rankIcon != null)
                Icon(rankIcon, color: rankColor, size: 24, shadows: [
                  Shadow(color: rankColor.withValues(alpha: 0.5), blurRadius: 8)
                ]),
              if (rankIcon != null) const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '#${index + 1} ${stat.playerName.toUpperCase()}',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              CBBadge(
                text: '${stat.winPercentage.toStringAsFixed(0)}% WIN RATE',
                color: rankColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCompactStat('GAMES', '${stat.gamesPlayed}', scheme),
              const SizedBox(width: 24),
              _buildCompactStat('WINS', '${stat.gamesWon}', scheme),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCompactStat('MAIN', stat.mostPlayedRole.toUpperCase(), scheme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, String value, ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: 8,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          value,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

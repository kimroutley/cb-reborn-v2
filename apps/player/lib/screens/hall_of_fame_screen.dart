import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final missingPlaceholderRoles = missingRoleAwardPlaceholders();
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'HALL OF FAME',
          style: Theme.of(context).textTheme.titleLarge!,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh Hall of Fame',
            onPressed: _isLoading ? null : _loadStats,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: CBNeonBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CBBreathingSpinner())
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 16, bottom: 32),
                  children: [
                    if (_stats.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CBGlassTile(
                          isPrismatic: true,
                          borderColor: scheme.primary.withValues(alpha: 0.4),
                          child: Text(
                            'No game records found. Play a game to enter the Hall of Fame!',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(
                        _stats.length,
                        (index) => _buildProfileCard(_stats[index], index, scheme),
                      ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ROLE AWARDS',
                        style: textTheme.titleLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Role ladders finalized: ${awardCoverage.rolesWithDefinitions}/${awardCoverage.totalRoles} • Recent unlocks: $_recentUnlockCount',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!_persistenceReady)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text(
                          'Career records are not initialized yet. Showing award catalog only.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildRoleAwardFilters(scheme, visibleRoles.length),
                    ),
                    if (missingPlaceholderRoles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: CBGlassTile(
                          isPrismatic: true,
                          borderColor: scheme.error.withValues(alpha: 0.5),
                          child: Text(
                            'Placeholder registry is missing roles: ${missingPlaceholderRoles.join(', ')}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ...visibleRoles
                        .map((role) => _buildRoleAwardCard(role, scheme)),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildRoleAwardFilters(ColorScheme scheme, int visibleRoleCount) {
    final roleOptions = [...roleCatalog]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return CBGlassTile(
      isPrismatic: true,
      borderColor: scheme.primary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedAwardRoleId,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All roles'),
                        ),
                        ...roleOptions.map(
                          (role) => DropdownMenuItem<String?>(
                            value: role.id,
                            child: Text(role.name),
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tier',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<RoleAwardTier?>(
                      value: _selectedAwardTier,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<RoleAwardTier?>(
                          value: null,
                          child: Text('All tiers'),
                        ),
                        ...RoleAwardTier.values.map(
                          (tier) => DropdownMenuItem<RoleAwardTier?>(
                            value: tier,
                            child: Text(_tierLabel(tier)),
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Showing $visibleRoleCount of ${roleCatalog.length} roles.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
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
            ? 'No awards match current filters.'
            : '${roleAwardDefinitions.length} awards shown • $visibleUnlockCount unlocks (total: $unlockCount)'
        : placeholderText;

    return CBGlassTile(
      isPrismatic: true,
      borderColor: scheme.primary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role.name,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            role.type,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            descriptor,
            style: textTheme.bodyLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
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
        rankIcon = Icons.emoji_events;
        break;
      case 1:
        rankColor =
            scheme.onSurface.withValues(alpha: 0.85); // Silver for 2nd place
        rankIcon = Icons.military_tech;
        break;
      case 2:
        rankColor =
            scheme.error; // Bronze for 3rd place, or a distinct color for top 3
        rankIcon = Icons.military_tech_outlined;
        break;
      default:
        rankColor =
            scheme.primary.withValues(alpha: 0.55); // Default for others
    }

    return CBGlassTile(
      isPrismatic: true,
      borderColor: rankColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (rankIcon != null)
                Icon(rankIcon, color: rankColor, shadows: [
                  BoxShadow(color: rankColor, blurRadius: 10, spreadRadius: 1)
                ]),
              if (rankIcon != null) const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '#${index + 1} ${stat.playerName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Wins: ${stat.gamesWon} • Win Rate: ${stat.winPercentage.toStringAsFixed(1)}%',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: rankColor),
          ),
          const SizedBox(height: 12),
          _buildStatRow('Games Played', '${stat.gamesPlayed}', scheme: scheme),
          _buildStatRow('Games Won', '${stat.gamesWon}', scheme: scheme),
          _buildStatRow('Favorite Role', stat.mostPlayedRole, scheme: scheme),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value,
      {required ColorScheme scheme}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: textTheme.bodyLarge!
                  .copyWith(color: scheme.onSurfaceVariant)),
          Text(value,
              style: textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.bold, color: scheme.onSurface)),
        ],
      ),
    );
  }
}

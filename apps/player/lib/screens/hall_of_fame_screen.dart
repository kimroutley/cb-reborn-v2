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

    final records = PersistenceService.instance.loadGameRecords();
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

    setState(() {
      _stats = playerStats.values.toList()
        ..sort((a, b) =>
            b.gamesWon.compareTo(a.gamesWon)); // Sort by wins for player view
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'HALL OF FAME',
      drawer:
          const CustomDrawer(), // Keep as const for now, revisit drawer integration later
      body: _isLoading
          ? const Center(child: CBBreathingSpinner())
          : _stats.isEmpty
              ? Center(
                  child: Text(
                    'No game records found. Play a game to enter the Hall of Fame!',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 32),
                  itemCount: _stats.length,
                  itemBuilder: (context, index) {
                    return _buildProfileCard(_stats[index], index, scheme);
                  },
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
      title: '#${index + 1} ${stat.playerName}',
      subtitle:
          'Wins: ${stat.gamesWon} • Win Rate: ${stat.winPercentage.toStringAsFixed(1)}%',
      accentColor: rankColor,
      isCritical: index < 3,
      isPrismatic: true,
      icon: rankIcon != null
          ? Icon(rankIcon, color: rankColor, shadows: [
              BoxShadow(color: rankColor, blurRadius: 10, spreadRadius: 1)
            ])
          : null,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

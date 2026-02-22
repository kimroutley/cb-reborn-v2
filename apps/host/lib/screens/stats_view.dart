import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'games_night_recap_screen.dart';

/// Displays game history records and aggregate stats.
class StatsView extends StatefulWidget {
  final GameState gameState;
  final VoidCallback? onOpenCommand;
  const StatsView({
    super.key,
    required this.gameState,
    this.onOpenCommand,
  });

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  List<GameRecord> _records = [];
  List<GamesNightRecord> _sessions = [];
  GameStats _stats = const GameStats();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = PersistenceService.instance.loadGameRecords();
    final stats = PersistenceService.instance.computeStats();
    final sessions = await PersistenceService.instance.loadAllSessions();
    if (mounted) {
      setState(() {
        _records = records;
        _stats = stats;
        _sessions = sessions;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(
        child: CBBreathingSpinner(),
      );
    }

    return Column(
      children: [
        // TACTICAL HEADER for Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CBBadge(text: 'ANALYTICS ENGINE', color: scheme.primary),
              const Spacer(),
              if (widget.onOpenCommand != null) ...[
                OutlinedButton.icon(
                  onPressed: widget.onOpenCommand,
                  icon: const Icon(Icons.dashboard_customize_rounded, size: 16),
                  label: const Text('Command'),
                ),
                const SizedBox(width: 8),
              ],
              if (_records.isNotEmpty)
                CBGhostButton(
                  label: 'PURGE DATA',
                  fullWidth: false,
                  color: scheme.error, // Migrated from CBColors.dead
                  onPressed: _confirmClearAll,
                ),
            ],
          ),
        ),
        Expanded(
          child: _records.isEmpty ? _buildEmptyState() : _buildContent(scheme),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart,
              size: 80, color: scheme.surfaceContainerHighest),
          const SizedBox(height: 24),
          Text(
            'NO GAME RECORDS',
            style: textTheme.displaySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a game to see stats here.',
            style: textTheme.bodySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme scheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(scheme);
        }
        final record = _records[index - 1];
        return _buildRecordTile(record, scheme);
      },
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickStatTile(
                context,
                'TOTAL GAMES',
                '${_stats.totalGames}',
                Icons.videogame_asset_outlined,
                scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStatTile(
                context,
                'AVG PLAYERS',
                _stats.averagePlayerCount.toStringAsFixed(1),
                Icons.people_outline_rounded,
                scheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (widget.gameState.phase != GamePhase.lobby) ...[
          _buildLiveIntel(scheme),
          const SizedBox(height: 24),
        ],
        _buildStatsCard(scheme),
        const SizedBox(height: 24),
        _buildGamesNightSessions(scheme),
        const SizedBox(height: 24),
        CBSectionHeader(title: 'GAME HISTORY', count: _records.length),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildQuickStatTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBGlassTile(
      borderColor: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(CBRadius.md),
      padding: const EdgeInsets.all(16),
      isPrismatic: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: textTheme.headlineSmall!.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1.0,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIntel(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    final players = widget.gameState.players;
    final alive = players.where((p) => p.isAlive).toList();
    final staff = alive.where((p) => p.alliance == Team.clubStaff).length;
    final animals = alive.where((p) => p.alliance == Team.partyAnimals).length;
    final neutrals = alive.length - staff - animals;

    return CBPanel(
      padding: const EdgeInsets.all(20),
      borderColor: scheme.secondary.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBBadge(text: 'LIVE GAME INTEL', color: scheme.secondary),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _statBox('ALIVE', '${alive.length}',
                      scheme.tertiary)), // Migrated from CBColors.matrixGreen
              const SizedBox(width: 8),
              Expanded(child: _statBox('STAFF', '$staff', scheme.secondary)),
              const SizedBox(width: 8),
              Expanded(child: _statBox('ANIMALS', '$animals', scheme.primary)),
              const SizedBox(width: 8),
              Expanded(
                  child: _statBox('NEUTRALS', '$neutrals',
                      scheme.error)), // Migrated from CBColors.alertOrange
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'CORE STABILITY: ${(alive.length / players.length * 100).round()}%',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color accentColor) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        color: accentColor.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.displayLarge!.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    final total = _stats.totalGames;
    if (total == 0) return const SizedBox.shrink();

    final staffPct =
        total > 0 ? (_stats.clubStaffWins / total * 100).round() : 0;
    final paPct =
        total > 0 ? (_stats.partyAnimalsWins / total * 100).round() : 0;
    final neutralWins = total - _stats.clubStaffWins - _stats.partyAnimalsWins;
    final neutralPct = total > 0 ? (neutralWins / total * 100).round() : 0;

    return CBPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBBadge(text: 'AGGREGATE STATS', color: scheme.primary),
          const SizedBox(height: 16),

          // Top row — totals
          Row(
            children: [
              Expanded(child: _statBox('GAMES', '$total', scheme.primary)),
              const SizedBox(width: 8),
              Expanded(
                  child: _statBox(
                      'AVG PLAYERS',
                      _stats.averagePlayerCount.toStringAsFixed(1),
                      scheme.secondary)),
              const SizedBox(width: 8),
              Expanded(
                  child: _statBox(
                      'AVG DAYS',
                      _stats.averageDayCount.toStringAsFixed(1),
                      scheme.error)), // Migrated from CBColors.alertOrange
            ],
          ),
          const SizedBox(height: 20),

          // Win rate bars
          Text(
            'WIN RATES',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          _winBar('CLUB STAFF', staffPct, scheme.secondary),
          const SizedBox(height: 6),
          _winBar('PARTY ANIMALS', paPct,
              scheme.tertiary), // Migrated from CBColors.matrixGreen
          const SizedBox(height: 6),
          _winBar('NEUTRAL', neutralPct,
              scheme.error), // Migrated from CBColors.alertOrange

          // Top roles
          if (_stats.roleFrequency.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'TOP ROLES',
              style: textTheme.labelSmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _topRoles(scheme),
            ),
          ],
        ],
      ),
    );
  }

  Widget _winBar(String label, int percent, Color color) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent / 100,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '$percent%',
            style: textTheme.labelSmall!.copyWith(color: color, fontSize: 12),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  List<Widget> _topRoles(ColorScheme scheme) {
    final sorted = _stats.roleFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(8).map((e) {
      final wins = _stats.roleWinCount[e.key] ?? 0;
      final roleName = roleCatalogMap[e.key]?.name ??
          e.key.replaceAll('_', ' ').toUpperCase();
      return CBBadge(
        text: '$roleName ×${e.value} (W:$wins)',
        color: scheme.primary,
      );
    }).toList();
  }

  Widget _buildGamesNightSessions(ColorScheme scheme) {
    // Use cached sessions
    if (_sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    final recordsById = {for (final r in _records) r.id: r};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CBSectionHeader(title: 'GAMES NIGHT SESSIONS', count: _sessions.length),
        const SizedBox(height: 12),
        ..._sessions.map((session) {
          final games = session.gameIds
              .map((id) => recordsById[id])
              .whereType<GameRecord>()
              .toList();

          return Dismissible(
            key: Key(session.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: scheme.error, // Migrated from CBColors.bloodOrange
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete,
                  color: scheme.onSurface), // Migrated from CBColors.voidBlack
            ),
            confirmDismiss: (_) => _confirmDelete(
              'Delete session "${session.sessionName}"?',
              'This will not delete the individual game records.',
            ),
            onDismissed: (_) async {
              await PersistenceService.instance.deleteSession(session.id);
              // Reload data to refresh list
              _loadData();
            },
            child: _buildSessionTile(session, games, scheme),
          );
        }),
      ],
    );
  }

  Widget _buildSessionTile(
      GamesNightRecord session, List<GameRecord> games, ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    final dateRange = session.endedAt != null
        ? '${DateFormat('MMM dd').format(session.startedAt)} - ${DateFormat('MMM dd, yyyy').format(session.endedAt!)}'
        : '${DateFormat('MMM dd, yyyy').format(session.startedAt)} (Active)';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CBPanel(
        padding: const EdgeInsets.all(16),
        borderColor: session.isActive
            ? scheme.tertiary // Migrated from CBColors.matrixGreen
            : scheme.outline.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (session.isActive)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CBBadge(
                        text: 'ACTIVE',
                        color: scheme
                            .tertiary), // Migrated from CBColors.matrixGreen
                  ),
                Expanded(
                  child: Text(
                    session.sessionName,
                    style: textTheme.headlineSmall!.copyWith(
                      color: session.isActive
                          ? scheme
                              .tertiary // Migrated from CBColors.matrixGreen
                          : scheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  tooltip: 'View Recap',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GamesNightRecapScreen(
                          session: session,
                          games: games,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateRange,
              style: textTheme.labelSmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${games.length} game${games.length == 1 ? '' : 's'} • ${session.playerNames.length} player${session.playerNames.length == 1 ? '' : 's'}',
              style: textTheme.bodySmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordTile(GameRecord record, ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    final date = DateFormat('MMM dd, yyyy – HH:mm').format(record.startedAt);
    final winnerLabel = switch (record.winner) {
      Team.clubStaff => 'CLUB STAFF',
      Team.partyAnimals => 'PARTY ANIMALS',
      Team.neutral => 'NEUTRAL',
      _ => record.winner.name.toUpperCase(),
    };
    final winnerColor = switch (record.winner) {
      Team.clubStaff => scheme.secondary,
      Team.partyAnimals =>
        scheme.tertiary, // Migrated from CBColors.matrixGreen
      Team.neutral => scheme.error, // Migrated from CBColors.alertOrange
      _ => scheme.onSurface.withValues(alpha: 0.6),
    };

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(
        'DELETE GAME RECORD',
        'Delete this archived game record? This cannot be undone.',
      ),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color:
            scheme.error.withValues(alpha: 0.8), // Migrated from CBColors.dead
        child: Icon(Icons.delete_forever, color: scheme.onSurface),
      ),
      onDismissed: (_) async {
        await PersistenceService.instance.deleteGameRecord(record.id);
        await _loadData();
      },
      child: CBPanel(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        borderColor: winnerColor.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CBBadge(text: winnerLabel, color: winnerColor),
                const Spacer(),
                Text(
                  date,
                  style: textTheme.labelSmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniStat(
                    Icons.people_outline, '${record.playerCount}', scheme),
                const SizedBox(width: 20),
                _miniStat(
                    Icons.wb_sunny_outlined, '${record.dayCount} days', scheme),
                const SizedBox(width: 20),
                _miniStat(Icons.casino_outlined,
                    '${record.rolesInPlay.length} roles', scheme),
              ],
            ),
            if (record.roster.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: record.roster.map((snap) {
                  final color = snap.alive
                      ? scheme.tertiary
                      : scheme
                          .error; // Migrated from CBColors.matrixGreen and CBColors.dead
                  return Text(
                    snap.name,
                    style: textTheme.bodySmall!.copyWith(
                      color: color.withValues(alpha: 0.7),
                      decoration: snap.alive
                          ? TextDecoration.none
                          : TextDecoration.lineThrough,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: scheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: textTheme.bodySmall!.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _confirmClearAll() {
    showThemedDialog(
      context: context,
      accentColor: Theme.of(context).colorScheme.error,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLEAR ALL RECORDS',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows: CBColors.textGlow(
                    Theme.of(context).colorScheme.error,
                    intensity: 0.55,
                  ),
                ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Delete all game history? This cannot be undone.',
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: 'DELETE ALL',
                backgroundColor: Theme.of(context).colorScheme.error,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          )
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        PersistenceService.instance.clearGameRecords();
        _loadData();
      }
    });
  }

  Future<bool?> _confirmDelete(String title, String message) async {
    final scheme = Theme.of(context).colorScheme;
    return showThemedDialog<bool>(
      context: context,
      accentColor: scheme.error, // Migrated from CBColors.bloodOrange
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.error, // Migrated from CBColors.bloodOrange
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows: CBColors.textGlow(scheme.error, intensity: 0.55),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.75),
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: 'DELETE',
                backgroundColor:
                    scheme.error, // Migrated from CBColors.bloodOrange
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          )
        ],
      ),
    );
  }
}

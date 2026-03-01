import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'games_night_recap_screen.dart';

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
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const Center(
        child: CBBreathingSpinner(),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              CBBadge(text: 'ANALYTICS ENGINE', color: scheme.primary),
              const Spacer(),
              if (widget.onOpenCommand != null) ...[
                CBGhostButton(
                  label: 'COMMAND',
                  icon: Icons.dashboard_customize_rounded,
                  fullWidth: false,
                  onPressed: () {
                    HapticService.selection();
                    widget.onOpenCommand!();
                  },
                ),
                const SizedBox(width: 12),
              ],
              if (_records.isNotEmpty)
                CBGhostButton(
                  label: 'PURGE DATA',
                  fullWidth: false,
                  color: scheme.error,
                  onPressed: () {
                    HapticService.heavy();
                    _confirmClearAll();
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: _records.isEmpty ? _buildEmptyState(scheme, textTheme) : _buildContent(scheme, textTheme),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme scheme, TextTheme textTheme) {
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
                Icon(Icons.bar_chart_rounded,
                    size: 64, color: scheme.primary.withValues(alpha: 0.2)),
                const SizedBox(height: 24),
                Text(
                  'NO ARCHIVED DATA',
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'COMPLETE A SESSION TO GENERATE METRICS.',
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

  Widget _buildContent(ColorScheme scheme, TextTheme textTheme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: scheme.primary,
      backgroundColor: scheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
        physics: const BouncingScrollPhysics(),
        itemCount: _records.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(scheme, textTheme);
          }
          final record = _records[index - 1];
          return CBFadeSlide(
            delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
            child: _buildRecordTile(record, scheme, textTheme),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme, TextTheme textTheme) {
    final totalAwards = allRoleAwardDefinitions().length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickStatTile(
                context,
                'TOTAL SESSIONS',
                '${_stats.totalGames}',
                Icons.videogame_asset_rounded,
                scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStatTile(
                context,
                'AVG OPERATIVES',
                _stats.averagePlayerCount.toStringAsFixed(1),
                Icons.people_alt_rounded,
                scheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStatTile(
                context,
                'ROLE ARCHIVES',
                '$totalAwards',
                Icons.military_tech_rounded,
                scheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (widget.gameState.phase != GamePhase.lobby) ...[
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: _buildLiveIntel(scheme, textTheme),
          ),
          const SizedBox(height: 24),
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: _buildVotingArchive(scheme, textTheme),
          ),
          const SizedBox(height: 24),
        ],
        CBFadeSlide(
          delay: const Duration(milliseconds: 300),
          child: _buildStatsCard(scheme, textTheme),
        ),
        const SizedBox(height: 24),
        CBFadeSlide(
          delay: const Duration(milliseconds: 400),
          child: _buildGamesNightSessions(scheme, textTheme),
        ),
        const SizedBox(height: 24),
        const CBFeedSeparator(label: 'MISSION LOGS'),
        const SizedBox(height: 16),
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
      borderColor: color.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(CBRadius.md),
      padding: const EdgeInsets.all(20),
      isPrismatic: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: textTheme.headlineSmall!.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontFamily: 'RobotoMono',
              shadows: CBColors.textGlow(color, intensity: 0.3),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: textTheme.labelSmall!.copyWith(
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

  Widget _buildLiveIntel(ColorScheme scheme, TextTheme textTheme) {
    final players = widget.gameState.players;
    final alive = players.where((p) => p.isAlive).toList();
    final staff = alive.where((p) => p.alliance == Team.clubStaff).length;
    final animals = alive.where((p) => p.alliance == Team.partyAnimals).length;
    final neutrals = alive.length - staff - animals;

    return CBPanel(
      padding: const EdgeInsets.all(24),
      borderColor: scheme.secondary.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CBSectionHeader(
            title: 'LIVE OPERATIVE INTEL',
            icon: Icons.radar_rounded,
            color: scheme.secondary,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _statBox('ACTIVE', '${alive.length}',
                      scheme.tertiary, textTheme)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statBox('STAFF', '$staff', scheme.primary,
                      textTheme)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statBox('PARTY', '$animals', scheme.secondary,
                      textTheme)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statBox('NEUTRAL', '$neutrals',
                      CBColors.alertOrange, textTheme)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'SYSTEM STABILITY: ${(alive.length / players.length * 100).round()}%',
            textAlign: TextAlign.center,
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1.5,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color accentColor, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.headlineSmall!.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w900,
              fontFamily: 'RobotoMono',
              shadows: CBColors.textGlow(accentColor, intensity: 0.3),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: textTheme.labelSmall!.copyWith(
              color: accentColor.withValues(alpha: 0.7),
              letterSpacing: 1.0,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingArchive(ColorScheme scheme, TextTheme textTheme) {
    final eventLog = widget.gameState.eventLog;
    final voteEvents = eventLog.whereType<GameEventVote>().toList()
      ..sort((a, b) => a.day.compareTo(b.day));

    if (voteEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    final byDay = <int, List<GameEventVote>>{};
    for (final v in voteEvents) {
      byDay.putIfAbsent(v.day, () => []).add(v);
    }

    return CBPanel(
      padding: const EdgeInsets.all(24),
      borderColor: scheme.tertiary.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CBSectionHeader(
            title: 'VOTING ARCHIVES',
            icon: Icons.how_to_vote_rounded,
            color: scheme.tertiary,
          ),
          const SizedBox(height: 24),
          for (final day in byDay.keys.toList()..sort()) ...[
            Text(
              'DAY $day PROTOCOL',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.tertiary,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 12),
            ...byDay[day]!.map((v) {
              final voter = widget.gameState.players
                  .cast<Player?>()
                  .firstWhere((p) => p?.id == v.voterId, orElse: () => null);
              final target = widget.gameState.players
                  .cast<Player?>()
                  .firstWhere((p) => p?.id == v.targetId, orElse: () => null);
              final voterLabel = voter?.name.toUpperCase() ?? v.voterId.toUpperCase();
              final targetLabel = v.targetId == 'abstain'
                  ? 'ABSTAINED'
                  : (target?.name.toUpperCase() ?? v.targetId.toUpperCase());
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right_alt_rounded,
                        size: 16,
                        color: scheme.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 8),
                    Text(
                      '$voterLabel → $targetLabel',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontFamily: 'RobotoMono',
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(ColorScheme scheme, TextTheme textTheme) {
    final total = _stats.totalGames;
    if (total == 0) return const SizedBox.shrink();

    final staffPct =
        total > 0 ? (_stats.clubStaffWins / total * 100).round() : 0;
    final paPct =
        total > 0 ? (_stats.partyAnimalsWins / total * 100).round() : 0;
    final neutralWins = total - _stats.clubStaffWins - _stats.partyAnimalsWins;
    final neutralPct = total > 0 ? (neutralWins / total * 100).round() : 0;

    return CBPanel(
      padding: const EdgeInsets.all(24),
      borderColor: scheme.primary.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CBSectionHeader(
            title: 'AGGREGATE PERFORMANCE',
            icon: Icons.leaderboard_rounded,
            color: scheme.primary,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _statBox('MISSIONS', '$total', scheme.primary, textTheme)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statBox(
                      'AVG OPERATIVES',
                      _stats.averagePlayerCount.toStringAsFixed(1),
                      scheme.secondary, textTheme)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statBox(
                      'AVG CYCLES',
                      _stats.averageDayCount.toStringAsFixed(1),
                      CBColors.alertOrange, textTheme)),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'FACTION SUCCESS RATES',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          _winBar('CLUB STAFF', staffPct, scheme.primary, textTheme),
          const SizedBox(height: 10),
          _winBar('PARTY ANIMALS', paPct, scheme.secondary, textTheme),
          const SizedBox(height: 10),
          _winBar('NEUTRAL', neutralPct, CBColors.alertOrange, textTheme),

          if (_stats.roleFrequency.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'TOP OPERATIVE ROLES',
              style: textTheme.labelSmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 2.0,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _topRoles(scheme, textTheme),
            ),
          ],
        ],
      ),
    );
  }

  Widget _winBar(String label, int percent, Color color, TextTheme textTheme) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 12,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.7)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$percent%',
            style: textTheme.labelMedium!.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontFamily: 'RobotoMono',
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  List<Widget> _topRoles(ColorScheme scheme, TextTheme textTheme) {
    final sorted = _stats.roleFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(6).map((e) {
      final wins = _stats.roleWinCount[e.key] ?? 0;
      final roleDef = roleCatalogMap[e.key];
      final roleName = roleDef?.name ??
          e.key.replaceAll('_', ' ').toUpperCase();
      final roleColor = roleDef != null ? CBColors.fromHex(roleDef.colorHex) : scheme.primary;

      return CBMiniTag(
        text: '$roleName ×${e.value} (W:$wins)',
        color: roleColor,
      );
    }).toList();
  }

  Widget _buildGamesNightSessions(ColorScheme scheme, TextTheme textTheme) {
    if (_sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    final recordsById = {for (final r in _records) r.id: r};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CBSectionHeader(title: 'ARCHIVED SESSIONS', icon: Icons.folder_rounded, color: scheme.tertiary, count: _sessions.length),
        const SizedBox(height: 16),
        ..._sessions.map((session) {
          final games = session.gameIds
              .map((id) => recordsById[id])
              .whereType<GameRecord>()
              .toList();

          return CBFadeSlide(
            delay: Duration(milliseconds: 50 * _sessions.indexOf(session).clamp(0, 5)),
            child: Dismissible(
              key: Key(session.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: scheme.error,
                  borderRadius: BorderRadius.circular(CBRadius.md),
                ),
                child: Icon(Icons.delete_forever_rounded, color: scheme.onError, size: 28),
              ),
              confirmDismiss: (_) => _confirmDelete(
                'DELETE SESSION LOG',
                'PERMANENTLY ERASE SESSION "${session.sessionName.toUpperCase()}" (GAME RECORDS REMAIN).',
              ),
              onDismissed: (_) async {
                await PersistenceService.instance.deleteSession(session.id);
                _loadData();
              },
              child: _buildSessionTile(session, games, scheme, textTheme),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSessionTile(
      GamesNightRecord session, List<GameRecord> games, ColorScheme scheme, TextTheme textTheme) {
    final dateRange = session.endedAt != null
        ? '${DateFormat('MMM dd').format(session.startedAt)} - ${DateFormat('MMM dd, yyyy').format(session.endedAt!)}'
        : '${DateFormat('MMM dd, yyyy').format(session.startedAt)} (ACTIVE)';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CBGlassTile(
        padding: const EdgeInsets.all(20),
        isPrismatic: session.isActive,
        borderColor: session.isActive
            ? scheme.tertiary
            : scheme.outlineVariant.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (session.isActive)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CBBadge(
                        text: 'ACTIVE',
                        color: scheme.tertiary, icon: Icons.bolt_rounded),
                  ),
                Expanded(
                  child: Text(
                    session.sessionName.toUpperCase(),
                    style: textTheme.titleMedium!.copyWith(
                      color: session.isActive ? scheme.tertiary : scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      shadows: session.isActive ? CBColors.textGlow(scheme.tertiary, intensity: 0.3) : null,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.open_in_new_rounded, color: scheme.onSurface.withValues(alpha: 0.7)),
                  tooltip: 'View Recap',
                  onPressed: () {
                    HapticService.selection();
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
            const SizedBox(height: 12),
            Text(
              dateRange,
              style: textTheme.labelSmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.videogame_asset_rounded, size: 16, color: scheme.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(
                  '${games.length} MISSION${games.length == 1 ? '' : 'S'}',
                  style: textTheme.bodySmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 20),
                Icon(Icons.people_alt_rounded, size: 16, color: scheme.secondary.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(
                  '${session.playerNames.length} OPERATIVE${session.playerNames.length == 1 ? '' : 'S'}',
                  style: textTheme.bodySmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordTile(GameRecord record, ColorScheme scheme, TextTheme textTheme) {
    final date = DateFormat('MMM dd, yyyy – HH:mm').format(record.startedAt);
    final winnerLabel = switch (record.winner) {
      Team.clubStaff => 'STAFF VICTORY',
      Team.partyAnimals => 'PARTY VICTORY',
      Team.neutral => 'NEUTRAL VICTORY',
      _ => record.winner.name.toUpperCase(),
    };
    final winnerColor = switch (record.winner) {
      Team.clubStaff => scheme.primary,
      Team.partyAnimals => scheme.secondary,
      Team.neutral => CBColors.alertOrange,
      _ => scheme.onSurface.withValues(alpha: 0.6),
    };

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(
        'DELETE MISSION LOG',
        'PERMANENTLY ERASE THIS ARCHIVED MISSION LOG? THIS CANNOT BE UNDONE.',
      ),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: scheme.error,
        child: Icon(Icons.delete_forever_rounded, color: scheme.onError, size: 28),
      ),
      onDismissed: (_) async {
        HapticService.heavy();
        await PersistenceService.instance.deleteGameRecord(record.id);
        await _loadData();
      },
      child: CBPanel(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        borderColor: winnerColor.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CBBadge(text: winnerLabel, color: winnerColor, icon: Icons.emoji_events_rounded),
                const Spacer(),
                Text(
                  date,
                  style: textTheme.labelSmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 10,
                    letterSpacing: 0.5,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _miniStat(
                    Icons.people_alt_rounded, '${record.playerCount} Operatives', scheme, textTheme),
                const SizedBox(width: 24),
                _miniStat(
                    Icons.timer_rounded, '${record.dayCount} Cycles', scheme, textTheme),
                const SizedBox(width: 24),
                _miniStat(Icons.assignment_ind_rounded,
                    '${record.rolesInPlay.length} Roles', scheme, textTheme),
              ],
            ),
            if (record.roster.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'OPERATIVE STATUS',
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: record.roster
                    .map<Widget>((snap) {
                      final color = snap.alive
                          ? scheme.tertiary
                          : scheme.error;
                      return CBMiniTag(
                        text: snap.name,
                        color: color,
                        tooltip: snap.alive ? null : 'Eliminated',
                      );
                    })
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, ColorScheme scheme, TextTheme textTheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: scheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Text(
          value.toUpperCase(),
          style: textTheme.bodySmall!.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PURGE ALL ARCHIVES',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w900,
                  shadows: CBColors.textGlow(
                    Theme.of(context).colorScheme.error,
                    intensity: 0.6,
                  ),
                ),
          ),
          const SizedBox(height: 24),
          Text(
            'PERMANENTLY DELETE ALL GAME HISTORY AND SESSION LOGS? THIS CANNOT BE UNDONE.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 32),
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
        HapticService.heavy();
        PersistenceService.instance.clearGameRecords();
        _loadData();
      }
    });
  }

  Future<bool?> _confirmDelete(String title, String message) async {
    final scheme = Theme.of(context).colorScheme;
    return showThemedDialog<bool>(
      context: context,
      accentColor: scheme.error,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.error,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w900,
                  shadows: CBColors.textGlow(scheme.error, intensity: 0.6),
                ),
          ),
          const SizedBox(height: 24),
          Text(
            message.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 32),
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
                label: 'CONFIRM DELETE',
                backgroundColor: scheme.error,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          )
        ],
      ),
    );
  }
}

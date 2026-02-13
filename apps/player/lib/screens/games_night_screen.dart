import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../widgets/custom_drawer.dart';

class GamesNightScreen extends ConsumerStatefulWidget {
  const GamesNightScreen({super.key});

  @override
  ConsumerState<GamesNightScreen> createState() => _GamesNightScreenState();
}

class _GamesNightScreenState extends ConsumerState<GamesNightScreen> {
  bool _isLoading = true;
  List<GamesNightRecord> _sessions = [];
  List<GameRecord> _gameRecords = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final service = PersistenceService.instance;
    final allSessions = await service.loadAllSessions();
    final allGameRecords = service.loadGameRecords();

    // For player, we only show sessions/games they were part of. (Simplified for now)
    // This will require actual player ID tracking in GameRecord/GamesNightRecord
    // For now, just load all, and we'll filter or show a message if no player context.

    if (!mounted) return;
    setState(() {
      _sessions = allSessions;
      _gameRecords = allGameRecords;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'GAMES NIGHT',
      drawer:
          const CustomDrawer(), // Keep as const for now, revisit drawer integration later
      body: _isLoading
          ? const Center(child: CBBreathingSpinner())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                children: [
                  CBSectionHeader(
                      title: 'YOUR SESSION HISTORY', color: scheme.tertiary),
                  const SizedBox(height: 16),
                  if (_sessions.isEmpty)
                    CBPanel(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No game sessions found. Play a game to see your history here.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.75)),
                      ),
                    )
                  else
                    ..._sessions
                        .map((s) => _buildSessionEntry(context, s, scheme)),
                  const SizedBox(height: 120), // Provide some bottom padding
                ],
              ),
            ),
    );
  }

  Widget _buildSessionEntry(
      BuildContext context, GamesNightRecord session, ColorScheme scheme) {
    final gamesInSession =
        _gameRecords.where((g) => session.gameIds.contains(g.id)).toList();
    final wins = gamesInSession
        .where((g) => g.winner == Team.partyAnimals)
        .length; // Simplified for player view
    final totalGames = gamesInSession.length;

    final dateRange = session.endedAt != null
        ? '${DateFormat('MMM dd').format(session.startedAt)} - ${DateFormat('MMM dd, yyyy').format(session.endedAt!)}'
        : '${DateFormat('MMM dd, yyyy').format(session.startedAt)} (Active)';

    Color accentColor = scheme.primary; // Default to primary
    if (session.isActive) {
      accentColor = scheme.tertiary; // Active session green
    } else if (wins > 0) {
      accentColor = scheme.primary; // Wins in blue
    } else {
      accentColor = scheme.error; // Losses in red
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CBGlassTile(
        title: session.sessionName,
        subtitle:
            '$totalGames game${totalGames == 1 ? '' : 's'}, $wins win${wins == 1 ? '' : 's'} • $dateRange',
        accentColor: accentColor,
        icon: Icon(Icons.history_rounded, color: accentColor, size: 24),
        isPrismatic: true,
        onTap: () {
          // TODO: Implement navigation to a detailed Games Night Recap for the player
          showThemedSnackBar(
            context,
            'Viewing session details for ${session.sessionName} (Not yet implemented).',
            accentColor: scheme.primary,
          );
        },
        content: const SizedBox.shrink(),
      ),
    );
  }
}

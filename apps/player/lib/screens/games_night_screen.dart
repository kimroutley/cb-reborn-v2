import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'games_night_recap_screen.dart';
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
    if (!mounted) return;
    setState(() => _isLoading = true);

    final service = PersistenceService.instance;
    final allSessions = await service.loadAllSessions();
    final allGameRecords = service.loadGameRecords();

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
      title: 'BAR TAB',
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CBBreathingSpinner())
          : RefreshIndicator(
              onRefresh: _loadData,
              backgroundColor: scheme.surfaceContainerHigh,
              color: scheme.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: CBSpace.x6, horizontal: CBSpace.x5),
                children: [
                  CBSectionHeader(
                    title: 'YOUR SESSION HISTORY',
                    color: scheme.tertiary,
                    icon: Icons.history_edu_rounded,
                  ),
                  const SizedBox(height: CBSpace.x4),
                  if (_sessions.isEmpty)
                    CBPanel(
                      padding: const EdgeInsets.all(CBSpace.x6),
                      child: Text(
                        'NO GAME SESSIONS FOUND. PLAY A GAME TO SEE YOUR HISTORY HERE.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                        ),
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
        .length;
    final totalGames = gamesInSession.length;

    final dateRange = session.endedAt != null
        ? '${DateFormat('MMM dd').format(session.startedAt)} - ${DateFormat('MMM dd, yyyy').format(session.endedAt!)}'
        : '${DateFormat('MMM dd, yyyy').format(session.startedAt)} (ACTIVE)';

    Color accentColor = scheme.primary;
    if (session.isActive) {
      accentColor = scheme.tertiary; // Active session green
    } else if (wins > 0) {
      accentColor = scheme.primary; // Wins in blue
    } else {
      accentColor = scheme.error; // Losses in red
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: CBSpace.x3),
      child: CBGlassTile(
        isPrismatic: true,
        borderColor: accentColor.withValues(alpha: 0.4),
        onTap: () {
          HapticService.selection();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GamesNightRecapScreen(
                session: session,
                games: gamesInSession,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, color: accentColor, size: 24),
                const SizedBox(width: CBSpace.x3),
                Expanded(
                  child: Text(
                    session.sessionName.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CBSpace.x2),
            Text(
              '$totalGames GAME${totalGames == 1 ? '' : 'S'}, $wins WIN${wins == 1 ? '' : 'S'} • $dateRange'.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

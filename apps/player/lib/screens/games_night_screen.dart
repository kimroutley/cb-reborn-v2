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
    final textTheme = Theme.of(context).textTheme;

    return CBPrismScaffold(
      title: 'SESSION ARCHIVES',
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CBBreathingSpinner())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: scheme.tertiary,
              backgroundColor: scheme.surface,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding:
                    const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x6, CBSpace.x6, CBSpace.x12),
                children: [
                  CBFadeSlide(
                    child: CBSectionHeader(
                        title: 'YOUR SESSION HISTORY',
                        icon: Icons.history_edu_rounded,
                        color: scheme.tertiary),
                  ),
                  const SizedBox(height: CBSpace.x4),
                  if (_sessions.isEmpty)
                    CBFadeSlide(
                      delay: const Duration(milliseconds: 100),
                      child: CBGlassTile(
                        padding: const EdgeInsets.all(CBSpace.x6),
                        borderColor: scheme.outlineVariant.withValues(alpha: 0.2),
                        child: Column(
                          children: [
                            Icon(Icons.archive_outlined,
                                size: CBSpace.x12, color: scheme.onSurface.withValues(alpha: 0.2)),
                            const SizedBox(height: CBSpace.x4),
                            Text(
                              'NO ARCHIVED SESSIONS',
                              textAlign: TextAlign.center,
                              style: textTheme.labelLarge?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: CBSpace.x2),
                            Text(
                              'COMPLETE A GAME TO LOG YOUR SESSION HISTORY HERE.',
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
                    ..._sessions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final session = entry.value;
                      return CBFadeSlide(
                        delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: CBSpace.x3),
                          child: _buildSessionEntry(context, session, scheme, textTheme),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSessionEntry(
      BuildContext context, GamesNightRecord session, ColorScheme scheme, TextTheme textTheme) {
    final gamesInSession =
        _gameRecords.where((g) => session.gameIds.contains(g.id)).toList();
    final wins = gamesInSession
        .where((g) => g.winner == Team.partyAnimals)
        .length; // Simplified for player view
    final totalGames = gamesInSession.length;

    final dateRange = session.endedAt != null
        ? '${DateFormat('MMM dd').format(session.startedAt)} - ${DateFormat('MMM dd, yyyy').format(session.endedAt!)}'
        : '${DateFormat('MMM dd, yyyy').format(session.startedAt)} (ACTIVE)';

    Color accentColor = scheme.primary; // Default to primary
    if (session.isActive) {
      accentColor = scheme.tertiary; // Active session green
    } else if (wins > 0) {
      accentColor = scheme.primary; // Wins in blue
    } else {
      accentColor = scheme.error; // Losses in red
    }

    return CBGlassTile(
      isPrismatic: session.isActive,
      borderColor: accentColor.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(CBSpace.x4),
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
              Container(
                padding: const EdgeInsets.all(CBSpace.x2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.history_rounded, color: accentColor, size: 20),
              ),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: Text(
                  session.sessionName.toUpperCase(),
                  style: textTheme.titleMedium!.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    shadows: session.isActive ? CBColors.textGlow(accentColor, intensity: 0.3) : null,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withValues(alpha: 0.5), size: 24),
            ],
          ),
          const SizedBox(height: CBSpace.x3),
          Text(
            dateRange.toUpperCase(),
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: CBSpace.x2),
          Row(
            children: [
              Icon(Icons.videogame_asset_rounded, color: scheme.onSurface.withValues(alpha: 0.5), size: 16),
              const SizedBox(width: CBSpace.x2),
              Text(
                '$totalGames MISSION${totalGames == 1 ? '' : 'S'}',
                style: textTheme.bodySmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: CBSpace.x5),
              Icon(Icons.emoji_events_rounded, color: scheme.onSurface.withValues(alpha: 0.5), size: 16),
              const SizedBox(width: CBSpace.x2),
              Text(
                '$wins CLEARED',
                style: textTheme.bodySmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

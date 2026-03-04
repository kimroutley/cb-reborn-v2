import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../host_destinations.dart';
import '../host_navigation.dart';
import '../widgets/common_dialogs.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';
import 'games_night_recap_screen.dart';

class GamesNightScreen extends ConsumerStatefulWidget {
  const GamesNightScreen({super.key});

  @override
  ConsumerState<GamesNightScreen> createState() => _GamesNightScreenState();
}

class _GamesNightScreenState extends ConsumerState<GamesNightScreen> {
  bool _isLoading = true;
  List<GamesNightRecord> _sessions = const [];
  List<GameRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final service = PersistenceService.instance;
    final sessions = await service.loadAllSessions();
    final records = service.loadGameRecords();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _records = records;
      _isLoading = false;
    });

    // Keep provider state in sync if a session was deleted elsewhere.
    await ref.read(gamesNightProvider.notifier).refreshSession();
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(gamesNightProvider);
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'GAMES NIGHT',
      actions: const [SimulationModeBadgeAction()],
      drawer: const CustomDrawer(currentDestination: HostDestination.gamesNight),
      body: _isLoading
          ? const Center(child: CBBreathingLoader())
          : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(vertical: CBSpace.x6, horizontal: CBSpace.x5),
                  children: [
                    CBSectionHeader(
                      title: 'ACTIVE SESSION',
                      icon: Icons.play_circle_outline_rounded,
                      color: scheme.tertiary,
                    ),
                    const SizedBox(height: CBSpace.x3),
                    _buildActiveSessionPanel(context, activeSession, scheme),
                    const SizedBox(height: CBSpace.x8),
                    CBSectionHeader(
                      title: 'RECENT SESSIONS',
                      icon: Icons.history_rounded,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: CBSpace.x3),
                    if (_sessions.isEmpty)
                      CBPanel(
        padding: const EdgeInsets.all(CBSpace.x4),
        borderColor: scheme.outlineVariant.withValues(alpha: 0.3),
                        child: Text(
                          'No sessions yet. Start a Games Night to begin tracking rounds.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.75)),
                        ),
                      )
                    else
                      ..._sessions.map((s) =>
                          _buildSessionDismissibleTile(context, s, scheme)),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
    );
  }

  Widget _buildActiveSessionPanel(
    BuildContext context,
    GamesNightRecord? session,
    ColorScheme scheme,
  ) {
    final textTheme = Theme.of(context).textTheme;

    if (session == null || !session.isActive) {
      return CBPanel(
        padding: CBInsets.screen,
        borderColor: scheme.outline.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NO ACTIVE SESSION',
              style: textTheme.labelLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: CBSpace.x3),
            Text(
              'Start a Games Night to connect multiple rounds and unlock the recap.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: CBSpace.x4),
            Align(
              alignment: Alignment.centerRight,
              child: CBPrimaryButton(
                label: 'START NEW SESSION',
                fullWidth: false,
                onPressed: () async {
                  final name = await showStartSessionDialog(context);
                  if (name == null || name.trim().isEmpty) return;
                  await ref
                      .read(gamesNightProvider.notifier)
                      .startSession(name.trim());
                  await _loadData();
                },
              ),
            ),
          ],
        ),
      );
    }

    final games = _gamesForSession(session);
    final date = DateFormat('MMM dd, yyyy').format(session.startedAt);

    return CBPanel(
      padding: CBInsets.screen,
      borderColor: scheme.tertiary.withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CBBadge(text: 'ACTIVE', color: scheme.tertiary),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: Text(
                  session.sessionName,
                  style: textTheme.headlineSmall?.copyWith(
                    color: scheme.tertiary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CBSpace.x3),
          Text(
            'STARTED $date',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: CBSpace.x3),
          Text(
            '${session.gameIds.length} game${session.gameIds.length == 1 ? '' : 's'} • ${session.playerNames.length} player${session.playerNames.length == 1 ? '' : 's'}',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: CBSpace.x4),
          Row(
            children: [
              Expanded(
                child: CBPrimaryButton(
                  label: 'START NEXT GAME',
                  onPressed: () {
                    ref.read(gameProvider.notifier).returnToLobby();
                    ref
                        .read(hostNavigationProvider.notifier)
                        .setDestination(HostDestination.lobby);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: CBSpace.x3),
          Row(
            children: [
              Expanded(
                child: CBGhostButton(
                  label: 'END SESSION',
                  color: scheme.error,
                  onPressed: () async {
                    final confirmed = await _confirmEndSession(
                        context, scheme.error); // Pass scheme.error
                    if (confirmed != true) return;
                    await ref.read(gamesNightProvider.notifier).endSession();
                    await _loadData();
                  },
                ),
              ),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: CBGhostButton(
                  label: 'VIEW RECAP',
                  color: scheme.primary,
                  onPressed: () {
                    if (games.isEmpty) {
                      showThemedSnackBar(
                        context,
                        'No recap yet — finish at least 1 game in this session.',
                        accentColor: scheme.error,
                        duration: const Duration(seconds: 2),
                      );
                      return;
                    }

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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDismissibleTile(
    BuildContext context,
    GamesNightRecord session,
    ColorScheme scheme,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final games = _gamesForSession(session);
    final date = DateFormat.yMMMd().format(session.startedAt);

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: CBSpace.x5),
        margin: const EdgeInsets.only(bottom: CBSpace.x3),
        decoration: BoxDecoration(
          color: scheme.error.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(CBRadius.sm),
        ),
        child: Icon(Icons.delete_forever,
            color: scheme.onSurface), // Updated to use scheme.onSurface
      ),
      confirmDismiss: (direction) async {
        return await showConfirmationDialog(
          context,
          title: 'Delete Session?',
          content:
              'Are you sure you want to delete "${session.sessionName}"? This cannot be undone.',
          confirmLabel: 'DELETE',
          confirmColor: scheme.error,
        );
      },
      onDismissed: (direction) async {
        await PersistenceService.instance.deleteSession(session.id);
        await _loadData();
        if (context.mounted) {
          showThemedSnackBar(
              context, 'Session "${session.sessionName}" deleted.');
        }
      },
      child: CBPanel(
        margin: const EdgeInsets.only(bottom: CBSpace.x3),
        padding: CBInsets.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.sessionName,
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: CBSpace.x2),
                      Text(
                        '${session.gameIds.length} games • $date',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                CBPrimaryButton(
                  label: 'RECAP',
                  icon: Icons.insights_rounded,
                  fullWidth: false,
                  onPressed: () {
                    Navigator.of(context).push(
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
          ],
        ),
      ),
    );
  }

  List<GameRecord> _gamesForSession(GamesNightRecord session) {
    return _records.where((r) => session.gameIds.contains(r.id)).toList();
  }

  Future<bool?> _confirmEndSession(BuildContext context, Color color) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return showThemedDialog<bool>(
      context: context,
      accentColor: color, // Passed color
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'END SESSION',
            style: theme.textTheme.headlineSmall!.copyWith(
              color: color, // Passed color
              letterSpacing: 1.6,
              fontWeight: FontWeight.bold,
              shadows: CBColors.textGlow(color, intensity: 0.6),
            ),
          ),
          const SizedBox(height: CBSpace.x3),
          Text(
            'Lock this Games Night and finalize the recap?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
          const SizedBox(height: CBSpace.x6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(width: CBSpace.x3),
              CBPrimaryButton(
                label: 'END',
                backgroundColor: color, // Passed color
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

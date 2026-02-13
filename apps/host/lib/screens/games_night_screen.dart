import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';
import 'games_night_recap_screen.dart';
import 'lobby_screen.dart';

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
      drawer: const CustomDrawer(),
      actions: const [SimulationModeBadgeAction()],
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
                    title: 'ACTIVE SESSION',
                    color:
                        scheme.tertiary, // Migrated from CBColors.matrixGreen
                  ),
                  const SizedBox(height: 12),
                  _buildActiveSessionPanel(context, activeSession, scheme),
                  const SizedBox(height: 28),
                  CBSectionHeader(
                    title: 'RECENT SESSIONS',
                    color: scheme.primary, // Migrated from CBColors.neonBlue
                  ),
                  const SizedBox(height: 12),
                  if (_sessions.isEmpty)
                    CBPanel(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No sessions yet. Start a Games Night to begin tracking rounds.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.75)),
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
        padding: const EdgeInsets.all(16),
        borderColor: scheme.outline.withValues(alpha: 0.2),
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
            const SizedBox(height: 10),
            Text(
              'Start a Games Night to connect multiple rounds and unlock the recap.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: CBPrimaryButton(
                label: 'START SESSION',
                onPressed: () async {
                  final name = await _showStartSessionDialog(context, scheme);
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
      padding: const EdgeInsets.all(16),
      borderColor: scheme.tertiary
          .withValues(alpha: 0.55), // Migrated from CBColors.matrixGreen
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CBBadge(
                  text: 'ACTIVE',
                  color: scheme.tertiary), // Migrated from CBColors.matrixGreen
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  session.sessionName,
                  style: textTheme.headlineSmall?.copyWith(
                    color:
                        scheme.tertiary, // Migrated from CBColors.matrixGreen
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'STARTED $date',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${session.gameIds.length} game${session.gameIds.length == 1 ? '' : 's'} • ${session.playerNames.length} player${session.playerNames.length == 1 ? '' : 's'}',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: CBPrimaryButton(
                  label: 'START NEXT GAME',
                  onPressed: () {
                    // Ensure the lobby is clean for the next round.
                    ref.read(gameProvider.notifier).returnToLobby();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LobbyScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CBGhostButton(
                  label: 'END SESSION',
                  onPressed: () async {
                    final confirmed = await _confirmEndSession(
                        context, scheme.error); // Pass scheme.error
                    if (confirmed != true) return;
                    await ref.read(gamesNightProvider.notifier).endSession();
                    await _loadData();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CBGhostButton(
                  label: 'VIEW RECAP',
                  onPressed: () {
                    if (games.isEmpty) {
                      showThemedSnackBar(
                        context,
                        'No recap yet — finish at least 1 game in this session.',
                        accentColor:
                            scheme.error, // Migrated from CBColors.dead
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
      BuildContext context, GamesNightRecord session, ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    final isActive = session.isActive;
    final accent = isActive
        ? scheme.tertiary
        : scheme
            .primary; // Migrated from CBColors.matrixGreen and CBColors.neonBlue
    final started = DateFormat('MMM dd, yyyy').format(session.startedAt);
    final ended = session.endedAt == null
        ? null
        : DateFormat('MMM dd, yyyy').format(session.endedAt!);
    final dateLine = ended == null ? 'STARTED $started' : '$started → $ended';

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDeleteSession(
          context, session, scheme.error), // Pass scheme.error
      onDismissed: (_) async {
        try {
          await PersistenceService.instance.deleteSession(session.id);
          await ref.read(gamesNightProvider.notifier).refreshSession();
          await _loadData();
        } catch (_) {
          if (!context.mounted) return;
          showThemedSnackBar(
            context,
            'Failed to delete session.',
            accentColor: scheme.error, // Migrated from CBColors.dead
            duration: const Duration(seconds: 2),
          );
          await _loadData();
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color:
            scheme.error.withValues(alpha: 0.8), // Migrated from CBColors.dead
        child: Icon(Icons.delete_forever, color: scheme.onSurface),
      ),
      child: CBGlassTile(
        title: session.sessionName,
        subtitle: dateLine,
        accentColor: accent,
        isPrismatic: true,
        isCritical: false,
        isResolved: !isActive,
        icon: isActive
            ? CBBadge(
                text: 'ACTIVE',
                color: scheme.tertiary) // Migrated from CBColors.matrixGreen
            : null,
        content: Row(
          children: [
            Text(
              '${session.gameIds.length} game${session.gameIds.length == 1 ? '' : 's'}',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${session.playerNames.length} player${session.playerNames.length == 1 ? '' : 's'}',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<GameRecord> _gamesForSession(GamesNightRecord session) {
    if (session.gameIds.isEmpty || _records.isEmpty) return const [];
    final byId = <String, GameRecord>{
      for (final r in _records) r.id: r,
    };
    final games = <GameRecord>[];
    for (final id in session.gameIds) {
      final record = byId[id];
      if (record != null) games.add(record);
    }
    return games;
  }

  Future<String?> _showStartSessionDialog(
      BuildContext context, ColorScheme scheme) async {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    return showThemedDialog<String>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'START GAMES NIGHT',
            style: theme.textTheme.headlineSmall!.copyWith(
              color: scheme.tertiary, // Migrated from CBColors.matrixGreen
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
              shadows: CBColors.textGlow(
                  scheme.tertiary), // Migrated from CBColors.matrixGreen
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CONNECT MULTIPLE ROUNDS FOR A FULL RECAP',
            style: theme.textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          CBTextField(
            controller: controller,
            autofocus: true,
            textStyle:
                theme.textTheme.bodyLarge!.copyWith(color: scheme.onSurface),
            decoration: InputDecoration(
              labelText: 'SESSION NAME',
              labelStyle: TextStyle(
                  color: scheme.tertiary.withValues(
                      alpha: 0.7)), // Migrated from CBColors.matrixGreen
              hintText: 'e.g. SATURDAY NIGHT FEVER',
              hintStyle:
                  TextStyle(color: scheme.onSurface.withValues(alpha: 0.2)),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'ABORT',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                label: 'INITIALIZE',
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    Navigator.pop(context, controller.text);
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
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
          const SizedBox(height: 10),
          Text(
            'Lock this Games Night and finalize the recap?',
            style: theme.textTheme.bodyMedium?.copyWith(
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

  Future<bool?> _confirmDeleteSession(
    BuildContext context,
    GamesNightRecord session,
    Color color,
  ) {
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
            'DELETE SESSION',
            style: theme.textTheme.headlineSmall!.copyWith(
              color: color, // Passed color
              letterSpacing: 1.6,
              fontWeight: FontWeight.bold,
              shadows: CBColors.textGlow(color, intensity: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Delete “${session.sessionName}”? This cannot be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
          if (session.isActive) ...[
            const SizedBox(height: 10),
            Text(
              'This is the ACTIVE session. Deleting it will remove the session wrapper for the current Games Night.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
                height: 1.3,
              ),
            ),
          ],
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
                label: 'DELETE',
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

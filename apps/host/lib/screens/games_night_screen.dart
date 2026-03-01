import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
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

    await ref.read(gamesNightProvider.notifier).refreshSession();
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(gamesNightProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBPrismScaffold(
      title: 'OPERATIONS LOG',
      actions: const [SimulationModeBadgeAction()],
      drawer:
          const CustomDrawer(currentDestination: HostDestination.gamesNight),
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
                      title: 'ACTIVE OPERATIONS',
                      icon: Icons.play_circle_outline_rounded,
                      color: scheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: CBSpace.x4),
                  CBFadeSlide(
                    delay: const Duration(milliseconds: 100),
                    child: _buildActiveSessionPanel(
                        context, activeSession, scheme, textTheme),
                  ),
                  const SizedBox(height: CBSpace.x8),
                  CBFadeSlide(
                    delay: const Duration(milliseconds: 200),
                    child: CBSectionHeader(
                      title: 'ARCHIVED SESSIONS',
                      icon: Icons.history_rounded,
                      color: scheme.primary,
                      count: _sessions.where((s) => !s.isActive).length,
                    ),
                  ),
                  const SizedBox(height: CBSpace.x4),
                  if (_sessions.where((s) => !s.isActive).isEmpty)
                    CBFadeSlide(
                      delay: const Duration(milliseconds: 250),
                      child: CBPanel(
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
                              'COMPLETE A SESSION TO BEGIN ARCHIVING HISTORY.',
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
                    ..._sessions.asMap().entries.where((entry) => !entry.value.isActive).map((entry) {
                      final index = entry.key;
                      final session = entry.value;
                      return CBFadeSlide(
                        delay: Duration(milliseconds: 50 * index.clamp(0, 10) + 250),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: CBSpace.x3),
                          child: _buildSessionDismissibleTile(context, session, scheme, textTheme),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveSessionPanel(
    BuildContext context,
    GamesNightRecord? session,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    if (session == null || !session.isActive) {
      return CBPanel(
        padding: const EdgeInsets.all(CBSpace.x6),
        borderColor: scheme.outlineVariant.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'NO ACTIVE SESSION',
              style: textTheme.labelLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: CBSpace.x3),
            Text(
              'INITIATE A NEW OPERATIONS SESSION TO LINK MULTIPLE GAME ROUNDS.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
                height: 1.4,
              ),
            ),
            const SizedBox(height: CBSpace.x5),
            CBPrimaryButton(
              label: 'INITIATE NEW SESSION',
              icon: Icons.add_circle_outline_rounded,
              onPressed: () async {
                HapticService.medium();
                final name = await showStartSessionDialog(context);
                if (name == null || name.trim().isEmpty) return;
                await ref
                    .read(gamesNightProvider.notifier)
                    .startSession(name.trim());
                await _loadData();
              },
            ),
          ],
        ),
      );
    }

    final games = _gamesForSession(session);
    final date = DateFormat('MMM dd, yyyy').format(session.startedAt);

    return CBGlassTile(
      padding: const EdgeInsets.all(CBSpace.x5),
      borderColor: scheme.tertiary.withValues(alpha: 0.5),
      isPrismatic: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CBBadge(
                text: 'ACTIVE',
                color: scheme.tertiary,
                icon: Icons.bolt_rounded,
              ),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: Text(
                  session.sessionName.toUpperCase(),
                  style: textTheme.headlineSmall?.copyWith(
                    color: scheme.tertiary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    shadows: CBColors.textGlow(scheme.tertiary, intensity: 0.3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CBSpace.x3),
          Text(
            'INITIATED: $date'.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.0,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: CBSpace.x3),
          Row(
            children: [
              Icon(Icons.videogame_asset_rounded, size: 16, color: scheme.primary.withValues(alpha: 0.7)),
              const SizedBox(width: CBSpace.x2),
              Text(
                '${session.gameIds.length} MISSION${session.gameIds.length == 1 ? '' : 'S'}',
                style: textTheme.bodySmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: CBSpace.x5),
              Icon(Icons.people_alt_rounded, size: 16, color: scheme.secondary.withValues(alpha: 0.7)),
              const SizedBox(width: CBSpace.x2),
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
          const SizedBox(height: CBSpace.x5),
          Row(
            children: [
              Expanded(
                child: CBPrimaryButton(
                  label: 'START NEXT MISSION',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    HapticService.medium();
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
                  label: 'TERMINATE SESSION',
                  icon: Icons.power_off_rounded,
                  color: scheme.error,
                  onPressed: () async {
                    HapticService.heavy();
                    final confirmed = await _confirmEndSession(
                        context, scheme.error);
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
                  icon: Icons.insights_rounded,
                  color: scheme.primary,
                  onPressed: () {
                    HapticService.selection();
                    if (games.isEmpty) {
                      showThemedSnackBar(
                        context,
                        'NO RECAP YET — COMPLETE AT LEAST 1 MISSION IN THIS SESSION.',
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
    TextTheme textTheme,
  ) {
    final games = _gamesForSession(session);
    final date = DateFormat.yMMMd().format(session.startedAt);

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: CBSpace.x6),
        margin: const EdgeInsets.only(bottom: CBSpace.x3),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(CBRadius.md),
        ),
        child: Icon(Icons.delete_forever_rounded,
            color: scheme.onError, size: 28),
      ),
      confirmDismiss: (direction) async {
        HapticService.heavy();
        return await showConfirmationDialog(
          context,
          title: 'DELETE ARCHIVED SESSION?',
          content:
              'ARE YOU SURE YOU WANT TO DELETE SESSION "${session.sessionName.toUpperCase()}"? THIS CANNOT BE UNDONE. INDIVIDUAL MISSION LOGS WILL REMAIN.',
          confirmLabel: 'DELETE',
          confirmColor: scheme.error,
        );
      },
      onDismissed: (direction) async {
        HapticService.heavy();
        await PersistenceService.instance.deleteSession(session.id);
        await _loadData();
        if (context.mounted) {
          showThemedSnackBar(
              context, 'SESSION "${session.sessionName.toUpperCase()}" DELETED.');
        }
      },
      child: CBGlassTile(
        margin: const EdgeInsets.only(bottom: CBSpace.x3),
        padding: const EdgeInsets.all(CBSpace.x4),
        borderColor: scheme.outlineVariant.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(CBSpace.x2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(Icons.history_edu_rounded, color: scheme.primary, size: 20),
                ),
                const SizedBox(width: CBSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.sessionName.toUpperCase(),
                        style: textTheme.titleMedium!.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: CBSpace.x2),
                      Text(
                        '${session.gameIds.length} MISSIONS • $date'.toUpperCase(),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          letterSpacing: 0.5,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                CBPrimaryButton(
                  label: 'VIEW RECAP',
                  icon: Icons.insights_rounded,
                  fullWidth: false,
                  onPressed: () {
                    HapticService.selection();
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
      accentColor: color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TERMINATE ACTIVE SESSION',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall!.copyWith(
              color: color,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
              shadows: CBColors.textGlow(color, intensity: 0.6),
            ),
          ),
          const SizedBox(height: CBSpace.x4),
          Text(
            'CONFIRM TERMINATION OF ACTIVE SESSION "${ref.read(gamesNightProvider)?.sessionName.toUpperCase() ?? ''}"? THIS WILL FINALIZE THE RECAP.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.75),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'ABORT',
                onPressed: () {
                  HapticService.light();
                  Navigator.of(context).pop(false);
                },
              ),
              const SizedBox(width: CBSpace.x3),
              CBPrimaryButton(
                label: 'CONFIRM TERMINATION',
                backgroundColor: color,
                onPressed: () {
                  HapticService.heavy();
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

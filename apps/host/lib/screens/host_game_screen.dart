import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_destinations.dart';
import '../host_navigation.dart';
import '../host_settings.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';
import '../widgets/host_main_feed.dart';
import '../widgets/script_step_panel.dart';
import 'dashboard_view.dart';
import 'end_game_view.dart';
import 'stats_view.dart';

/// Phone-first game control screen using a tabbed layout (Feed + Nerve Centre).
/// Benchmarked for Google Pixel 10 Pro.
class HostGameScreen extends ConsumerStatefulWidget {
  const HostGameScreen({super.key});

  @override
  ConsumerState<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends ConsumerState<HostGameScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isGeneratingNarration = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _triggerNightNarration() async {
    if (_isGeneratingNarration) return;
    final settings = ref.read(hostSettingsProvider);
    if (!settings.geminiNarrationEnabled) return;
    if (!ref.read(geminiNarrationServiceProvider).hasApiKey) return;

    setState(() => _isGeneratingNarration = true);
    try {
      final controller = ref.read(gameProvider.notifier);

      final narrations = await controller.generateDualTrackNightNarration(
        personalityId: settings.hostPersonalityId,
      );

      final playerNarration = narrations['player'];
      if (playerNarration != null && playerNarration.trim().isNotEmpty) {
        controller.dispatchBulletin(
          title: 'AI NARRATOR',
          content: playerNarration,
          type: 'result',
        );
      }

      final hostNarration = narrations['host'];
      if (hostNarration != null && hostNarration.trim().isNotEmpty) {
        controller.dispatchBulletin(
          title: 'AI NARRATOR (SPICY)',
          content: hostNarration,
          type: 'result',
          isHostOnly: true,
        );
      }
    } catch (e) {
      debugPrint('[HostGameScreen] AI narration failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingNarration = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final nav = ref.read(hostNavigationProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    ref.listen(gameProvider.select((s) => s.phase), (previous, next) {
      if (previous == GamePhase.night && next == GamePhase.day) {
        _triggerNightNarration();
      }
    });

    if (gameState.phase == GamePhase.endGame) {
      return CBPrismScaffold(
        title: 'GAME RECAP',
        body: EndGameView(
          gameState: gameState,
          controller: controller,
          onReturnToLobby: () {
            controller.returnToLobby();
            nav.setDestination(HostDestination.lobby);
          },
          onRematchWithPlayers: () {
            controller.returnToLobbyWithPlayers();
            nav.setDestination(HostDestination.lobby);
          },
        ),
      );
    }

    final hasScript = gameState.currentStep != null &&
        gameState.scriptQueue.isNotEmpty;

    return CBPrismScaffold(
      title: 'GAME CONTROL',
      drawer: const CustomDrawer(currentDestination: HostDestination.game),
      actions: [
        IconButton(
          tooltip: 'View Analytics',
          icon: const Icon(Icons.analytics_outlined),
          onPressed: () {
            showThemedDialog(
              context: context,
              child: StatsView(
                gameState: gameState,
                onOpenCommand: () => Navigator.of(context).pop(),
              ),
            );
          },
        ),
        const SimulationModeBadgeAction(),
      ],
      appBarBottom: TabBar(
        controller: _tabController,
        indicatorColor: scheme.primary,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.5),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontSize: 11,
        ),
        tabs: const [
          Tab(text: 'FEED', icon: Icon(Icons.forum_rounded, size: 18)),
          Tab(
              text: 'NERVE CENTRE',
              icon: Icon(Icons.radar_rounded, size: 18)),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Feed (Script Step + Main Feed)
          Column(
            children: [
              if (gameState.phase == GamePhase.setup)
                _RoleConfirmationBar(
                  players: gameState.players,
                  confirmedIds: ref.watch(sessionProvider).roleConfirmedPlayerIds,
                ),
              if (hasScript) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: ScriptStepPanel(
                    gameState: gameState,
                    controller: controller,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Expanded(
                child: HostMainFeed(gameState: gameState),
              ),
            ],
          ),

          // Tab 2: Nerve Centre Dashboard
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: DashboardView(
                    gameState: gameState,
                    onAction: controller.advancePhase,
                    onAddMock: controller.addBot,
                    eyesOpen: gameState.eyesOpen,
                    onToggleEyes: controller.toggleEyes,
                    onBack: () => nav.setDestination(HostDestination.lobby),
                  ),
                ),
              ),
              _PersistentPhaseBar(
                gameState: gameState,
                onAction: controller.advancePhase,
                onToggleEyes: controller.toggleEyes,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersistentPhaseBar extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onAction;
  final Function(bool) onToggleEyes;

  const _PersistentPhaseBar({
    required this.gameState,
    required this.onAction,
    required this.onToggleEyes,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLobby = gameState.phase == GamePhase.lobby;
    final isEndGame = gameState.phase == GamePhase.endGame;
    if (isEndGame) return const SizedBox.shrink();

    final phaseLabel = switch (gameState.phase) {
      GamePhase.lobby => 'LOBBY',
      GamePhase.setup => 'SETUP',
      GamePhase.night => 'NIGHT ${gameState.dayCount}',
      GamePhase.day => 'DAY ${gameState.dayCount}',
      GamePhase.resolution => 'RESOLUTION',
      GamePhase.endGame => 'END',
    };
    final phaseColor = switch (gameState.phase) {
      GamePhase.night => scheme.secondary,
      GamePhase.day => scheme.tertiary,
      _ => scheme.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: phaseColor.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: phaseColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: phaseColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                phaseLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: phaseColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!isLobby)
              IconButton(
                onPressed: () => onToggleEyes(!gameState.eyesOpen),
                tooltip: gameState.eyesOpen ? 'Eyes Open' : 'Eyes Closed',
                icon: Icon(
                  gameState.eyesOpen
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
              ),
            if (gameState.scriptQueue.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                '${gameState.scriptIndex + 1}/${gameState.scriptQueue.length}',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onAction();
              },
              icon: const Icon(Icons.fast_forward_rounded, size: 18),
              label: Text(
                isLobby ? 'START' : 'ADVANCE',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ROLE CONFIRMATION BAR ──────────────────────────────────

class _RoleConfirmationBar extends StatelessWidget {
  final List<Player> players;
  final List<String> confirmedIds;

  const _RoleConfirmationBar({
    required this.players,
    required this.confirmedIds,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final humanPlayers = players.where((p) => !p.isBot).toList();
    final total = humanPlayers.length;
    final confirmed =
        humanPlayers.where((p) => confirmedIds.contains(p.id)).length;
    final allDone = confirmed >= total && total > 0;
    final progress = total > 0 ? confirmed / total : 0.0;
    final pending =
        humanPlayers.where((p) => !confirmedIds.contains(p.id)).toList();

    final accentColor = allDone ? scheme.tertiary : scheme.secondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: CBGlassTile(
        isPrismatic: allDone,
        borderColor: accentColor.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  allDone
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_top_rounded,
                  size: 18,
                  color: accentColor,
                ),
                const SizedBox(width: 10),
                Text(
                  'ROLE CONFIRMATIONS',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontSize: 9,
                  ),
                ),
                const Spacer(),
                Text(
                  '$confirmed / $total',
                  style: textTheme.titleSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: pending.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: scheme.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      p.name.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontSize: 9,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'ALL PLAYERS CONFIRMED — READY TO PROCEED',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.tertiary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

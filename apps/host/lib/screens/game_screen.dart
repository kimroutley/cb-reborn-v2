import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_view.dart';
import '../host_settings.dart';
import '../widgets/game_bottom_controls.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  String? _firstPickId; // For two-player selection
  final ScrollController _scrollController = ScrollController();
  int _lastFeedLength = 0;
  late TabController _tabController;
  bool _isGeneratingAiNarration = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final gameState = ref.watch(gameProvider);
    // Auto-scroll when new feed events appear
    if (gameState.feedEvents.length != _lastFeedLength) {
      _lastFeedLength = gameState.feedEvents.length;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: CBMotion.micro,
          curve: CBMotion.emphasizedCurve,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final gameState = ref.watch(gameProvider);
    final hostSettings = ref.watch(hostSettingsProvider);
    final controller = ref.read(gameProvider.notifier);
    final hostSettingsNotifier = ref.read(hostSettingsProvider.notifier);
    final step = gameState.currentStep;

    if (step == null && gameState.feedEvents.isEmpty) {
      return CBPrismScaffold(
        title: 'GAME CONTROL',
        drawer: const CustomDrawer(),
        actions: const [SimulationModeBadgeAction()],
        body: Center(
          child: Text('NO SCRIPT', style: textTheme.labelMedium!),
        ),
      );
    }

    return CBPrismScaffold(
      title: 'GAME CONTROL',
      drawer: const CustomDrawer(),
      showAppBar: true,
      actions: [
        const SimulationModeBadgeAction(),
        IconButton(
          tooltip: hostSettings.geminiNarrationEnabled
              ? 'Gemini narration is ON'
              : 'Gemini narration is OFF',
          icon: Icon(
            hostSettings.geminiNarrationEnabled
                ? Icons.auto_awesome_rounded
                : Icons.auto_awesome_outlined,
            color: hostSettings.geminiNarrationEnabled
                ? scheme.tertiary
                : scheme.onSurfaceVariant,
          ),
          onPressed: () {
            final nextValue = !hostSettings.geminiNarrationEnabled;
            hostSettingsNotifier.setGeminiNarrationEnabled(nextValue);
            showThemedSnackBar(
              context,
              nextValue
                  ? 'Gemini narration enabled (AI variation).'
                  : 'Gemini narration disabled (standard script).',
              accentColor: nextValue ? scheme.tertiary : scheme.secondary,
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.history_rounded),
          onPressed: () {
            _tabController.animateTo(1);
            // Scroll to logs in dashboard
          },
        ),
      ],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: scheme.primary.withValues(alpha: 0.14)),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
                text: 'FEED',
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 20)),
            Tab(
                text: 'DASHBOARD',
                icon: Icon(Icons.dashboard_outlined, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGameFeed(
            context,
            gameState,
            step,
            controller,
            hostSettings.geminiNarrationEnabled,
          ),
          DashboardView(
            gameState: gameState,
          ),
        ],
      ),
    );
  }

  Widget _buildGameFeed(
    BuildContext context,
    GameState gameState,
    ScriptStep? step,
    Game controller,
    bool geminiNarrationEnabled,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (geminiNarrationEnabled
                        ? scheme.tertiary
                        : scheme.secondary)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: geminiNarrationEnabled
                      ? scheme.tertiary.withValues(alpha: 0.45)
                      : scheme.secondary.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                geminiNarrationEnabled
                    ? 'NARRATION MODE: AI'
                    : 'NARRATION MODE: STANDARD',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                      color: geminiNarrationEnabled
                          ? scheme.tertiary
                          : scheme.secondary,
                    ),
              ),
            ),
          ),
        ),
        // ── SCROLLABLE CHAT FEED ──
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: gameState.feedEvents.length +
                (step != null ? _liveWidgetCount(step) : 0),
            itemBuilder: (context, index) {
              // Past feed events
              if (index < gameState.feedEvents.length) {
                final event = gameState.feedEvents[index];
                // Cluster: same roleId as previous non-system event
                final isClustered = index > 0 &&
                    event.roleId != null &&
                    event.type != FeedEventType.system &&
                    gameState.feedEvents[index - 1].roleId == event.roleId &&
                    gameState.feedEvents[index - 1].type !=
                        FeedEventType.system;
                return _buildFeedBubble(gameState, event,
                    isClustered: isClustered);
              }
              // Live current step widgets (rendered after feed history)
              final liveIndex = index - gameState.feedEvents.length;
              return _buildLiveStepWidget(
                  context, gameState, step!, liveIndex, controller);
            },
          ),
        ),

        // ── BOTTOM CONTROLS ──
        GameBottomControls(
          step: step,
          controller: controller,
          firstPickId: _firstPickId,
          onConfirm: () => setState(() => _firstPickId = null),
          onContinue: () => _handleContinuePressed(
            controller,
            geminiNarrationEnabled,
          ),
        ),
      ],
    );
  }

  Future<void> _handleContinuePressed(
    Game controller,
    bool geminiNarrationEnabled,
  ) async {
    if (_isGeneratingAiNarration) {
      return;
    }

    if (!geminiNarrationEnabled) {
      controller.advancePhase();
      return;
    }

    setState(() => _isGeneratingAiNarration = true);
    await controller.prepareCurrentStepNarrationOverrideWithAi();
    if (!mounted) return;
    setState(() => _isGeneratingAiNarration = false);

    controller.advancePhase();
  }

  int _liveWidgetCount(ScriptStep step) {
    if (step.actionType == ScriptActionType.phaseTransition) return 1;
    if (step.actionType == ScriptActionType.info) return 1;
    if (step.actionType == ScriptActionType.selectPlayer) {
      return 2; // Title + Grid
    }
    return 0;
  }

  Widget _buildLiveStepWidget(BuildContext context, GameState gameState,
      ScriptStep step, int index, Game controller) {
    final scheme = Theme.of(context).colorScheme;
    switch (step.actionType) {
      case ScriptActionType.phaseTransition:
        return CBPhaseInterrupt(
          title: step.title,
          accentColor: scheme.primary,
          icon: Icons.shield,
          onDismiss: () {},
        );
      case ScriptActionType.info:
        return CBMessageBubble(
          variant: CBMessageVariant.system,
          content: step.title,
          accentColor: scheme.secondary,
        );
      case ScriptActionType.selectPlayer:
        if (index == 0) {
          return CBMessageBubble(
            variant: CBMessageVariant.system,
            content: step.title,
            accentColor: scheme.primary,
          );
        }
        return _buildPlayerSelectionGrid(step, gameState, controller);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlayerSelectionGrid(
      ScriptStep step, GameState gameState, Game controller) {
    final eligiblePlayers = gameState.players.where((p) => p.isAlive).toList();
    final maxSelections =
        step.actionType == ScriptActionType.selectTwoPlayers ? 2 : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: eligiblePlayers.map((p) {
          final isSelected = _firstPickId == p.id;
          return CBCompactPlayerChip(
            name: p.name,
            color: RoleColorExtension(p.role).color,
            isSelected: isSelected,
            onTap: () {
              if (maxSelections == 1) {
                controller.handleInteraction(stepId: step.id, targetId: p.id);
              } else {
                setState(() {
                  if (isSelected) {
                    _firstPickId = null;
                  }
                  _firstPickId = p.id;
                });
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedBubble(GameState gameState, FeedEvent event,
      {bool isClustered = false}) {
    final player = gameState.players.firstWhere(
      (p) => p.role.id == event.roleId,
      orElse: () => Player(
        id: 'unassigned',
        name: 'Unassigned',
        role: Role(
          id: 'unassigned',
          name: 'Unassigned',
          alliance: Team.unknown,
          type: '',
          description: '',
          nightPriority: 0,
          assetPath: '',
          colorHex: '#888888',
        ),
        alliance: Team.unknown,
      ),
    );

    final role = player.role;

    return CBMessageBubble(
      variant: event.type.toMessageVariant(),
      playerHeader: CBPlayerStatusTile(
        playerName: player.name,
        roleName: role.name,
        assetPath: role.assetPath,
        roleColor: RoleColorExtension(role).color,
        isAlive: player.isAlive,
        statusEffects: player.statusEffects,
      ),
      content: event.content,
      accentColor: RoleColorExtension(role).color,
      isClustered: isClustered,
    );
  }
}

extension RoleColorExtension on Role {
  Color get color {
    final buffer = StringBuffer();
    if (colorHex.length == 6 || colorHex.length == 7) buffer.write('ff');
    buffer.write(colorHex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

extension on FeedEventType {
  CBMessageVariant toMessageVariant() {
    switch (this) {
      case FeedEventType.narrative:
        return CBMessageVariant.narrative;
      case FeedEventType.directive:
        return CBMessageVariant.system;
      case FeedEventType.action:
        return CBMessageVariant.system;
      case FeedEventType.system:
        return CBMessageVariant.system;
      case FeedEventType.result:
        return CBMessageVariant.result;
      case FeedEventType.timer:
        return CBMessageVariant.system;
    }
  }
}

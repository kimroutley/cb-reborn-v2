import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_settings.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/game_bottom_controls.dart';
import '../widgets/game_feed_list.dart';
import '../widgets/narration_mode_badge.dart';
import '../widgets/simulation_mode_badge_action.dart';
import 'dashboard_view.dart';

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
    return Column(
      children: [
        NarrationModeBadge(geminiNarrationEnabled: geminiNarrationEnabled),
        // ── SCROLLABLE CHAT FEED ──
        GameFeedList(
          scrollController: _scrollController,
          gameState: gameState,
          step: step,
          controller: controller,
          firstPickId: _firstPickId,
          onFirstPickChanged: (id) => setState(() => _firstPickId = id),
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

}

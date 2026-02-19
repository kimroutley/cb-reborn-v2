import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_destinations.dart';
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
  final ScrollController _scrollController = ScrollController();
  int _lastFeedLength = 0;
  late TabController _tabController;
  final bool _isGeneratingAiNarration = false;

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
    final gameState = ref.watch(gameProvider);
    final hostSettings = ref.watch(hostSettingsProvider);
    final controller = ref.read(gameProvider.notifier);
    final hostSettingsNotifier = ref.read(hostSettingsProvider.notifier);
    final step = gameState.currentStep;

    if (step == null && gameState.feedEvents.isEmpty) {
      return CBPrismScaffold(
        title: 'GAME CONTROL',
        actions: const [SimulationModeBadgeAction()],
        drawer: const CustomDrawer(currentDestination: HostDestination.game),
        body: Center(
          child: Text('NO SCRIPT', style: textTheme.labelMedium!),
        ),
      );
    }

    return CBPrismScaffold(
      title: 'GAME CONTROL',
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
          ),
          onPressed: () {
            hostSettingsNotifier.toggleGeminiNarration();
          },
        ),
      ],
      appBarBottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'FEED', icon: Icon(Icons.dynamic_feed_rounded)),
          Tab(text: 'DASHBOARD', icon: Icon(Icons.dashboard_rounded)),
        ],
      ),
      drawer: const CustomDrawer(currentDestination: HostDestination.game),
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
          DashboardView(gameState: gameState),
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
        Expanded(
          child: GameFeedList(
            scrollController: _scrollController,
            gameState: gameState,
            step: step,
            controller: controller,
          ),
        ),
        if (_isGeneratingAiNarration)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: NarrationModeBadge(
              geminiNarrationEnabled: geminiNarrationEnabled,
            ),
          ),
        GameBottomControls(
          step: step,
          gameState: gameState,
          controller: controller,
          onConfirm: () {
            controller.advancePhase();
          },
          onContinue: () async {
            controller.advancePhase();
          },
        ),
      ],
    );
  }
}

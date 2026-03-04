import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/dashboard/ai_export_panel.dart';
import '../widgets/dashboard/director_commands.dart';
import '../widgets/dashboard/enhanced_logs_panel.dart';
import '../widgets/dashboard/god_mode_controls.dart';
import '../widgets/dashboard/live_intel_panel.dart';
import '../widgets/bottom_controls.dart';

/// Host Command Center - Tactical Dashboard with God Mode and Analytics
class DashboardView extends ConsumerWidget {
  final GameState gameState;
  final VoidCallback onAction;
  final VoidCallback onAddMock;
  final bool eyesOpen;
  final Function(bool) onToggleEyes;
  final VoidCallback onBack;

  const DashboardView({
    super.key,
    required this.gameState,
    required this.onAction,
    required this.onAddMock,
    required this.eyesOpen,
    required this.onToggleEyes,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isInGame = gameState.phase != GamePhase.lobby &&
        gameState.phase != GamePhase.endGame;

    return Padding(
      padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x4, CBSpace.x4, CBSpace.x12),
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        CBFadeSlide(
          child: CBSectionHeader(
            title: 'HOST COMMAND CENTRE',
            color: scheme.primary,
            icon: Icons.dashboard_customize_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x6),

        // Live Intel
        if (gameState.phase != GamePhase.lobby) ...[
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: LiveIntelPanel(players: gameState.players),
          ),
          const SizedBox(height: CBSpace.x6),
        ],

        // God Mode Control Panel
        if (isInGame) ...[
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: GodModeControls(gameState: gameState),
          ),
          const SizedBox(height: CBSpace.x6),
        ],

        // Director Commands
        CBFadeSlide(
          delay: const Duration(milliseconds: 300),
          child: DirectorCommands(gameState: gameState),
        ),
        const SizedBox(height: CBSpace.x6),

        // Enhanced Logs
        CBFadeSlide(
          delay: const Duration(milliseconds: 400),
          child: EnhancedLogsPanel(logs: gameState.gameHistory),
        ),
        const SizedBox(height: CBSpace.x6),

        // AI Export
        const CBFadeSlide(
          delay: Duration(milliseconds: 500),
          child: AIExportPanel(),
        ),
        const SizedBox(height: CBSpace.x8),

        CBFadeSlide(
          delay: const Duration(milliseconds: 600),
          child: BottomControls(
            isLobby: gameState.phase == GamePhase.lobby,
            isEndGame: gameState.phase == GamePhase.endGame,
            playerCount: gameState.players.length,
            onAction: onAction,
            onAddMock: onAddMock,
            eyesOpen: eyesOpen,
            onToggleEyes: onToggleEyes,
            onBack: onBack,
          ),
        ),
        const SizedBox(height: CBSpace.x12),
      ],
      ),
    );
  }
}

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
    return ListView(
      padding: CBInsets.screen,
      children: [
        // Header
        CBSectionHeader(
          title: 'Host Command Center',
          color: scheme.primary,
          icon: Icons.dashboard_customize,
        ),
        const SizedBox(height: 24),

        // Live Intel
        if (gameState.phase != GamePhase.lobby) ...[
          LiveIntelPanel(players: gameState.players),
          const SizedBox(height: 24),
        ],

        // God Mode Control Panel
        if (gameState.phase != GamePhase.lobby &&
            gameState.phase != GamePhase.endGame) ...[
          GodModeControls(gameState: gameState),
          const SizedBox(height: 24),
        ],

        // Director Commands
        DirectorCommands(gameState: gameState),
        const SizedBox(height: 24),

        // Enhanced Logs
        EnhancedLogsPanel(logs: gameState.gameHistory),
        const SizedBox(height: 24),

        // AI Export
        const AIExportPanel(),
        const SizedBox(height: 24),

        BottomControls(
          isLobby: false,
          isEndGame: false,
          playerCount: gameState.players.length,
          onAction: onAction,
          onAddMock: onAddMock,
          eyesOpen: eyesOpen,
          onToggleEyes: onToggleEyes,
          onBack: onBack,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/dashboard/ai_export_panel.dart';
import '../widgets/dashboard/bar_tab_panel.dart';
import '../widgets/dashboard/dead_pool_intel_panel.dart';
import '../widgets/dashboard/director_commands.dart';
import '../widgets/dashboard/enhanced_logs_panel.dart';
import '../widgets/dashboard/god_mode_controls.dart';
import '../widgets/dashboard/live_intel_panel.dart';
import '../widgets/dashboard/night_action_intel_panel.dart';
import '../widgets/dashboard/quick_settings_panel.dart';
import '../widgets/dashboard/vote_intel_panel.dart';

/// Host Command Center - Tactical Dashboard with God Mode and Analytics.
/// Phone-first layout: critical intel up top, secondary panels collapsible.
/// BottomControls live in the persistent _PersistentPhaseBar in HostGameScreen.
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
    final isInGame = gameState.phase != GamePhase.lobby &&
        gameState.phase != GamePhase.endGame;
    final isNight = gameState.phase == GamePhase.night;
    final isDay = gameState.phase == GamePhase.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── PRIMARY INTEL (always visible) ──
        if (isInGame) ...[
          LiveIntelPanel(gameState: gameState),
          const SizedBox(height: 12),
        ],

        if (isDay) ...[
          VoteIntelPanel(gameState: gameState),
          const SizedBox(height: 12),
        ],

        if (isNight ||
            (isDay && gameState.lastNightReport.isNotEmpty)) ...[
          NightActionIntelPanel(gameState: gameState),
          const SizedBox(height: 12),
        ],

        // ── GOD MODE (critical, always visible) ──
        GodModeControls(gameState: gameState),
        const SizedBox(height: 12),

        // ── SECONDARY PANELS (collapsible on phone) ──
        if (isInGame) ...[
          _CollapsibleSection(
            title: 'DEAD POOL INTEL',
            icon: Icons.whatshot_rounded,
            initiallyExpanded: false,
            child: DeadPoolIntelPanel(gameState: gameState),
          ),
          const SizedBox(height: 8),
        ],

        _CollapsibleSection(
          title: 'BAR TAB',
          icon: Icons.local_bar_rounded,
          initiallyExpanded: false,
          child: BarTabPanel(gameState: gameState),
        ),
        const SizedBox(height: 8),

        _CollapsibleSection(
          title: 'POWER TRIPS',
          icon: Icons.flash_on_rounded,
          initiallyExpanded: false,
          child: DirectorCommands(gameState: gameState),
        ),
        const SizedBox(height: 8),

        _CollapsibleSection(
          title: 'CONTROL ROOM',
          icon: Icons.tune_rounded,
          initiallyExpanded: false,
          child: QuickSettingsPanel(gameState: gameState),
        ),
        const SizedBox(height: 8),

        _CollapsibleSection(
          title: 'SESSION LOGS',
          icon: Icons.history_edu_rounded,
          initiallyExpanded: false,
          child: EnhancedLogsPanel(logs: gameState.gameHistory),
        ),
        const SizedBox(height: 8),

        const _CollapsibleSection(
          title: 'AI EXPORT',
          icon: Icons.auto_awesome,
          initiallyExpanded: false,
          child: AIExportPanel(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool initiallyExpanded;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = true,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _animController;
  late final Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: _expanded ? 1.0 : 0.0,
    );
    _rotationAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _expanded
                    ? scheme.primary.withValues(alpha: 0.3)
                    : scheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(widget.icon,
                    size: 16,
                    color: _expanded
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: textTheme.labelSmall?.copyWith(
                      color: _expanded
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                RotationTransition(
                  turns: _rotationAnim,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: widget.child,
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

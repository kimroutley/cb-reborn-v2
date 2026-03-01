import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_theme/cb_theme.dart'; // Import cb_theme for CBFadeSlide and CBSpace

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
          CBFadeSlide(
            child: LiveIntelPanel(gameState: gameState),
          ),
          const SizedBox(height: CBSpace.x3),
        ],

        if (isDay) ...[
          CBFadeSlide(
            delay: const Duration(milliseconds: 50),
            child: VoteIntelPanel(gameState: gameState),
          ),
          const SizedBox(height: CBSpace.x3),
        ],

        if (isNight ||
            (isDay && gameState.lastNightReport.isNotEmpty)) ...[
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: NightActionIntelPanel(gameState: gameState),
          ),
          const SizedBox(height: CBSpace.x3),
        ],

        // ── GOD MODE (critical, always visible) ──
        CBFadeSlide(
          delay: const Duration(milliseconds: 150),
          child: GodModeControls(gameState: gameState),
        ),
        const SizedBox(height: CBSpace.x3),

        // ── SECONDARY PANELS (collapsible on phone) ──
        if (isInGame) ...[
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: _CollapsibleSection(
              title: 'DEAD POOL INTEL',
              icon: Icons.whatshot_rounded,
              initiallyExpanded: false,
              child: DeadPoolIntelPanel(gameState: gameState),
            ),
          ),
          const SizedBox(height: CBSpace.x2),
        ],

        CBFadeSlide(
          delay: const Duration(milliseconds: 250),
          child: _CollapsibleSection(
            title: 'BAR TAB',
            icon: Icons.local_bar_rounded,
            initiallyExpanded: false,
            child: BarTabPanel(gameState: gameState),
          ),
        ),
        const SizedBox(height: CBSpace.x2),

        CBFadeSlide(
          delay: const Duration(milliseconds: 300),
          child: _CollapsibleSection(
            title: 'POWER TRIPS',
            icon: Icons.flash_on_rounded,
            initiallyExpanded: false,
            child: DirectorCommands(gameState: gameState),
          ),
        ),
        const SizedBox(height: CBSpace.x2),

        CBFadeSlide(
          delay: const Duration(milliseconds: 350),
          child: _CollapsibleSection(
            title: 'CONTROL ROOM',
            icon: Icons.tune_rounded,
            initiallyExpanded: false,
            child: QuickSettingsPanel(gameState: gameState),
          ),
        ),
        const SizedBox(height: CBSpace.x2),

        CBFadeSlide(
          delay: const Duration(milliseconds: 400),
          child: _CollapsibleSection(
            title: 'SESSION LOGS',
            icon: Icons.history_edu_rounded,
            initiallyExpanded: false,
            child: EnhancedLogsPanel(logs: gameState.gameHistory),
          ),
        ),
        const SizedBox(height: CBSpace.x2),

        CBFadeSlide(
          delay: const Duration(milliseconds: 450),
          child: const _CollapsibleSection(
            title: 'AI EXPORT',
            icon: Icons.auto_awesome,
            initiallyExpanded: false,
            child: AIExportPanel(),
          ),
        ),
        const SizedBox(height: CBSpace.x6),
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
      duration: const Duration(milliseconds: 250),
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
    HapticService.selection();
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
        CBGlassTile(
          onTap: _toggle,
          padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: CBSpace.x3),
          borderColor: _expanded
              ? scheme.primary.withValues(alpha: 0.4)
              : scheme.outlineVariant.withValues(alpha: 0.2),
          child: Row(
            children: [
              Icon(widget.icon,
                  size: 18,
                  color: _expanded
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: Text(
                  widget.title.toUpperCase(),
                  style: textTheme.labelMedium?.copyWith(
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
                  Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: scheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.only(top: CBSpace.x2),
            child: widget.child,
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 250),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

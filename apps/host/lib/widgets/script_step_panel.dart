import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_settings.dart';

class ScriptStepPanel extends ConsumerStatefulWidget {
  final GameState gameState;
  final Game controller;

  const ScriptStepPanel({
    super.key,
    required this.gameState,
    required this.controller,
  });

  @override
  ConsumerState<ScriptStepPanel> createState() => _ScriptStepPanelState();
}

class _ScriptStepPanelState extends ConsumerState<ScriptStepPanel> {
  bool _isAiLoading = false;
  String? _aiVariation;
  String? _aiVariationStepId;
  String? _lastAutoNarratedStepId;

  Future<void> _regenerateWithAi() async {
    final settings = ref.read(hostSettingsProvider);
    if (!settings.geminiNarrationEnabled) return;
    if (!ref.read(geminiNarrationServiceProvider).hasApiKey) return;

    setState(() => _isAiLoading = true);
    try {
      final step = widget.gameState.currentStep;
      String? text;

      if (step != null && step.id.startsWith('day_results_')) {
        text = await _generateNightReport();
      } else {
        text = await widget.controller.generateCurrentStepNarrationText(
          personalityId: settings.hostPersonalityId,
        );
      }

      if (text != null && text.trim().isNotEmpty && mounted) {
        setState(() {
          _aiVariation = text;
          _aiVariationStepId = widget.gameState.currentStep?.id;
          _isAiLoading = false;
        });
        HapticFeedback.mediumImpact();
      } else if (mounted) {
        setState(() => _isAiLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  Future<String?> _generateNightReport() async {
    final settings = ref.read(hostSettingsProvider);
    return widget.controller.generateDynamicNightNarration(
      personalityId: settings.hostPersonalityId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(hostSettingsProvider);
    final step = widget.gameState.currentStep;
    final queueLength = widget.gameState.scriptQueue.length;
    final currentIndex = widget.gameState.scriptIndex;

    if (step == null || queueLength == 0) {
      return CBPanel(
        borderColor: scheme.outlineVariant.withValues(alpha: 0.3),
        child: Center(
          child: Text(
            'NO ACTIVE SCRIPT',
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }

    final isInteractive = step.actionType == ScriptActionType.selectPlayer ||
        step.actionType == ScriptActionType.selectTwoPlayers ||
        step.actionType == ScriptActionType.binaryChoice ||
        step.actionType == ScriptActionType.confirm ||
        step.actionType == ScriptActionType.optional ||
        step.actionType == ScriptActionType.multiSelect;

    final isVote = step.id.startsWith('day_vote');
    final isLastStep = currentIndex >= queueLength - 1;
    final hasAction = widget.gameState.actionLog.containsKey(step.id);
    final roleColor = step.roleId != null
        ? CBColors.fromHex(
            (roleCatalogMap[step.roleId]?.colorHex ?? '#4CC9F0'))
        : scheme.primary;
    final aiEnabled = settings.geminiNarrationEnabled &&
        ref.read(geminiNarrationServiceProvider).hasApiKey;

    // Auto-generate AI narration when a new step arrives
    if (aiEnabled &&
        step.readAloudText.isNotEmpty &&
        step.id != _lastAutoNarratedStepId) {
      _lastAutoNarratedStepId = step.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _regenerateWithAi();
      });
    }

    return CBPanel(
      borderColor: roleColor.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CBGlassTile(
            isPrismatic: isInteractive,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderColor: roleColor.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.terminal_rounded,
                        size: 16, color: roleColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.title,
                        style: textTheme.labelLarge?.copyWith(
                          color: roleColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    CBBadge(
                      text: '${currentIndex + 1}/$queueLength',
                      color: scheme.tertiary,
                    ),
                  ],
                ),
                if (step.roleId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'TARGET: ${roleCatalogMap[step.roleId]?.name.toUpperCase() ?? step.roleId!.toUpperCase()}',
                    style: textTheme.labelSmall?.copyWith(
                      color: roleColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (step.readAloudText.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (_aiVariation != null && _aiVariationStepId == step.id) ...[
              CBGlassTile(
                borderColor: scheme.tertiary.withValues(alpha: 0.4),
                isPrismatic: true,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 12, color: scheme.tertiary),
                        const SizedBox(width: 6),
                        Text(
                          'AI NARRATION',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.tertiary,
                            fontWeight: FontWeight.w900,
                            fontSize: 8,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _aiVariation!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.9),
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                step.readAloudText,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.35),
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ] else
              Text(
                step.readAloudText,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.85),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (aiEnabled) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 28,
                child: _isAiLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CBBreathingLoader(
                              size: 12, color: scheme.tertiary),
                          const SizedBox(width: 8),
                          Text(
                            'GENERATING AI VOICE...',
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.tertiary,
                              fontSize: 8,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      )
                    : CBGhostButton(
                        label: _aiVariation != null &&
                                _aiVariationStepId == step.id
                            ? 'REGENERATE'
                            : 'AI VOICE',
                        icon: Icons.auto_awesome_rounded,
                        color: scheme.tertiary,
                        onPressed: _regenerateWithAi,
                      ),
              ),
            ],
          ],
          if (step.instructionText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              step.instructionText,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          if (isInteractive && !isVote) ...[
            const SizedBox(height: 12),
            if (hasAction)
              CBGlassTile(
                padding: const EdgeInsets.all(8),
                borderColor: scheme.tertiary.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: scheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ACTION RECEIVED: ${widget.gameState.actionLog[step.id]}',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              CBGlassTile(
                padding: const EdgeInsets.all(8),
                borderColor: scheme.secondary.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    CBBreathingLoader(size: 14, color: scheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AWAITING PLAYER INPUT...',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.secondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 16),

          Row(
            children: [
              if (!isLastStep)
                Expanded(
                  child: CBPrimaryButton(
                    label: 'NEXT STEP',
                    icon: Icons.skip_next_rounded,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.controller.advanceStep();
                    },
                  ),
                ),
              if (!isLastStep) const SizedBox(width: 12),
              Expanded(
                child: isLastStep
                    ? CBPrimaryButton(
                        label: 'ADVANCE PHASE',
                        icon: Icons.fast_forward_rounded,
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          widget.controller.advancePhase();
                        },
                      )
                    : CBGhostButton(
                        label: 'ADVANCE PHASE',
                        icon: Icons.fast_forward_rounded,
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          widget.controller.advancePhase();
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

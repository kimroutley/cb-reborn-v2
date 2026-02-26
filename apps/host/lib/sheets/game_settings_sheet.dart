import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameSettingsSheet extends ConsumerStatefulWidget {
  const GameSettingsSheet({super.key});

  @override
  ConsumerState<GameSettingsSheet> createState() => _GameSettingsSheetState();
}

class _GameSettingsSheetState extends ConsumerState<GameSettingsSheet> {
  late final TextEditingController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = TextEditingController(
      text: ref.read(gameProvider).discussionTimerSeconds.toString(),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBGlassTile(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CBSectionHeader(
              title: 'GAME SETTINGS',
              icon: Icons.tune_rounded,
              color: scheme.primary,
            ),
            const SizedBox(height: 20),

            // Game Style
            Text(
              'GAME STYLE',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 8),
            ...GameStyle.values.map((style) {
              final isSelected = gameState.gameStyle == style;
              final styleColor = switch (style) {
                GameStyle.offensive => scheme.error,
                GameStyle.defensive => scheme.tertiary,
                GameStyle.reactive => scheme.secondary,
                GameStyle.manual => CBColors.alertOrange,
                GameStyle.chaos => scheme.primary,
              };
              final styleIcon = switch (style) {
                GameStyle.offensive => Icons.local_fire_department_rounded,
                GameStyle.defensive => Icons.shield_rounded,
                GameStyle.reactive => Icons.psychology_rounded,
                GameStyle.manual => Icons.touch_app_rounded,
                GameStyle.chaos => Icons.casino_rounded,
              };
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: CBGlassTile(
                  onTap: () {
                    HapticService.selection();
                    controller.setGameStyle(style);
                  },
                  isPrismatic: isSelected,
                  isSelected: isSelected,
                  borderColor: isSelected
                      ? styleColor
                      : scheme.outlineVariant.withValues(alpha: 0.2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(styleIcon, size: 18, color: styleColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              style.label.replaceAll('_', ' '),
                              style: textTheme.labelMedium?.copyWith(
                                color:
                                    isSelected ? styleColor : scheme.onSurface,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              style.description,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: styleColor,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Tie Breaks
            CBGlassTile(
              borderColor: scheme.outlineVariant.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.balance_rounded,
                      size: 18, color: scheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RANDOM TIE-BREAKS',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Tied votes pick a random exile.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value:
                        gameState.tieBreakStrategy == TieBreakStrategy.random,
                    activeTrackColor: scheme.primary,
                    onChanged: (value) {
                      HapticService.selection();
                      controller.setTieBreak(value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Discussion Timer
            CBGlassTile(
              borderColor: scheme.outlineVariant.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.timer_rounded,
                      size: 18, color: scheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'DISCUSSION TIMER',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: CBTextField(
                      controller: _timerController,
                      keyboardType: TextInputType.number,
                      onSubmitted: (value) {
                        final seconds = int.tryParse(value) ?? 300;
                        controller.setDiscussionTimer(seconds);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            CBPrimaryButton(
              label: 'DONE',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

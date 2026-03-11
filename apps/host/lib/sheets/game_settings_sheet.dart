import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameSettingsSheet extends ConsumerWidget {
  const GameSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(CBRadius.xl)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(CBSpace.x6),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CBBottomSheetHandle(),
              const SizedBox(height: CBSpace.x4),
              Row(
                children: [
                  Icon(Icons.tune_rounded, color: scheme.primary, size: 28),
                  const SizedBox(width: CBSpace.x3),
                  Expanded(
                    child: Text(
                      'HOST SETTINGS',
                      style: textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        shadows: CBColors.textGlow(scheme.primary, intensity: 0.3),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: CBSpace.x2),
              Text(
                'SYSTEM PARAMETERS ARE HOST-AUTHORITATIVE.',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.primary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: CBSpace.x6),

              // --- GAME STYLE ---
              CBSectionHeader(title: 'PRESET PROTOCOLS', icon: Icons.precision_manufacturing_rounded, color: scheme.secondary),
              const SizedBox(height: CBSpace.x3),
              CBPanel(
                borderColor: scheme.secondary.withValues(alpha: 0.4),
                child: DropdownButtonFormField<GameStyle>(
                  initialValue: currentState.gameStyle,
                  dropdownColor: scheme.surfaceContainerHighest,
                  icon: Icon(Icons.expand_more_rounded, color: scheme.secondary),
                  style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: scheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CBRadius.sm),
                      borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CBRadius.sm),
                      borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                    ),
                  ),
                  items: GameStyle.values.map((style) {
                    return DropdownMenuItem(
                      value: style,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            style.label.toUpperCase(),
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            style.description,
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      HapticService.selection();
                      controller.setGameStyle(value);
                    }
                  },
                  isExpanded: true,
                ),
              ),
              const SizedBox(height: CBSpace.x6),

              // --- DISCUSSION TIMER ---
              CBSectionHeader(title: 'TEMPORAL LIMITS', icon: Icons.timer_outlined, color: scheme.tertiary),
              const SizedBox(height: CBSpace.x3),
              
              CBGlassTile(
                borderColor: scheme.tertiary.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DAY PHASE TIMER',
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.tertiary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scheme.tertiary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${currentState.discussionTimerSeconds}s',
                            style: textTheme.labelLarge?.copyWith(
                              color: scheme.tertiary,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CBSpace.x2),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: scheme.tertiary,
                        inactiveTrackColor: scheme.tertiary.withValues(alpha: 0.2),
                        thumbColor: scheme.tertiary,
                        overlayColor: scheme.tertiary.withValues(alpha: 0.1),
                        trackHeight: 4.0,
                      ),
                      child: Slider(
                        value: currentState.discussionTimerSeconds.toDouble(),
                        min: 30,
                        max: 600,
                        divisions: 19,
                        // label: '${currentState.discussionTimerSeconds}s',
                        onChanged: (value) {
                          controller.setDiscussionTimerSeconds(value.round());
                        },
                        onChangeEnd: (_) => HapticService.selection(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: CBSpace.x6),

              CBSectionHeader(title: 'OVERRIDE PROTOCOLS', icon: Icons.warning_amber_rounded, color: CBColors.dead),
              const SizedBox(height: CBSpace.x3),

              // --- TOGGLES ---
              _buildSwitchTile(
                context,
                label: 'EYES OPEN NARRATION',
                description: 'Determine if players keep eyes open during phase transition narration.',
                value: currentState.eyesOpen,
                onChanged: (val) {
                  HapticService.selection();
                  controller.setEyesOpen(val);
                },
              ),
              const SizedBox(height: CBSpace.x3),
              _buildSwitchTile(
                context,
                label: 'RANDOM TIE BREAKING',
                description: 'If disabled, ties will result in no action/death during execution.',
                value: currentState.tieBreakStrategy == TieBreakStrategy.random,
                onChanged: (val) {
                  HapticService.selection();
                  controller.setTieBreakStrategy(
                    val ? TieBreakStrategy.random : TieBreakStrategy.peaceful,
                  );
                },
              ),

              const SizedBox(height: CBSpace.x6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBGlassTile(
      padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: CBSpace.x3),
      borderColor: scheme.outlineVariant.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   label,
                   style: textTheme.labelMedium?.copyWith(
                     color: scheme.onSurface,
                     fontWeight: FontWeight.w900,
                     letterSpacing: 1.0,
                   ),
                 ),
                 const SizedBox(height: CBSpace.x1),
                 Text(
                   description,
                   style: textTheme.bodySmall?.copyWith(
                     color: scheme.onSurface.withValues(alpha: 0.6),
                     fontSize: 11,
                   ),
                 ),
               ],
            ),
          ),
          const SizedBox(width: CBSpace.x4),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: scheme.surface,
            activeTrackColor: scheme.primary,
            inactiveTrackColor: scheme.surfaceContainerHigh,
            inactiveThumbColor: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

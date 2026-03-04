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
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CBBottomSheetHandle(), // Assuming this exists in cb_theme
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.settings_suggest_rounded, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'HOST SETTINGS',
                    style: textTheme.headlineSmall?.copyWith(
                      color: scheme.secondary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      shadows: CBColors.textGlow(scheme.secondary),
                    ),
                  ),
                ),
                IconButton(
                  // Keep the close button from previous impl? CBBottomSheetHandle usually suffices for drag down.
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'THESE SETTINGS ARE HOST-AUTHORITATIVE AND CANNOT BE CHANGED BY PLAYERS.',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
                fontSize: 9,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24),

            // --- DISCUSSION TIMER ---
            Text(
              'DISCUSSION TIMER',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: currentState.discussionTimerSeconds.toDouble(),
                    min: 30,
                    max: 600,
                    divisions: 19,
                    label: '${currentState.discussionTimerSeconds}s',
                    onChanged: (value) {
                      controller.setDiscussionTimerSeconds(value.round());
                    },
                    activeColor: scheme.secondary,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${currentState.discussionTimerSeconds}s',
                    style: textTheme.bodyLarge?.copyWith(
                      color: scheme.secondary,
                      fontFamily: 'Monospace',
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- GAME STYLE ---
            Text(
              'GAME STYLE PRESET',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<GameStyle>(
              initialValue: currentState.gameStyle,
              dropdownColor: scheme.surfaceContainerHighest,
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
              decoration: InputDecoration(
                filled: true,
                fillColor: scheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
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
                        style.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                  controller.setGameStyle(value);
                }
              },
              isExpanded: true,
            ),
            const SizedBox(height: 24),

            // --- TOGGLES ---
            _buildSwitch(
              context,
              label: 'EYES OPEN NARRATION',
              description:
                  'Determine if players keep eyes open during narration.',
              value: currentState.eyesOpen,
              onChanged: (val) => controller.setEyesOpen(val),
            ),
            const Divider(height: 24),
            _buildSwitch(
              context,
              label: 'RANDOM TIE BREAKING',
              description: 'If false, ties result in no action/death.',
              value: currentState.tieBreakStrategy == TieBreakStrategy.random,
              onChanged: (val) => controller.setTieBreakStrategy(
                val ? TieBreakStrategy.random : TieBreakStrategy.peaceful,
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(
    BuildContext context, {
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: scheme.secondary,
        ),
      ],
    );
  }
}

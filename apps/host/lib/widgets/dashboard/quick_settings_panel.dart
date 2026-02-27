import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuickSettingsPanel extends ConsumerWidget {
  final GameState gameState;

  const QuickSettingsPanel({super.key, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(gameProvider.notifier);

    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'CONTROL ROOM',
            color: scheme.primary,
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            '// GAME CONFIGURATION, TIMER & TOOLS.',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.primary.withValues(alpha: 0.6),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),

          // Discussion Timer
          _SettingRow(
            label: 'DISCUSSION TIMER',
            value: _formatDuration(gameState.discussionTimerSeconds),
            icon: Icons.timer_rounded,
            color: scheme.secondary,
            onTap: () => _showTimerPicker(context, ref),
          ),
          const SizedBox(height: 8),

          // Game Style
          _SettingRow(
            label: 'GAME STYLE',
            value: gameState.gameStyle.label,
            icon: Icons.casino_rounded,
            color: scheme.tertiary,
            onTap: () => _showGameStylePicker(context, ref),
          ),
          const SizedBox(height: 8),

          // Tie Break
          _SettingRow(
            label: 'TIE BREAK',
            value: gameState.tieBreakStrategy.label,
            icon: Icons.balance_rounded,
            color: scheme.primary,
            onTap: () => _showTieBreakPicker(context, ref),
          ),
          const SizedBox(height: 8),

          // Sync Mode
          _SettingRow(
            label: 'SYNC MODE',
            value: gameState.syncMode == SyncMode.local ? 'LOCAL' : 'CLOUD',
            icon: gameState.syncMode == SyncMode.local
                ? Icons.wifi_off_rounded
                : Icons.cloud_rounded,
            color: gameState.syncMode == SyncMode.cloud
                ? scheme.tertiary
                : scheme.onSurface.withValues(alpha: 0.6),
            onTap: () {
              final newMode = gameState.syncMode == SyncMode.local
                  ? SyncMode.cloud
                  : SyncMode.local;
              controller.setSyncMode(newMode);
              HapticFeedback.selectionClick();
            },
          ),

          // Debug tools
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Text(
              '// DEBUG TOOLS',
              style: textTheme.labelSmall!.copyWith(
                color: scheme.error.withValues(alpha: 0.5),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ToolChip(
                  label: 'ADD BOT',
                  icon: Icons.smart_toy_rounded,
                  color: scheme.primary,
                  onTap: () {
                    controller.addBot();
                    showThemedSnackBar(context, 'BOT ADDED TO ROSTER',
                        accentColor: scheme.primary);
                  },
                ),
                _ToolChip(
                  label: 'SIM BOTS',
                  icon: Icons.fast_forward_rounded,
                  color: scheme.secondary,
                  onTap: () {
                    final count = controller.simulateBotTurns();
                    showThemedSnackBar(context, '$count BOT ACTIONS SIMULATED',
                        accentColor: scheme.secondary);
                  },
                ),
                _ToolChip(
                  label: 'SIM PLAYERS',
                  icon: Icons.people_rounded,
                  color: scheme.tertiary,
                  onTap: () {
                    final count = controller.simulatePlayersForCurrentStep();
                    showThemedSnackBar(
                        context, '$count PLAYER ACTIONS SIMULATED',
                        accentColor: scheme.tertiary);
                  },
                ),
                _ToolChip(
                  label: 'SANDBOX',
                  icon: Icons.science_rounded,
                  color: CBColors.alertOrange,
                  onTap: () {
                    controller.loadTestGameSandbox();
                    showThemedSnackBar(context, 'TEST SANDBOX LOADED',
                        accentColor: CBColors.alertOrange);
                  },
                ),
                _ToolChip(
                  label: 'SAVE',
                  icon: Icons.save_rounded,
                  color: scheme.primary,
                  onTap: () {
                    final ok = controller.manualSave();
                    showThemedSnackBar(
                        context, ok ? 'GAME SAVED' : 'SAVE FAILED',
                        accentColor: ok ? scheme.tertiary : scheme.error);
                  },
                ),
                _ToolChip(
                  label: 'LOAD',
                  icon: Icons.upload_file_rounded,
                  color: scheme.primary,
                  onTap: () {
                    final ok = controller.manualLoad();
                    showThemedSnackBar(
                        context, ok ? 'GAME LOADED' : 'LOAD FAILED',
                        accentColor: ok ? scheme.tertiary : scheme.error);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (secs == 0) return '${mins}m';
    return '${mins}m ${secs}s';
  }

  void _showTimerPicker(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final presets = [60, 120, 180, 300, 420, 600];

    showThemedDialog(
      context: context,
      accentColor: scheme.secondary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DISCUSSION TIMER',
            style: textTheme.labelLarge!.copyWith(
              color: scheme.secondary,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((seconds) {
              final isActive = gameState.discussionTimerSeconds == seconds;
              return ChoiceChip(
                label: Text(_formatDuration(seconds)),
                selected: isActive,
                selectedColor: scheme.secondary.withValues(alpha: 0.3),
                onSelected: (_) {
                  ref.read(gameProvider.notifier).setDiscussionTimer(seconds);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showGameStylePicker(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showThemedDialog(
      context: context,
      accentColor: scheme.tertiary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GAME STYLE',
            style: textTheme.labelLarge!.copyWith(
              color: scheme.tertiary,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ...GameStyle.values.map((style) {
            final isActive = gameState.gameStyle == style;
            return ListTile(
              dense: true,
              selected: isActive,
              selectedTileColor: scheme.tertiary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              leading: Icon(
                isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isActive
                    ? scheme.tertiary
                    : scheme.onSurface.withValues(alpha: 0.4),
                size: 18,
              ),
              title: Text(
                style.label,
                style: textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              subtitle: Text(
                style.description,
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              onTap: () {
                ref.read(gameProvider.notifier).setGameStyle(style);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }

  void _showTieBreakPicker(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showThemedDialog(
      context: context,
      accentColor: scheme.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TIE BREAK STRATEGY',
            style: textTheme.labelLarge!.copyWith(
              color: scheme.primary,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ...TieBreakStrategy.values.map((strategy) {
            final isActive = gameState.tieBreakStrategy == strategy;
            return ListTile(
              dense: true,
              selected: isActive,
              selectedTileColor: scheme.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              leading: Icon(
                isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isActive
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.4),
                size: 18,
              ),
              title: Text(
                strategy.label,
                style: textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              subtitle: Text(
                strategy.description,
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              onTap: () {
                ref.read(gameProvider.notifier).setTieBreakStrategy(strategy);
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SettingRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: CBGlassTile(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderColor: color.withValues(alpha: 0.2),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                value,
                style: textTheme.labelSmall!.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: scheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.labelSmall!.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

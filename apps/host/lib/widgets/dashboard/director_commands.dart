import 'dart:math';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DirectorCommands extends ConsumerWidget {
  final GameState gameState;

  const DirectorCommands({super.key, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(CBSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CBSectionHeader(
            title: 'DIRECTOR COMMANDS',
            color: scheme.primary,
            icon: Icons.movie_filter_rounded,
          ),
          const SizedBox(height: CBSpace.x4),
          Text(
            'INJECT NARRATIVE EVENTS & ANNOUNCEMENTS INTO THE MISSION FEED.',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x5),
          Row(
            children: [
              Expanded(
                child: _DirectorActionButton(
                  label: 'RUMOUR',
                  icon: Icons.campaign_rounded,
                  color: scheme.secondary,
                  description: 'FLAVOR INJECTION',
                  onPressed: () => _flashRandomRumour(context, ref),
                ),
              ),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: _DirectorActionButton(
                  label: 'BROADCAST',
                  icon: Icons.record_voice_over_rounded,
                  color: scheme.primary,
                  description: 'VOICE OF GOD',
                  onPressed: () => _voiceOfGod(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: CBSpace.x3),
          Row(
            children: [
              Expanded(
                child: _buildCmdMiniButton(context, ref, 'NEON FLICKER', Icons.lightbulb_outline, scheme.primary),
              ),
              const SizedBox(width: CBSpace.x2),
              Expanded(
                child: _buildCmdMiniButton(context, ref, 'SYSTEM GLITCH', Icons.settings_ethernet, scheme.tertiary),
              ),
              const SizedBox(width: CBSpace.x2),
              Expanded(
                child: _buildCmdMiniButton(context, ref, 'BASS DROP', Icons.music_note_rounded, scheme.onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCmdMiniButton(BuildContext context, WidgetRef ref, String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        HapticService.selection();
        ref.read(gameProvider.notifier).sendDirectorCommand(label);
        showThemedSnackBar(context, '$label TRIGGERED.', accentColor: color);
      },
      borderRadius: BorderRadius.circular(CBRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: CBSpace.x2, vertical: CBSpace.x2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(CBRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: CBSpace.x1),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _flashRandomRumour(BuildContext context, WidgetRef ref) {
    final alivePlayers = gameState.players.where((p) => p.isAlive).toList();
    if (alivePlayers.isEmpty) return;

    final target = alivePlayers[Random().nextInt(alivePlayers.length)];
    final rumour = rumourTemplates[Random().nextInt(rumourTemplates.length)]
        .replaceAll('{player}', target.name);

    ref.read(gameProvider.notifier).dispatchBulletin(
          title: 'RUMOUR MILL',
          content: rumour,
          type: 'event',
        );

    showThemedSnackBar(context, 'RUMOUR DISPATCHED TO ALL NODES.', accentColor: Theme.of(context).colorScheme.secondary);
  }

  void _voiceOfGod(BuildContext context, WidgetRef ref) {
    String message = '';
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showThemedDialog(
      context: context,
      accentColor: scheme.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'VOICE OF GOD PROTOCOL',
            style: textTheme.headlineSmall!.copyWith(
              color: scheme.primary,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
              shadows: CBColors.textGlow(scheme.primary, intensity: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x4),
          Text(
            'TRANSMIT A HIGH-PRIORITY GLOBAL ANNOUNCEMENT TO ALL PATRONS.',
            style: textTheme.bodySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x6),
          CBTextField(
            hintText: 'ENTER ANNOUNCEMENT PAYLOAD...',
            maxLines: 4,
            onChanged: (value) => message = value,
          ),
          const SizedBox(height: CBSpace.x8),
          Row(
            children: [
              Expanded(
                child: CBGhostButton(
                  label: 'ABORT',
                  onPressed: () {
                    HapticService.light();
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: CBPrimaryButton(
                  label: 'BROADCAST',
                  onPressed: () {
                    if (message.isNotEmpty) {
                      HapticService.heavy();
                      ref.read(gameProvider.notifier).dispatchBulletin(
                            title: 'HOST ANNOUNCEMENT',
                            content: message,
                            type: 'urgent',
                          );
                      Navigator.pop(context);
                      showThemedSnackBar(
                          context, 'GLOBAL ANNOUNCEMENT TRANSMITTED.', accentColor: scheme.primary);
                    }
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _DirectorActionButton extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _DirectorActionButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return CBGlassTile(
      onTap: () {
        HapticService.selection();
        onPressed();
      },
      borderColor: color.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: CBSpace.x3, vertical: CBSpace.x4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: -2)],
            ),
            child: Icon(icon, color: color, size: 28, shadows: CBColors.iconGlow(color, intensity: 0.6)),
          ),
          const SizedBox(height: CBSpace.x3),
          Text(
            label.toUpperCase(),
            style: textTheme.labelLarge!.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              shadows: CBColors.textGlow(color, intensity: 0.5),
            ),
          ),
          const SizedBox(height: CBSpace.x1),
          Text(
            description.toUpperCase(),
            style: textTheme.labelSmall!.copyWith(
              color: color.withValues(alpha: 0.7),
              fontSize: 8,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

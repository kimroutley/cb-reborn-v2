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
      borderColor: scheme.primary.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'DIRECTOR COMMANDS',
            color: scheme.primary,
            icon: Icons.movie_filter_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            '// INJECT NARRATIVE EVENTS & ANNOUNCEMENTS INTO THE FEED.',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.primary.withValues(alpha: 0.6),
              fontSize: 8,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _DirectorActionButton(
                label: 'RANDOM RUMOR',
                icon: Icons.campaign_rounded,
                color: scheme.secondary,
                description: 'Inject flavor rumor mill',
                onPressed: () => _flashRandomRumour(context, ref),
              ),
              _DirectorActionButton(
                label: 'VOICE OF GOD',
                icon: Icons.record_voice_over_rounded,
                color: scheme.primary,
                description: 'Direct global broadcast',
                onPressed: () => _voiceOfGod(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _flashRandomRumour(BuildContext context, WidgetRef ref) {
    final alivePlayers = gameState.players.where((p) => p.isAlive).toList();
    if (alivePlayers.isEmpty) return;

    final target = alivePlayers[Random().nextInt(alivePlayers.length)];
    final rumour = rumourTemplates[Random().nextInt(rumourTemplates.length)]
        .replaceAll('{player}', target.name);

    ref
        .read(gameProvider.notifier)
        .dispatchBulletin(title: 'RUMOUR MILL', content: rumour, type: 'event');

    showThemedSnackBar(
      context,
      'RUMOR DISPATCHED TO ALL NODES',
      accentColor: Theme.of(context).colorScheme.secondary,
    );
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROTOCOL: VOICE OF GOD',
            style: textTheme.labelLarge!.copyWith(
              color: scheme.primary,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w900,
              shadows: CBColors.textGlow(scheme.primary, intensity: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transmit a high-priority global announcement to all patrons.',
            style: textTheme.bodySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          CBTextField(
            hintText: 'ENTER ANNOUNCEMENT PAYLOAD...',
            maxLines: 4,
            onChanged: (value) => message = value,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'ABORT',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: 'BROADCAST',
                onPressed: () {
                  if (message.isNotEmpty) {
                    ref
                        .read(gameProvider.notifier)
                        .dispatchBulletin(
                          title: 'HOST ANNOUNCEMENT',
                          content: message,
                          type: 'urgent',
                        );
                    Navigator.pop(context);
                    showThemedSnackBar(
                      context,
                      'GLOBAL ANNOUNCEMENT TRANSMITTED',
                      accentColor: scheme.primary,
                    );
                  }
                },
              ),
            ],
          ),
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
      borderColor: color.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
              shadows: CBColors.iconGlow(color, intensity: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: textTheme.labelSmall!.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description.toUpperCase(),
              style: textTheme.labelSmall!.copyWith(
                color: color.withValues(alpha: 0.5),
                fontSize: 8,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final scheme = Theme.of(context).colorScheme;
    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CBSectionHeader(
            title: 'Director Commands',
            icon: Icons.movie_filter,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _directorButton(
                'RANDOM RUMOUR',
                Icons.campaign_rounded,
                scheme.secondary,
                () => _flashRandomRumour(context, ref),
              ),
              _directorButton(
                'VOICE OF GOD',
                Icons.record_voice_over_rounded,
                scheme.primary,
                () => _voiceOfGod(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _directorButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 160,
      child: CBGhostButton(
        label: label,
        color: color,
        onPressed: onPressed,
      ),
    );
  }

  void _flashRandomRumour(BuildContext context, WidgetRef ref) {
    final alivePlayers =
        gameState.players.where((p) => p.isAlive).toList();
    if (alivePlayers.isEmpty) return;

    final target = alivePlayers[Random().nextInt(alivePlayers.length)];
    final rumour = rumourTemplates[Random().nextInt(rumourTemplates.length)]
        .replaceAll('{player}', target.name);

    ref.read(gameProvider.notifier).dispatchBulletin(
          title: 'RUMOUR MILL',
          content: rumour,
          type: 'event',
        );

    showThemedSnackBar(context, 'Rumour dispatched to all players');
  }

  void _voiceOfGod(BuildContext context, WidgetRef ref) {
    String message = '';
    final scheme = Theme.of(context).colorScheme;
    showThemedDialog(
      context: context,
      accentColor: scheme.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOICE OF GOD',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows:
                      CBColors.textGlow(scheme.primary, intensity: 0.6),
                ),
          ),
          const SizedBox(height: 16),
          CBTextField(
            decoration: const InputDecoration(
              labelText: 'Announcement',
              hintText: 'Your message to all players...',
            ),
            maxLines: 3,
            onChanged: (value) => message = value,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: 'SEND',
                onPressed: () {
                  if (message.isNotEmpty) {
                    ref.read(gameProvider.notifier).dispatchBulletin(
                          title: 'HOST ANNOUNCEMENT',
                          content: message,
                          type: 'urgent',
                        );
                    Navigator.pop(context);
                    showThemedSnackBar(
                        context, 'Announcement sent to all players');
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}

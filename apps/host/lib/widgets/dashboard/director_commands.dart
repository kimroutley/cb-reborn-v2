import 'dart:math';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      borderColor: scheme.primary.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'POWER TRIPS',
            color: scheme.primary,
            icon: Icons.flash_on_rounded,
          ),
          const SizedBox(height: 8),
          Text(
            'Abuse your authority. Inject chaos, spread lies, and manipulate the narrative.',
            style: textTheme.bodySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _PowerTripCard(
            label: 'VOICE OF GOD',
            blurb: 'Broadcast a high-priority announcement to every player device. Nobody can ignore this.',
            icon: Icons.record_voice_over_rounded,
            color: scheme.primary,
            onPressed: () => _voiceOfGod(context, ref),
          ),
          _PowerTripCard(
            label: 'RANDOM RUMOUR',
            blurb: 'Generate a random rumour about a living player and push it to all feeds. Stir the pot.',
            icon: Icons.campaign_rounded,
            color: scheme.secondary,
            onPressed: () => _flashRandomRumour(context, ref),
          ),
          _PowerTripCard(
            label: 'PRIVATE DM',
            blurb: 'Send a secret message to one player. Only they will see it. Perfect for planting seeds.',
            icon: Icons.mail_lock_rounded,
            color: scheme.tertiary,
            onPressed: () => _privateDM(context, ref),
          ),
          _PowerTripCard(
            label: 'NEON FLICKER',
            blurb: 'Trigger a visual effect on all player screens. Purely atmospheric — creates tension.',
            icon: Icons.lightbulb_outline_rounded,
            color: CBColors.neonPink,
            onPressed: () {
              ref.read(gameProvider.notifier).sendDirectorCommand('flicker');
              HapticFeedback.heavyImpact();
              showThemedSnackBar(context, 'NEON FLICKER DISPATCHED',
                  accentColor: CBColors.neonPink);
            },
          ),
          _PowerTripCard(
            label: 'SYSTEM GLITCH',
            blurb: 'Simulate a system malfunction on all devices. Disorients players and creates panic.',
            icon: Icons.settings_ethernet_rounded,
            color: CBColors.alertOrange,
            onPressed: () {
              ref.read(gameProvider.notifier).sendDirectorCommand('glitch');
              HapticFeedback.mediumImpact();
              showThemedSnackBar(context, 'SYSTEM GLITCH TRIGGERED',
                  accentColor: CBColors.alertOrange);
            },
          ),
          _PowerTripCard(
            label: 'FAKE DEATH',
            blurb: 'Broadcast a fake elimination. The player stays alive — everyone else panics.',
            icon: Icons.theater_comedy_rounded,
            color: scheme.error,
            onPressed: () => _fakeDeath(context, ref),
          ),
          _PowerTripCard(
            label: 'COPY GAME LOG',
            blurb: 'Export the full session log to your clipboard for sharing or post-game analysis.',
            icon: Icons.content_copy_rounded,
            color: scheme.onSurface.withValues(alpha: 0.6),
            isLast: true,
            onPressed: () {
              final log = ref.read(gameProvider.notifier).exportGameLog();
              Clipboard.setData(ClipboardData(text: log));
              showThemedSnackBar(context, 'GAME LOG COPIED TO CLIPBOARD',
                  accentColor: scheme.primary);
            },
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

    ref.read(gameProvider.notifier).dispatchBulletin(
          title: 'RUMOUR MILL',
          content: rumour,
          type: 'event',
        );

    showThemedSnackBar(context, 'RUMOUR DISPATCHED TO ALL NODES',
        accentColor: Theme.of(context).colorScheme.secondary);
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
            'POWER TRIP: VOICE OF GOD',
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
            style: textTheme.bodySmall!
                .copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
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
                    ref.read(gameProvider.notifier).dispatchBulletin(
                          title: 'HOST ANNOUNCEMENT',
                          content: message,
                          type: 'urgent',
                        );
                    Navigator.pop(context);
                    showThemedSnackBar(context,
                        'GLOBAL ANNOUNCEMENT TRANSMITTED',
                        accentColor: scheme.primary);
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  void _privateDM(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final alivePlayers = gameState.players.where((p) => p.isAlive).toList();
    String? selectedPlayerId;
    String message = '';

    showThemedDialog(
      context: context,
      accentColor: scheme.tertiary,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'POWER TRIP: PRIVATE DM',
                style: textTheme.labelLarge!.copyWith(
                  color: scheme.tertiary,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w900,
                  shadows: CBColors.textGlow(scheme.tertiary, intensity: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Send a covert message to a single patron.',
                style: textTheme.bodySmall!
                    .copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: alivePlayers.length,
                  itemBuilder: (context, index) {
                    final p = alivePlayers[index];
                    final isSelected = selectedPlayerId == p.id;
                    final roleColor = CBColors.fromHex(p.role.colorHex);
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedPlayerId = p.id),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? scheme.tertiary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: CBRoleAvatar(
                                assetPath: p.role.assetPath,
                                color: roleColor,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.name.split(' ').first.toUpperCase(),
                              style: textTheme.labelSmall!.copyWith(
                                color: isSelected
                                    ? scheme.tertiary
                                    : scheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              CBTextField(
                hintText: 'YOUR SECRET MESSAGE...',
                maxLines: 3,
                onChanged: (value) => message = value,
              ),
              const SizedBox(height: 24),
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
                    label: 'TRANSMIT',
                    backgroundColor: scheme.tertiary,
                    onPressed:
                        selectedPlayerId == null || message.trim().isEmpty
                            ? null
                            : () {
                                ref.read(gameProvider.notifier).dispatchBulletin(
                                      title: 'HOST WHISPER',
                                      content: message,
                                      type: 'whisper',
                                    );
                                Navigator.pop(context);
                                final playerName = alivePlayers
                                    .firstWhere(
                                        (p) => p.id == selectedPlayerId)
                                    .name;
                                showThemedSnackBar(context,
                                    'DM SENT TO ${playerName.toUpperCase()}',
                                    accentColor: scheme.tertiary);
                              },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _fakeDeath(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final alivePlayers = gameState.players.where((p) => p.isAlive).toList();
    String? selectedPlayerId;

    showThemedDialog(
      context: context,
      accentColor: scheme.error,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'POWER TRIP: FAKE DEATH',
                style: textTheme.labelLarge!.copyWith(
                  color: scheme.error,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w900,
                  shadows: CBColors.textGlow(scheme.error, intensity: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Broadcast a fake elimination to sow chaos. Player remains alive.',
                style: textTheme.bodySmall!
                    .copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: alivePlayers.length,
                  itemBuilder: (context, index) {
                    final p = alivePlayers[index];
                    final isSelected = selectedPlayerId == p.id;
                    final roleColor = CBColors.fromHex(p.role.colorHex);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p.name.split(' ').first.toUpperCase()),
                        selected: isSelected,
                        selectedColor: roleColor.withValues(alpha: 0.3),
                        labelStyle: textTheme.labelSmall!.copyWith(
                          color: isSelected ? roleColor : scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                        onSelected: (_) =>
                            setDialogState(() => selectedPlayerId = p.id),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
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
                    label: 'FAKE IT',
                    backgroundColor: scheme.error,
                    onPressed: selectedPlayerId == null
                        ? null
                        : () {
                            final playerName = alivePlayers
                                .firstWhere((p) => p.id == selectedPlayerId)
                                .name;
                            ref.read(gameProvider.notifier).dispatchBulletin(
                                  title: 'ELIMINATION',
                                  content:
                                      '${playerName.toUpperCase()} has been eliminated from the club.',
                                  type: 'result',
                                );
                            Navigator.pop(context);
                            showThemedSnackBar(context,
                                'FAKE DEATH BROADCAST FOR ${playerName.toUpperCase()}',
                                accentColor: scheme.error);
                          },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PowerTripCard extends StatelessWidget {
  final String label;
  final String blurb;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isLast;

  const _PowerTripCard({
    required this.label,
    required this.blurb,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticService.selection();
            onPressed();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: color.withValues(alpha: 0.06),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                    shadows: CBColors.iconGlow(color, intensity: 0.4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: textTheme.labelMedium!.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        blurb,
                        style: textTheme.bodySmall!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                          fontSize: 11,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

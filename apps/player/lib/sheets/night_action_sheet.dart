import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import '../player_bridge.dart';

class NightActionSheet extends StatelessWidget {
  final StepSnapshot step;
  final List<PlayerSnapshot> players;
  final Function(String) onAction;

  const NightActionSheet({
    super.key,
    required this.step,
    required this.players,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final accent = scheme.tertiary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CBBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(CBSpace.x5, CBSpace.x2, CBSpace.x5, CBSpace.x4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CBSpace.x2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bolt_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: Text(
                  'MISSION ACTION',
                  style: textTheme.headlineSmall!.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: CBColors.textGlow(accent, intensity: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (step.actionType == 'binaryChoice')
          Padding(
            padding: const EdgeInsets.fromLTRB(CBSpace.x5, 0, CBSpace.x5, CBSpace.x8),
            child: Column(
              children: step.options.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: CBSpace.x3),
                  child: CBPrimaryButton(
                    label: option.toUpperCase(),
                    backgroundColor: scheme.primary.withValues(alpha: 0.15),
                    foregroundColor: scheme.primary,
                    onPressed: () {
                      HapticService.medium();
                      onAction(option);
                    },
                  ),
                );
              }).toList(),
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(CBSpace.x5, 0, CBSpace.x5, CBSpace.x8),
              itemCount: players.length,
              separatorBuilder: (_, __) => const SizedBox(height: CBSpace.x3),
              itemBuilder: (context, index) {
                final player = players[index];

                return CBGlassTile(
                  padding: const EdgeInsets.all(CBSpace.x4),
                  borderColor: scheme.outlineVariant.withValues(alpha: 0.2),
                  onTap: () {
                    HapticService.heavy();
                    onAction(player.id);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
                        ),
                        child: Center(
                          child: Text(
                            player.name.characters.first.toUpperCase(),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: CBSpace.x4),
                      Expanded(
                        child: Text(
                          player.name.toUpperCase(),
                          style: textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                      ),
                      CBGhostButton(
                        label: 'SELECT',
                        color: accent,
                        onPressed: () {
                          HapticService.heavy();
                          onAction(player.id);
                        },
                        fullWidth: false,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

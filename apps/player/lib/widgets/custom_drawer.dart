import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile_edit_guard.dart';
import '../player_destinations.dart';
import '../player_navigation.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  Future<bool> _confirmDiscardProfileChanges(
    BuildContext context,
    WidgetRef ref,
    PlayerDestination nextDestination,
  ) async {
    final currentDestination = ref.read(playerNavigationProvider);
    if (currentDestination != PlayerDestination.profile ||
        nextDestination == PlayerDestination.profile ||
        !ref.read(playerProfileDirtyProvider)) {
      return true;
    }

    final shouldDiscard = await showCBDiscardChangesDialog(
      context,
      message: 'You have unsaved profile edits. Leave without saving?',
    );

    if (shouldDiscard) {
      ref.read(playerProfileDirtyProvider.notifier).reset();
    }
    return shouldDiscard;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final currentDestination = ref.watch(playerNavigationProvider);

    return Drawer(
      backgroundColor: scheme.surfaceContainerLow,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),

          ...playerDestinations.map((config) {
            final isSelected = currentDestination == config.destination;

            return _DrawerTile(
              icon: config.icon,
              title: config.label,
              isSelected: isSelected,
              onTap: () async {
                if (config.destination == currentDestination) {
                  Navigator.pop(context);
                  return;
                }
                final canLeave = await _confirmDiscardProfileChanges(
                  context,
                  ref,
                  config.destination,
                );
                if (!context.mounted) {
                  return;
                }
                if (!canLeave) {
                  return;
                }
                Navigator.pop(context);
                ref
                    .read(playerNavigationProvider.notifier)
                    .setDestination(config.destination);
              },
            );
          }),

          Divider(color: scheme.outlineVariant.withValues(alpha: 0.25)),

          // BAR TAB PREVIEW (Visual only stub)
          Padding(
            padding: CBInsets.panel,
            child: Container(
              padding: CBInsets.screen,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(CBRadius.md),
                border: Border.all(
                  color: scheme.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        color: scheme.tertiary,
                        size: 16,
                      ),
                      const SizedBox(width: CBSpace.x2),
                      Text(
                        "YOUR BAR TAB",
                        style: textTheme.labelSmall!.copyWith(
                          color: scheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CBSpace.x3),
                  Text(
                    "0 DRINKS OWED",
                    style: textTheme.headlineSmall!.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    "NO ACTIVE PENALTIES",
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return DrawerHeader(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
              color: scheme.primary.withValues(alpha: 0.4), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBRoleAvatar(color: scheme.primary, size: 48, pulsing: true),
          const SizedBox(height: CBSpace.x4),
          Text(
            'CLUB BLACKOUT',
            style: textTheme.headlineMedium!.copyWith(
              color: scheme.onSurface,
              shadows: CBColors.textGlow(scheme.primary, intensity: 0.5),
            ),
          ),
          Text(
            'THE ULTIMATE SOCIAL DECEPTION',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.35),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isSelected;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        title.toUpperCase(),
        style: textTheme.labelSmall!.copyWith(
          color: isSelected
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.85),
          letterSpacing: 1.5,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
          shadows: isSelected
              ? CBColors.textGlow(scheme.primary, intensity: 0.3)
              : null,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
}

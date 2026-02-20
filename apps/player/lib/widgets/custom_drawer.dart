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
    final selectedIndex = playerDestinations
        .indexWhere((config) => config.destination == currentDestination);

    const coreGroup = <PlayerDestination>{
      PlayerDestination.home,
      PlayerDestination.lobby,
      PlayerDestination.claim,
      PlayerDestination.game,
    };
    const guidesGroup = <PlayerDestination>{
      PlayerDestination.guides,
      PlayerDestination.gamesNight,
      PlayerDestination.hallOfFame,
    };
    const profileGroup = <PlayerDestination>{
      PlayerDestination.profile,
      PlayerDestination.stats,
      PlayerDestination.about,
    };

    List<PlayerDestinationConfig> configsFor(Set<PlayerDestination> group) {
      return playerDestinations
          .where((config) => group.contains(config.destination))
          .toList(growable: false);
    }

    final coreDestinations = configsFor(coreGroup);
    final guidesDestinations = configsFor(guidesGroup);
    final profileDestinations = configsFor(profileGroup);

    return NavigationDrawer(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.secondaryContainer,
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      onDestinationSelected: (index) async {
        HapticService.selection();
        final destination = playerDestinations[index].destination;
        if (destination == currentDestination) {
          return;
        }

        final canLeave = await _confirmDiscardProfileChanges(
          context,
          ref,
          destination,
        );
        if (!context.mounted || !canLeave) {
          return;
        }

        ref.read(playerNavigationProvider.notifier).setDestination(destination);
        try {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } catch (_) {}
      },
      children: [
        _buildDrawerHeader(context),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x2, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Core',
            icon: Icons.hub_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...coreDestinations.map(
          (dest) => NavigationDrawerDestination(
            icon: Icon(dest.icon),
            label: Text(dest.label),
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Guides',
            icon: Icons.auto_stories_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...guidesDestinations.map(
          (dest) => NavigationDrawerDestination(
            icon: Icon(dest.icon),
            label: Text(dest.label),
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Profile & Stats',
            icon: Icons.perm_identity_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...profileDestinations.map(
          (dest) => NavigationDrawerDestination(
            icon: Icon(dest.icon),
            label: Text(dest.label),
          ),
        ),

        const SizedBox(height: 12),

        // BAR TAB PREVIEW (Visual only stub)
        Padding(
          padding: CBInsets.screen,
          child: CBPanel(
            borderColor: scheme.tertiary,
            borderWidth: 1.25,
            padding: CBInsets.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CBSectionHeader(
                  title: 'Your Bar Tab',
                  icon: Icons.receipt_long_rounded,
                ),
                const SizedBox(height: CBSpace.x3),
                Text(
                  '0 DRINKS OWED',
                  style: textTheme.headlineSmall!.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    shadows: CBColors.textGlow(scheme.onSurface,
                        intensity: 0.35),
                  ),
                ),
                Text(
                  'NO ACTIVE PENALTIES',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CBSpace.x6,
        CBSpace.x6,
        CBSpace.x4,
        CBSpace.x4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLUB BLACKOUT',
            style: textTheme.headlineSmall?.copyWith(
              color: scheme.secondary,
              fontWeight: FontWeight.bold,
              shadows: CBColors.textGlow(scheme.secondary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PLAYER TERMINAL',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_theme/cb_theme.dart';

import '../host_destinations.dart';
import '../host_navigation.dart';
import '../profile_edit_guard.dart';


class CustomDrawer extends ConsumerWidget {
  final HostDestination? currentDestination;
  final ValueChanged<HostDestination>? onDrawerItemTap;

  const CustomDrawer({
    super.key,
    this.currentDestination,
    this.onDrawerItemTap,
  });

  Future<bool> _confirmDiscardProfileChanges(
    BuildContext context,
    WidgetRef ref,
    HostDestination current,
    HostDestination next,
  ) async {
    if (current != HostDestination.profile ||
        next == HostDestination.profile ||
        !ref.read(hostProfileDirtyProvider)) {
      return true;
    }

    final shouldDiscard = await showCBDiscardChangesDialog(
      context,
      message: 'You have unsaved profile edits. Leave without saving?',
    );

    if (shouldDiscard) {
      ref.read(hostProfileDirtyProvider.notifier).reset();
    }
    return shouldDiscard;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HostDestination activeDestination =
        currentDestination ?? ref.watch(hostNavigationProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const gameplayGroup = <HostDestination>{
      HostDestination.lobby,
      HostDestination.gameSetup,
      HostDestination.game,
      HostDestination.guides,
    };
    const statsAndAwardsGroup = <HostDestination>{
      HostDestination.hallOfFame,
    };
    const gamesNightGroup = <HostDestination>{
      HostDestination.gamesNight,
    };
    const walletGroup = <HostDestination>{
      HostDestination.profile,
    };
    const otherGroup = <HostDestination>{
      HostDestination.home,
      HostDestination.saveLoad,
      HostDestination.settings,
      HostDestination.about,
    };

    List<HostDestinationConfig> configsFor(Set<HostDestination> group) {
      return hostDestinations
          .where((config) => group.contains(config.destination))
          .toList(growable: false);
    }

    final gameplayDestinations = configsFor(gameplayGroup);
    final statsAndAwardsDestinations = configsFor(statsAndAwardsGroup);
    final gamesNightDestinations = configsFor(gamesNightGroup);
    final walletDestinations = configsFor(walletGroup);
    final otherDestinations = configsFor(otherGroup);
    final drawerDestinations = <HostDestinationConfig>[
      ...gameplayDestinations,
      ...statsAndAwardsDestinations,
      ...gamesNightDestinations,
      ...walletDestinations,
      ...otherDestinations,
    ];

    final selectedIndex = drawerDestinations
        .indexWhere((d) => d.destination == activeDestination);

    Future<void> handleDestinationSelected(int index) async {
      HapticService.selection();
      final destination = drawerDestinations[index].destination;
      if (destination == activeDestination) {
        return;
      }

      final canLeave = await _confirmDiscardProfileChanges(
        context,
        ref,
        activeDestination,
        destination,
      );
      if (!context.mounted) {
        return;
      }
      if (!canLeave) {
        return;
      }

      if (onDrawerItemTap != null) {
        onDrawerItemTap!(destination);
      } else {
        ref.read(hostNavigationProvider.notifier).setDestination(destination);
      }

      try {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (_) {}
    }

    return CBSideDrawer(
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      onDestinationSelected: handleDestinationSelected,
      drawerHeader: CBDrawerHeader(
        subtitle: 'HOST CONSOLE',
        color: colorScheme.secondary,
      ), // Pass the header
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x2, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Gameplay',
            icon: Icons.gamepad_outlined,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...gameplayDestinations.map((dest) {
          final idx = drawerDestinations.indexOf(dest);
          final isSelected = idx == selectedIndex;
          return CBDrawerTile(
            icon: dest.icon,
            label: dest.label,
            isSelected: isSelected,
            color: colorScheme.secondary,
            onTap: () => handleDestinationSelected(idx),
          );
        }),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Stats and Awards',
            icon: Icons.emoji_events_outlined,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...statsAndAwardsDestinations.map((dest) {
          final idx = drawerDestinations.indexOf(dest);
          final isSelected = idx == selectedIndex;
          return CBDrawerTile(
            icon: dest.icon,
            label: dest.label,
            isSelected: isSelected,
            color: colorScheme.secondary,
            onTap: () => handleDestinationSelected(idx),
          );
        }),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Games Night',
            icon: Icons.group_outlined,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...gamesNightDestinations.map((dest) {
          final idx = drawerDestinations.indexOf(dest);
          final isSelected = idx == selectedIndex;
          return CBDrawerTile(
            icon: dest.icon,
            label: dest.label,
            isSelected: isSelected,
            color: colorScheme.secondary,
            onTap: () => handleDestinationSelected(idx),
          );
        }),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'My Account',
            icon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...walletDestinations.map((dest) {
          final idx = drawerDestinations.indexOf(dest);
          final isSelected = idx == selectedIndex;
          return CBDrawerTile(
            icon: dest.icon,
            label: dest.label,
            isSelected: isSelected,
            color: colorScheme.secondary,
            onTap: () => handleDestinationSelected(idx),
          );
        }),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Other',
            icon: Icons.more_horiz_outlined,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...otherDestinations.map((dest) {
          final idx = drawerDestinations.indexOf(dest);
          final isSelected = idx == selectedIndex;
          return CBDrawerTile(
            icon: dest.icon,
            label: dest.label,
            isSelected: isSelected,
            color: colorScheme.secondary,
            onTap: () => handleDestinationSelected(idx),
          );
        }),

        const SizedBox(height: 24),
      ],
    );
  }
}

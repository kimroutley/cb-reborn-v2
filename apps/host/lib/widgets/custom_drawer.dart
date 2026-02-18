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

    final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'You have unsaved profile edits. Leave without saving?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;

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

    const coreGroup = <HostDestination>{
      HostDestination.home,
      HostDestination.lobby,
      HostDestination.game,
    };
    const managementGroup = <HostDestination>{
      HostDestination.guides,
      HostDestination.gamesNight,
      HostDestination.hallOfFame,
    };
    const systemGroup = <HostDestination>{
      HostDestination.saveLoad,
      HostDestination.settings,
      HostDestination.profile,
      HostDestination.about,
    };

    List<HostDestinationConfig> configsFor(Set<HostDestination> group) {
      return hostDestinations
          .where((config) => group.contains(config.destination))
          .toList(growable: false);
    }

    final coreDestinations = configsFor(coreGroup);
    final managementDestinations = configsFor(managementGroup);
    final systemDestinations = configsFor(systemGroup);

    // Calculate selected index based on the full list of destinations
    final selectedIndex =
        hostDestinations.indexWhere((d) => d.destination == activeDestination);

    return NavigationDrawer(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) async {
        final destination = hostDestinations[index].destination;
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

        // Close the drawer if it's likely we're in a mobile-style overlay
        // (Scaffold.of(context).isDrawerOpen is a better check if needed)
        try {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } catch (_) {}
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CLUB BLACKOUT',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  shadows: CBColors.textGlow(colorScheme.secondary),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'HOST CONSOLE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),

        const Divider(indent: 28, endIndent: 28),
        const SizedBox(height: 12),

        // Group 1: Core (Home, Lobby, Game)
        ...coreDestinations.map((dest) => NavigationDrawerDestination(
              icon: Icon(dest.icon),
              label: Text(dest.label),
            )),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Divider(),
        ),

        // Group 2: Management (Guides, Games Night, HoF)
        ...managementDestinations.map((dest) => NavigationDrawerDestination(
              icon: Icon(dest.icon),
              label: Text(dest.label),
            )),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Divider(),
        ),

        // Group 3: System (Save/Load, Settings, Profile, About)
        ...systemDestinations.map((dest) => NavigationDrawerDestination(
              icon: Icon(dest.icon),
              label: Text(dest.label),
            )),

        const SizedBox(height: 24),
      ],
    );
  }
}

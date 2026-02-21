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

    const lobbyGroup = <HostDestination>{
      HostDestination.lobby,
    };
    const socialGroup = <HostDestination>{
      HostDestination.game,
    };
    const blackbookGroup = <HostDestination>{
      HostDestination.guides,
    };
    const walletGroup = <HostDestination>{
      HostDestination.profile,
    };
    const aboutGroup = <HostDestination>{
      HostDestination.about,
    };
    const adminGroup = <HostDestination>{
      HostDestination.home,
      HostDestination.saveLoad,
      HostDestination.settings,
      HostDestination.gamesNight,
      HostDestination.hallOfFame,
    };

    List<HostDestinationConfig> configsFor(Set<HostDestination> group) {
      return hostDestinations
          .where((config) => group.contains(config.destination))
          .toList(growable: false);
    }

    final lobbyDestinations = configsFor(lobbyGroup);
    final socialDestinations = configsFor(socialGroup);
    final blackbookDestinations = configsFor(blackbookGroup);
    final walletDestinations = configsFor(walletGroup);
    final aboutDestinations = configsFor(aboutGroup);
    final adminDestinations = configsFor(adminGroup);
    final drawerDestinations = <HostDestinationConfig>[
      ...lobbyDestinations,
      ...socialDestinations,
      ...blackbookDestinations,
      ...walletDestinations,
      ...aboutDestinations,
      ...adminDestinations,
    ];

    final selectedIndex = drawerDestinations
        .indexWhere((d) => d.destination == activeDestination);

    return NavigationDrawer(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      onDestinationSelected: (index) async {
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

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x2, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Lobby',
            icon: Icons.hub_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x2),

        ...lobbyDestinations.map((dest) => NavigationDrawerDestination(
              icon: Icon(dest.icon),
              label: Text(dest.label),
            )),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Group Chat',
            icon: Icons.chat_bubble_outline_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...socialDestinations.map((dest) => NavigationDrawerDestination(
              icon: Icon(dest.icon),
              label: Text(dest.label),
            )),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'The Blackbook',
            icon: Icons.auto_stories_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x2),

        ...blackbookDestinations.map((dest) => NavigationDrawerDestination(
              icon: Icon(dest.icon),
              label: Text(dest.label),
            )),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Wallet',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...walletDestinations.map((dest) => NavigationDrawerDestination(
              icon: Icon(dest.icon),
              label: Text(dest.label),
            )),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'About',
            icon: Icons.info_outline_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...aboutDestinations.map((dest) => NavigationDrawerDestination(
              icon: Icon(dest.icon),
              label: Text(dest.label),
            )),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Admin',
            icon: Icons.tune_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x2),

        ...adminDestinations.map((dest) => NavigationDrawerDestination(
              icon: Icon(dest.icon),
              label: Text(dest.label),
            )),

        const SizedBox(height: 24),
      ],
    );
  }
}

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
      drawerHeader: _buildDrawerHeader(context, theme, colorScheme), // Pass the header
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
          return _DrawerTile(
            icon: dest.icon,
            label: dest.label,
            isSelected: isSelected,
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
          return _DrawerTile(
            icon: dest.icon,
            label: dest.label,
            isSelected: isSelected,
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
          return _DrawerTile(
            icon: dest.icon,
            label: dest.label,
            isSelected: isSelected,
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
          return _DrawerTile(
            icon: dest.icon,
            label: dest.label,
            isSelected: isSelected,
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
          return _DrawerTile(
            icon: dest.icon,
            label: dest.label,
            isSelected: isSelected,
            onTap: () => handleDestinationSelected(idx),
          );
        }),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDrawerHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
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
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w900,
              fontFamily: 'Orbitron',
              letterSpacing: 1.5,
              shadows: CBColors.textGlow(colorScheme.secondary, intensity: 0.5),
            ),
          ),
          const SizedBox(height: CBSpace.x1),
          Text(
            'HOST CONSOLE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CBSpace.x3, vertical: 4),
      child: Material(
        color: CBColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28), // M3 fully rounded
          splashColor: colorScheme.secondary.withValues(alpha: 0.1),
          highlightColor: colorScheme.secondary.withValues(alpha: 0.05),
          child: Container(
            height: 56, // M3 standard height
            decoration: BoxDecoration(
              color: isSelected 
                  ? colorScheme.secondary.withValues(alpha: 0.15) 
                  : CBColors.transparent,
              borderRadius: BorderRadius.circular(28),
              border: isSelected 
                  ? Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.4),
                      width: 1.0,
                    )
                  : Border.all(color: Colors.transparent),
              boxShadow: isSelected 
                  ? [
                      BoxShadow(
                        color: colorScheme.secondary.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: -2,
                      )
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected 
                      ? colorScheme.secondary 
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                  shadows: isSelected 
                      ? CBColors.iconGlow(colorScheme.secondary, intensity: 0.6)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected 
                          ? colorScheme.secondary 
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.5,
                      shadows: isSelected 
                          ? CBColors.textGlow(colorScheme.secondary, intensity: 0.2)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

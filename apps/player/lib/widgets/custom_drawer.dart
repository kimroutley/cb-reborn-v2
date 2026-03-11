import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile_edit_guard.dart';
import '../player_destinations.dart';
import '../player_navigation.dart';
import '../active_bridge.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final currentDestination = ref.watch(playerNavigationProvider);
    
    final phase = ref.watch(activeBridgeProvider).state.phase;
    final gameStarted = phase != 'lobby' && phase != 'setup';

    final gameplayGroup = <PlayerDestination>{
      PlayerDestination.home,
      PlayerDestination.lobby,
      if (gameStarted) PlayerDestination.game,
      PlayerDestination.guides,
    };
    const statsAndAwardsGroup = <PlayerDestination>{
      PlayerDestination.stats,
      PlayerDestination.hallOfFame,
    };
    const gamesNightGroup = <PlayerDestination>{
      PlayerDestination.gamesNight,
    };
    const walletGroup = <PlayerDestination>{
      PlayerDestination.profile,
    };
    const otherGroup = <PlayerDestination>{
      PlayerDestination.about,
      PlayerDestination.settings,
    };

    List<PlayerDestinationConfig> configsFor(Set<PlayerDestination> group) {
      return playerDestinations
          .where((config) => group.contains(config.destination))
          .toList(growable: false);
    }

    final gameplayDestinations = configsFor(gameplayGroup);
    final statsAndAwardsDestinations = configsFor(statsAndAwardsGroup);
    final gamesNightDestinations = configsFor(gamesNightGroup);
    final walletDestinations = configsFor(walletGroup);
    final otherDestinations = configsFor(otherGroup);
    final drawerDestinations = <PlayerDestinationConfig>[
      ...gameplayDestinations,
      ...statsAndAwardsDestinations,
      ...gamesNightDestinations,
      ...walletDestinations,
      ...otherDestinations,
    ];

    final selectedIndex = drawerDestinations
        .indexWhere((config) => config.destination == currentDestination);

    Future<void> handleDestinationSelected(int index) async {
      HapticService.selection();
      final destination = drawerDestinations[index].destination;
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
    }

    return CBSideDrawer(
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      onDestinationSelected: handleDestinationSelected,
      drawerHeader:
          _buildDrawerHeader(context, theme, scheme), // Pass the header
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
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDrawerHeader(
      BuildContext context, ThemeData theme, ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
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
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              fontFamily: 'Orbitron',
              letterSpacing: 1.5,
              shadows: CBColors.textGlow(scheme.primary, intensity: 0.5),
            ),
          ),
          const SizedBox(height: CBSpace.x1),
          Text(
            'PLAYER TERMINAL',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
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
          splashColor: colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: colorScheme.primary.withValues(alpha: 0.05),
          child: Container(
            height: 56, // M3 standard height
            decoration: BoxDecoration(
              color: isSelected 
                  ? colorScheme.primary.withValues(alpha: 0.15) 
                  : CBColors.transparent,
              borderRadius: BorderRadius.circular(28),
              border: isSelected 
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      width: 1.0,
                    )
                  : Border.all(color: Colors.transparent),
              boxShadow: isSelected 
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.1),
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
                  // Filled icon when selected, outlined when not
                  icon,
                  color: isSelected 
                      ? colorScheme.primary 
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                  shadows: isSelected 
                      ? CBColors.iconGlow(colorScheme.primary, intensity: 0.6)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected 
                          ? colorScheme.primary 
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.5,
                      shadows: isSelected 
                          ? CBColors.textGlow(colorScheme.primary, intensity: 0.2)
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

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
      drawerHeader: CBDrawerHeader(
        subtitle: 'PLAYER TERMINAL',
        color: scheme.primary,
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
            color: scheme.primary,
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
            color: scheme.primary,
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
            color: scheme.primary,
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
            color: scheme.primary,
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
            color: scheme.primary,
            onTap: () => handleDestinationSelected(idx),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }
}

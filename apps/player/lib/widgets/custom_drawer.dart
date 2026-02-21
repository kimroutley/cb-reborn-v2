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
    final scheme = Theme.of(context).colorScheme;
    final currentDestination = ref.watch(playerNavigationProvider);
    const lobbyGroup = <PlayerDestination>{
      PlayerDestination.home,
    };
    const socialGroup = <PlayerDestination>{
      PlayerDestination.game,
    };
    const referenceGroup = <PlayerDestination>{
      PlayerDestination.guides,
    };
    const walletGroup = <PlayerDestination>{
      PlayerDestination.profile,
      PlayerDestination.stats,
      PlayerDestination.hallOfFame,
    };
    const aboutGroup = <PlayerDestination>{
      PlayerDestination.about,
    };
    const barTabGroup = <PlayerDestination>{
      PlayerDestination.gamesNight,
    };

    List<PlayerDestinationConfig> configsFor(Set<PlayerDestination> group) {
      return playerDestinations
          .where((config) => group.contains(config.destination))
          .toList(growable: false);
    }

    final lobbyDestinations = configsFor(lobbyGroup);
    final socialDestinations = configsFor(socialGroup);
    final referenceDestinations = configsFor(referenceGroup);
    final walletDestinations = configsFor(walletGroup);
    final aboutDestinations = configsFor(aboutGroup);
    final barTabDestinations = configsFor(barTabGroup);
    final drawerDestinations = <PlayerDestinationConfig>[
      ...lobbyDestinations,
      ...socialDestinations,
      ...referenceDestinations,
      ...walletDestinations,
      ...aboutDestinations,
      ...barTabDestinations,
    ];

    final selectedIndex = drawerDestinations
        .indexWhere((config) => config.destination == currentDestination);

    return NavigationDrawer(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.secondaryContainer,
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      onDestinationSelected: (index) async {
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
      },
      children: [
        _buildDrawerHeader(context),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x2, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Lobby',
            icon: Icons.hub_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...lobbyDestinations.map(
          (dest) => NavigationDrawerDestination(
            icon: Icon(dest.icon),
            label: Text(dest.label),
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Group Chat',
            icon: Icons.chat_bubble_outline_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...socialDestinations.map(
          (dest) => NavigationDrawerDestination(
            icon: Icon(dest.icon),
            label: Text(dest.label),
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'The Blackbook',
            icon: Icons.auto_stories_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...referenceDestinations.map(
          (dest) => NavigationDrawerDestination(
            icon: Icon(dest.icon),
            label: Text(dest.label),
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Wallet',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...walletDestinations.map(
          (dest) => NavigationDrawerDestination(
            icon: Icon(dest.icon),
            label: Text(dest.label),
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'About',
            icon: Icons.info_outline_rounded,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...aboutDestinations.map(
          (dest) => NavigationDrawerDestination(
            icon: Icon(dest.icon),
            label: Text(dest.label),
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, 0),
          child: CBSectionHeader(
            title: 'Bar Tab',
            icon: Icons.wine_bar_outlined,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...barTabDestinations.map(
          (dest) => NavigationDrawerDestination(
            icon: Icon(dest.icon),
            label: Text(dest.label),
          ),
        ),

        const SizedBox(height: 12),
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

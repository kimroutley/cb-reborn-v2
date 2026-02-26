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

    const gameplayGroup = <PlayerDestination>{
      PlayerDestination.connect,
      PlayerDestination.game,
      PlayerDestination.guides,
    };
    const statsGroup = <PlayerDestination>{
      PlayerDestination.stats,
      PlayerDestination.hallOfFame,
    };
    const socialGroup = <PlayerDestination>{
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
          .where((c) => group.contains(c.destination))
          .toList(growable: false);
    }

    final gameplay = configsFor(gameplayGroup);
    final stats = configsFor(statsGroup);
    final social = configsFor(socialGroup);
    final wallet = configsFor(walletGroup);
    final other = configsFor(otherGroup);

    final allDests = [
      ...gameplay,
      ...stats,
      ...social,
      ...wallet,
      ...other,
    ];
    final selectedIndex =
        allDests.indexWhere((c) => c.destination == currentDestination);

    final entries = <CBDrawerEntry>[
      const CBDrawerSection(title: 'Gameplay', icon: Icons.gamepad_outlined),
      ...gameplay.map(_dest),
      const CBDrawerSection(
          title: 'Stats & Awards', icon: Icons.emoji_events_outlined),
      ...stats.map(_dest),
      const CBDrawerSection(title: 'Social', icon: Icons.group_outlined),
      ...social.map(_dest),
      const CBDrawerSection(
          title: 'Wallet', icon: Icons.account_balance_wallet_outlined),
      ...wallet.map(_dest),
      const CBDrawerSection(title: 'Other', icon: Icons.more_horiz_outlined),
      ...other.map(_dest),
    ];

    return CBSideDrawer(
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      onDestinationSelected: (index) async {
        HapticService.selection();
        final destination = allDests[index].destination;
        if (destination == currentDestination) return;

        final canLeave = await _confirmDiscardProfileChanges(
          context,
          ref,
          destination,
        );
        if (!context.mounted || !canLeave) return;

        ref
            .read(playerNavigationProvider.notifier)
            .setDestination(destination);
        try {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        } catch (_) {}
      },
      drawerHeader: _DrawerHeader(scheme: scheme),
      entries: entries,
    );
  }

  static CBDrawerDestination _dest(PlayerDestinationConfig c) {
    return CBDrawerDestination(icon: c.icon, label: c.label);
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final ColorScheme scheme;
  const _DrawerHeader({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 20, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.nightlife_rounded,
              size: 18,
              color: scheme.primary,
              shadows: CBColors.iconGlow(scheme.primary, intensity: 0.5),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLUB BLACKOUT',
                  style: text.titleSmall?.copyWith(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    shadows: CBColors.textGlow(scheme.secondary, intensity: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'PLAYER TERMINAL',
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    letterSpacing: 1.6,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

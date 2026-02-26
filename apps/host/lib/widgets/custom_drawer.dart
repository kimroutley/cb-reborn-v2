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
    final scheme = Theme.of(context).colorScheme;
    final HostDestination activeDestination =
        currentDestination ?? ref.watch(hostNavigationProvider);

    const gameplayGroup = <HostDestination>{
      HostDestination.lobby,
      HostDestination.game,
      HostDestination.guides,
    };
    const statsGroup = <HostDestination>{
      HostDestination.hallOfFame,
    };
    const socialGroup = <HostDestination>{
      HostDestination.gamesNight,
    };
    const accountGroup = <HostDestination>{
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
          .where((c) => group.contains(c.destination))
          .toList(growable: false);
    }

    final gameplay = configsFor(gameplayGroup);
    final stats = configsFor(statsGroup);
    final social = configsFor(socialGroup);
    final account = configsFor(accountGroup);
    final other = configsFor(otherGroup);

    final allDests = [
      ...gameplay,
      ...stats,
      ...social,
      ...account,
      ...other,
    ];
    final selectedIndex =
        allDests.indexWhere((d) => d.destination == activeDestination);

    final entries = <CBDrawerEntry>[
      const CBDrawerSection(title: 'Gameplay', icon: Icons.gamepad_outlined),
      ...gameplay.map(_dest),
      const CBDrawerSection(
          title: 'Stats & Awards', icon: Icons.emoji_events_outlined),
      ...stats.map(_dest),
      const CBDrawerSection(title: 'Social', icon: Icons.group_outlined),
      ...social.map(_dest),
      const CBDrawerSection(
          title: 'Account', icon: Icons.account_circle_outlined),
      ...account.map(_dest),
      const CBDrawerSection(title: 'Other', icon: Icons.more_horiz_outlined),
      ...other.map(_dest),
    ];

    return CBSideDrawer(
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      onDestinationSelected: (index) async {
        HapticService.selection();
        final destination = allDests[index].destination;
        if (destination == activeDestination) return;

        final canLeave = await _confirmDiscardProfileChanges(
          context,
          ref,
          activeDestination,
          destination,
        );
        if (!context.mounted || !canLeave) return;

        if (onDrawerItemTap != null) {
          onDrawerItemTap!(destination);
        } else {
          ref
              .read(hostNavigationProvider.notifier)
              .setDestination(destination);
        }

        try {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        } catch (_) {}
      },
      drawerHeader: _DrawerHeader(scheme: scheme),
      entries: entries,
    );
  }

  static CBDrawerDestination _dest(HostDestinationConfig c) {
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
                color: scheme.secondary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.secondary.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.shield_rounded,
              size: 18,
              color: scheme.secondary,
              shadows: CBColors.iconGlow(scheme.secondary, intensity: 0.5),
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
                  'HOST CONSOLE',
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

import 'package:flutter/material.dart';

enum HostDestination {
  home,
  lobby,
  game,
  guides,
  gamesNight,
  hallOfFame,
  saveLoad,
  settings,
  profile,
  about,
}

@immutable
class HostDestinationConfig {
  final HostDestination destination;
  final String label;
  final IconData icon;

  const HostDestinationConfig({
    required this.destination,
    required this.label,
    required this.icon,
  });
}

const hostDestinations = <HostDestinationConfig>[
  HostDestinationConfig(
    destination: HostDestination.home,
    label: 'Command Center',
    icon: Icons.home_outlined,
  ),
  HostDestinationConfig(
    destination: HostDestination.lobby,
    label: 'Lobby',
    icon: Icons.group_outlined,
  ),
  HostDestinationConfig(
    destination: HostDestination.game,
    label: 'Group Chat',
    icon: Icons.chat_bubble_outline_rounded,
  ),
  HostDestinationConfig(
    destination: HostDestination.guides,
    label: 'The Blackbook',
    icon: Icons.menu_book_outlined,
  ),
  HostDestinationConfig(
    destination: HostDestination.gamesNight,
    label: 'Games Night',
    icon: Icons.wine_bar_outlined,
  ),
  HostDestinationConfig(
    destination: HostDestination.hallOfFame,
    label: 'Hall of Fame',
    icon: Icons.shield_outlined,
  ),
  HostDestinationConfig(
    destination: HostDestination.saveLoad,
    label: 'Save/Load Game',
    icon: Icons.save_alt_outlined,
  ),
  HostDestinationConfig(
    destination: HostDestination.settings,
    label: 'Settings',
    icon: Icons.settings_outlined,
  ),
  HostDestinationConfig(
    destination: HostDestination.profile,
    label: 'Wallet',
    icon: Icons.account_balance_wallet_outlined,
  ),
  HostDestinationConfig(
    destination: HostDestination.about,
    label: 'About',
    icon: Icons.info_outline,
  ),
];

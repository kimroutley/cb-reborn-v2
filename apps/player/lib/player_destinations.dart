import 'package:flutter/material.dart';

enum PlayerDestination {
  home,
  lobby,
  claim,
  transition,
  game,
  guides,
  gamesNight,
  hallOfFame,
  profile,
  stats,
  about,
}

@immutable
class PlayerDestinationConfig {
  final PlayerDestination destination;
  final String label;
  final IconData icon;

  const PlayerDestinationConfig({
    required this.destination,
    required this.label,
    required this.icon,
  });
}

const playerDestinations = <PlayerDestinationConfig>[
  PlayerDestinationConfig(
    destination: PlayerDestination.home,
    label: 'Home',
    icon: Icons.home_outlined,
  ),
  PlayerDestinationConfig(
    destination: PlayerDestination.lobby,
    label: 'Club Lounge',
    icon: Icons.group_outlined,
  ),
  PlayerDestinationConfig(
    destination: PlayerDestination.claim,
    label: 'Entry Terminal',
    icon: Icons.vpn_key_outlined,
  ),
  PlayerDestinationConfig(
    destination: PlayerDestination.game,
    label: 'Session Feed',
    icon: Icons.play_circle_outline,
  ),
  PlayerDestinationConfig(
    destination: PlayerDestination.guides,
    label: 'Game Bible',
    icon: Icons.menu_book_outlined,
  ),
  PlayerDestinationConfig(
    destination: PlayerDestination.gamesNight,
    label: 'Games Night',
    icon: Icons.wine_bar_outlined,
  ),
  PlayerDestinationConfig(
    destination: PlayerDestination.profile,
    label: 'Profile',
    icon: Icons.badge_outlined,
  ),
  PlayerDestinationConfig(
    destination: PlayerDestination.stats,
    label: 'Career Stats',
    icon: Icons.show_chart_rounded,
  ),
  PlayerDestinationConfig(
    destination: PlayerDestination.hallOfFame,
    label: 'Hall of Fame',
    icon: Icons.emoji_events_outlined,
  ),
  PlayerDestinationConfig(
    destination: PlayerDestination.about,
    label: 'About',
    icon: Icons.info_outline,
  ),
];

import 'package:flutter/material.dart';
import 'package:cb_models/cb_models.dart';

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

class HostDestinationConfig extends AbstractDestinationConfig<HostDestination> {
  const HostDestinationConfig({
    required super.destination,
    required super.label,
    required super.icon,
  });
}

const hostDestinations = <HostDestinationConfig>[
  HostDestinationConfig(
    destination: HostDestination.home,
    label: 'Home',
    icon: Icons.home_rounded,
  ),
  HostDestinationConfig(
    destination: HostDestination.lobby,
    label: 'Lobby',
    icon: Icons.hub_rounded,
  ),
  HostDestinationConfig(
    destination: HostDestination.game,
    label: 'Game',
    icon: Icons.casino_rounded,
  ),
  HostDestinationConfig(
    destination: HostDestination.profile,
    label: 'Profile',
    icon: Icons.person_rounded,
  ),
  HostDestinationConfig(
    destination: HostDestination.settings,
    label: 'Settings',
    icon: Icons.settings_rounded,
  ),
  HostDestinationConfig(
    destination: HostDestination.guides,
    label: 'Guides',
    icon: Icons.auto_stories_rounded,
  ),
  HostDestinationConfig(
    destination: HostDestination.about,
    label: 'About',
    icon: Icons.info_outline_rounded,
  ),
  HostDestinationConfig(
    destination: HostDestination.gamesNight,
    label: 'Games Night',
    icon: Icons.group_rounded,
  ),
  HostDestinationConfig(
    destination: HostDestination.hallOfFame,
    label: 'Hall of Fame',
    icon: Icons.emoji_events_rounded,
  ),
  HostDestinationConfig(
    destination: HostDestination.saveLoad,
    label: 'Save/Load Game',
    icon: Icons.save_rounded,
  ),
];

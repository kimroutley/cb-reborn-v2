import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_destinations.dart';
import '../host_navigation.dart';
import 'games_night_screen.dart';
import 'guides_screen.dart';
import 'host_game_screen.dart';
import 'host_hall_of_fame_screen.dart';
import 'host_lobby_screen.dart';
import 'home_screen.dart';
import 'host_save_load_screen.dart';
import 'privacy_policy_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Central destination host for the Host app.
///
/// Drawer taps update [hostNavigationProvider], and this shell reacts to that
/// state to render the correct destination screen.
class HostNavigationShell extends ConsumerWidget {
  const HostNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = ref.watch(hostNavigationProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(
        key: ValueKey<HostDestination>(destination),
        child: _buildDestination(destination),
      ),
    );
  }

  Widget _buildDestination(HostDestination destination) {
    switch (destination) {
      case HostDestination.home:
        return const HomeScreen();
      case HostDestination.guides:
        return const GuidesScreen();
      case HostDestination.gamesNight:
        return const GamesNightScreen();
      case HostDestination.settings:
        return const SettingsScreen();
      case HostDestination.profile:
        return const ProfileScreen();
      case HostDestination.about:
        return const PrivacyPolicyScreen();
      case HostDestination.lobby:
        return const HostLobbyScreen();
      case HostDestination.game:
        return const HostGameScreen();
      case HostDestination.hallOfFame:
        return const HostHallOfFameScreen();
      case HostDestination.saveLoad:
        return const HostSaveLoadScreen();
    }
  }
}

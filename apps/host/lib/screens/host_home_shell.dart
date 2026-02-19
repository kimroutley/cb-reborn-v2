import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cloud_host_bridge.dart';
import '../host_bridge.dart';
import '../host_destinations.dart';
import '../host_navigation.dart';
import '../sync_mode_runtime.dart';
import 'about_screen.dart';
import 'game_screen.dart';
import 'games_night_screen.dart';
import 'guides_screen.dart';
import 'hall_of_fame_screen.dart';
import 'home_screen.dart';
import 'lobby_screen.dart';
import 'profile_screen.dart';
import 'save_load_screen.dart';
import 'settings_screen.dart';

class HostHomeShell extends ConsumerStatefulWidget {
  const HostHomeShell({super.key});

  @override
  ConsumerState<HostHomeShell> createState() => _HostHomeShellState();
}

class _HostHomeShellState extends ConsumerState<HostHomeShell> {
  // Navigation state is now managed by hostNavigationProvider

  Future<void> _syncBridgesForMode(SyncMode mode) async {
    final localBridge = ref.read(hostBridgeProvider);
    final cloudBridge = ref.read(cloudHostBridgeProvider);

    await syncHostBridgesForMode(
      mode: mode,
      stopLocal: localBridge.stop,
      startLocal: localBridge.start,
      stopCloud: cloudBridge.stop,
      startCloud: cloudBridge.start,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Attempt crash-recovery from persisted game state.
      final gameController = ref.read(gameProvider.notifier);
      final restored = gameController.tryRestoreGame();

      final syncMode = ref.read(gameProvider).syncMode;
      await _syncBridgesForMode(syncMode);

      if (!restored || !mounted) {
        return;
      }

      // If game restored, navigate to the appropriate screen via provider
      final gameState = ref.read(gameProvider);
      if (gameState.phase == GamePhase.lobby) {
        ref
            .read(hostNavigationProvider.notifier)
            .setDestination(HostDestination.lobby);
      } else if (gameState.phase != GamePhase.endGame) {
        ref
            .read(hostNavigationProvider.notifier)
            .setDestination(HostDestination.game);
      }

      showThemedSnackBar(
        context,
        'Previous game restored.',
        accentColor: Theme.of(context).colorScheme.tertiary,
        duration: const Duration(seconds: 3),
      );
    });
  }

  Widget _screenFor(HostDestination destination) {
    switch (destination) {
      case HostDestination.home:
        return const HomeScreen();
      case HostDestination.lobby:
        return const LobbyScreen();
      case HostDestination.game:
        return const GameScreen();
      case HostDestination.guides:
        return const GuidesScreen();
      case HostDestination.gamesNight:
        return const GamesNightScreen();
      case HostDestination.hallOfFame:
        return const HallOfFameScreen();
      case HostDestination.saveLoad:
        return const SaveLoadScreen();
      case HostDestination.settings:
        return const SettingsScreen();
      case HostDestination.profile:
        return const ProfileScreen();
      case HostDestination.about:
        return const AboutScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = ref.watch(hostNavigationProvider);
    final child = _screenFor(destination);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: child,
    );
  }
}

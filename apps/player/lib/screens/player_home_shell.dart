import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_theme/cb_theme.dart'; // Import for CBMotion

import '../player_destinations.dart';
import '../player_navigation.dart';
import '../active_bridge.dart';
import '../player_onboarding_provider.dart';
import 'claim_screen.dart';
import 'connect_screen.dart';
import 'lobby_screen.dart';
import 'profile_screen.dart';
import 'game_screen.dart';
import 'start_transition_screen.dart';
import 'guides_screen.dart';
import 'games_night_screen.dart';
import 'hall_of_fame_screen.dart';
import 'stats_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';

// Trigger provider for confirming game start
final confirmGameStartProvider =
    NotifierProvider<ConfirmGameStartNotifier, int>(
        ConfirmGameStartNotifier.new);

class ConfirmGameStartNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state++;
}

class PlayerHomeShell extends ConsumerStatefulWidget {
  const PlayerHomeShell({
    super.key,
    this.startConfirmTimeout = const Duration(seconds: 10),
    this.transitionDuration = CBMotion.transition, // Using CBMotion.transition
  });

  final Duration startConfirmTimeout;
  final Duration transitionDuration;

  @override
  ConsumerState<PlayerHomeShell> createState() => _PlayerHomeShellState();
}

class _PlayerHomeShellState extends ConsumerState<PlayerHomeShell> {
  bool _handlingSetupTransition = false;

  static const Set<PlayerDestination> _sessionBoundDestinations = {
    PlayerDestination.lobby,
    PlayerDestination.claim,
    PlayerDestination.transition,
    PlayerDestination.game,
  };

  @override
  void initState() {
    super.initState();
    ref.listenManual(activeBridgeProvider, _onBridgeChanged);
    ref.listenManual(confirmGameStartProvider, (_, count) {
      if (count > 0) {
        _handleManualStartConfirmation();
      }
    });
  }

  void _handleManualStartConfirmation() {
    final onboarding = ref.read(playerOnboardingProvider);

    if (onboarding.awaitingStartConfirmation) {
      ref
          .read(playerOnboardingProvider.notifier)
          .setAwaitingStartConfirmation(false);
      _beginTransitionToGame();
    }
  }

  void _onBridgeChanged(ActiveBridge? previous, ActiveBridge next) {
    final nav = ref.read(playerNavigationProvider.notifier);
    final onboarding = ref.read(playerOnboardingProvider.notifier);

    final prevState = previous?.state;
    final prevPhase = prevState?.phase;
    final prevConnected = prevState?.isConnected ?? false;
    final prevJoinAccepted = prevState?.joinAccepted ?? false;

    final nextState = next.state;
    final nextPhase = nextState.phase;
    final nextConnected = nextState.isConnected;
    final nextJoinAccepted = nextState.joinAccepted;

    final hasBridgeSession = nextConnected || nextJoinAccepted;
    if (!hasBridgeSession) {
      _handlingSetupTransition = false;
      onboarding.reset();

      final currentDestination = ref.read(playerNavigationProvider);
      if (_sessionBoundDestinations.contains(currentDestination)) {
        nav.setDestination(PlayerDestination.connect);
      }
      return;
    }

    final connectedNow = !prevConnected && nextConnected;
    final acceptedNow = !prevJoinAccepted && nextJoinAccepted;
    final destination = ref.read(playerNavigationProvider);
    if ((connectedNow || acceptedNow) &&
        nextPhase == 'lobby' &&
        destination == PlayerDestination.connect) {
      // No auto-navigate: Connect screen shows group chat and "Continue to Lounge".
    }

    if (nextPhase == prevPhase) {
      return;
    }

    switch (nextPhase) {
      case 'lobby':
        _handlingSetupTransition = false;
        onboarding.setAwaitingStartConfirmation(false);
        nav.setDestination(PlayerDestination.lobby);
        break;
      case 'setup':
        if (_handlingSetupTransition) {
          return;
        }
        _handlingSetupTransition = true;
        onboarding.setAwaitingStartConfirmation(true);
        nav.setDestination(PlayerDestination.lobby);
        break;
      case 'night':
      case 'day':
      case 'resolution':
      case 'endGame':
        _handlingSetupTransition = false;
        onboarding.setAwaitingStartConfirmation(false);
        nav.setDestination(PlayerDestination.game);
        break;
      default:
        break;
    }

    if (nextPhase == 'setup') {
      final myId = nextState.myPlayerId;
      final isRoleConfirmed =
          myId != null && nextState.roleConfirmedPlayerIds.contains(myId);
      if (isRoleConfirmed) {
        onboarding.setAwaitingStartConfirmation(false);
        _beginTransitionToGame();
      }
    }
  }

  void _beginTransitionToGame() {
    if (!mounted) {
      return;
    }

    final nav = ref.read(playerNavigationProvider.notifier);
    nav.setDestination(PlayerDestination.transition);

    Future<void>.delayed(widget.transitionDuration, () {
      if (!mounted) {
        return;
      }
      nav.setDestination(PlayerDestination.game);
      _handlingSetupTransition = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final destination = ref.watch(playerNavigationProvider);

    Widget activeWidget;
    switch (destination) {
      case PlayerDestination.connect:
        activeWidget = const ConnectScreen();
        break;
      case PlayerDestination.lobby:
        activeWidget = const LobbyScreen();
        break;
      case PlayerDestination.claim:
        activeWidget = ClaimScreen(); // Retained for explicit claim screen
        break;
      case PlayerDestination.transition:
        activeWidget = const StartTransitionScreen();
        break;
      case PlayerDestination.game:
        activeWidget = const GameScreen();
        break;
      case PlayerDestination.guides:
        activeWidget = const GuidesScreen();
        break;
      case PlayerDestination.gamesNight:
        activeWidget = const GamesNightScreen();
        break;
      case PlayerDestination.hallOfFame:
        activeWidget = const HallOfFameScreen();
        break;
      case PlayerDestination.profile:
        activeWidget = const ProfileScreen();
        break;
      case PlayerDestination.stats:
        activeWidget = const StatsScreen();
        break;
      case PlayerDestination.about:
        activeWidget = const AboutScreen();
        break;
      case PlayerDestination.settings:
        activeWidget = const SettingsScreen();
        break;
    }

    return AnimatedSwitcher(
      duration: CBMotion.transition,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: CBMotion.emphasizedCurve,
            )),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(destination),
        child: activeWidget,
      ),
    );
  }
}

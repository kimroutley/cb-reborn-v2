import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../player_destinations.dart';
import '../player_navigation.dart';
import '../active_bridge.dart';
import '../player_onboarding_provider.dart';
import 'home_screen.dart';
import 'lobby_screen.dart';
import 'profile_screen.dart';
import 'claim_screen.dart';
import 'game_screen.dart';
import 'start_transition_screen.dart';
import 'guides_screen.dart';
import 'games_night_screen.dart';
import 'hall_of_fame_screen.dart';
import 'stats_screen.dart';
import 'about_screen.dart';
import '../widgets/custom_drawer.dart';

class PlayerHomeShell extends ConsumerStatefulWidget {
  const PlayerHomeShell({
    super.key,
    this.startConfirmTimeout = const Duration(seconds: 10),
    this.transitionDuration = const Duration(milliseconds: 2200),
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
        nav.setDestination(PlayerDestination.home);
      }
      return;
    }

    final connectedNow = !prevConnected && nextConnected;
    final acceptedNow = !prevJoinAccepted && nextJoinAccepted;
    final destination = ref.read(playerNavigationProvider);
    if ((connectedNow || acceptedNow) &&
        nextPhase == 'lobby' &&
        destination == PlayerDestination.home) {
      nav.setDestination(PlayerDestination.lobby);
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
        _showStartConfirmationDialog();
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
  }

  void _showStartConfirmationDialog() {
    if (widget.startConfirmTimeout <= Duration.zero) {
      ref
          .read(playerOnboardingProvider.notifier)
          .setAwaitingStartConfirmation(false);
      _beginTransitionToGame();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      var dialogCompleted = false;
      final timeoutSeconds = widget.startConfirmTimeout.inSeconds;

      final dialogFuture = showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('GAME STARTED'),
              content: Text(
                'The host started the game. Confirm and enter the session now. '
                'Auto-join starts in ${timeoutSeconds}s.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('JOIN NOW'),
                ),
              ],
            ),
          );
        },
      ).then((value) {
        dialogCompleted = true;
        return value ?? false;
      });

      final autoJoinFuture = Future<bool>.delayed(
        widget.startConfirmTimeout,
        () => true,
      );

      final shouldJoin = await Future.any<bool>([
        dialogFuture,
        autoJoinFuture,
      ]);

      if (!mounted) {
        return;
      }

      if (!dialogCompleted) {
        Navigator.of(context, rootNavigator: true).pop(true);
      }

      ref
          .read(playerOnboardingProvider.notifier)
          .setAwaitingStartConfirmation(false);
      if (shouldJoin) {
        _beginTransitionToGame();
      } else {
        _handlingSetupTransition = false;
      }
    });
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
      case PlayerDestination.home:
        activeWidget = const HomeScreen();
        break;
      case PlayerDestination.lobby:
        activeWidget = const LobbyScreen();
        break;
      case PlayerDestination.claim:
        activeWidget = const ClaimScreen();
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
    }

    return Scaffold(
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(destination),
              child: activeWidget,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Builder(
                builder: (context) => IconButton(
                  key: const ValueKey('player_shell_menu_button'),
                  tooltip: 'Open menu',
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

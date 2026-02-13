import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/join_link_state.dart';
import 'package:cb_player/player_stats.dart';
import 'package:cb_player/screens/connect_screen.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_drawer.dart';
import 'guides_screen.dart';
import 'games_night_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  StreamSubscription<Uri>? _linkSub;
  String? _lastHandledJoinUrl;
  DateTime? _lastHandledJoinAt;
  bool _isConnectSheetOpen = false;

  static const Duration _joinUrlDebounceWindow = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    final appLinks = AppLinks();
    _linkSub = appLinks.uriLinkStream.listen((uri) {
      if (!mounted) {
        return;
      }
      final url = uri.toString();
      if (uri.queryParameters.containsKey('code') &&
          (uri.queryParameters.containsKey('mode') ||
              uri.path.contains('join')) &&
          !_isSameJoinUrlInDebounceWindow(url)) {
        ref.read(pendingJoinUrlProvider.notifier).setValue(url);
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    final playerState = ref.watch(playerBridgeProvider);

    final pendingJoinUrl = ref.watch(pendingJoinUrlProvider);
    if (pendingJoinUrl != null &&
        pendingJoinUrl.isNotEmpty &&
        !_isSameJoinUrlInDebounceWindow(pendingJoinUrl) &&
        !_isConnectSheetOpen &&
        !(playerState.isConnected && !playerState.isLobby)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _lastHandledJoinUrl = pendingJoinUrl;
        _lastHandledJoinAt = DateTime.now();
        _showConnectScreen(ref, initialJoinUrl: pendingJoinUrl);
        ref.read(pendingJoinUrlProvider.notifier).setValue(null);
      });
    } else if (pendingJoinUrl != null && pendingJoinUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref.read(pendingJoinUrlProvider.notifier).setValue(null);
      });
    }

    // Watch stats for the current player
    if (playerState.myPlayerId != null) {
      ref
          .read(playerStatsProvider.notifier)
          .setActivePlayerId(playerState.myPlayerId!);
    }
    final stats = ref.watch(playerStatsProvider);

    return CBPrismScaffold(
      title: 'CLUB BLACKOUT',
      drawer: const CustomDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: CBSpace.x6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: CBSpace.x8),

              // ── LOGO / TITLE AREA ──
              CBFadeSlide(
                key: const ValueKey('home_welcome'),
                child: Text(
                  'WELCOME TO',
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium!.copyWith(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                    shadows: CBColors.textGlow(scheme.secondary),
                  ),
                ),
              ),
              const SizedBox(height: CBSpace.x2),
              CBFadeSlide(
                key: const ValueKey('home_title'),
                delay: const Duration(milliseconds: 80),
                child: Text(
                  'CLUB\nBLACKOUT',
                  textAlign: TextAlign.center,
                  style: textTheme.displayLarge!.copyWith(
                    color: scheme.primary,
                    height: 0.9,
                    fontWeight: FontWeight.w900,
                    shadows: CBColors.textGlow(scheme.primary, intensity: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: CBSpace.x12),

              // ── CAREER SNAPSHOT (Informative) ──
              CBFadeSlide(
                key: const ValueKey('home_stats'),
                delay: const Duration(milliseconds: 140),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(CBRadius.md),
                    border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat(context, 'GAMES', '${stats.gamesPlayed}',
                          scheme.primary),
                      _buildMiniStat(context, 'WINS', '${stats.gamesWon}',
                          scheme.tertiary),
                      _buildMiniStat(
                          context,
                          'FAV ROLE',
                          stats.favoriteRole.split(' ').first,
                          scheme.secondary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: CBSpace.x8),

              // ── MAIN ACTION ──
              CBFadeSlide(
                key: const ValueKey('home_enter'),
                delay: const Duration(milliseconds: 200),
                child: CBGlassTile(
                  title: "ENTER THE CLUB",
                  subtitle: "JOIN A SESSION OR CONNECT LOCALLY",
                  accentColor: scheme.primary,
                  isPrismatic: true,
                  icon: Icon(Icons.login_rounded, color: scheme.primary),
                  onTap: () => _showConnectScreen(ref),
                  content: const SizedBox.shrink(),
                ),
              ),

              const SizedBox(height: CBSpace.x4),

              // ── SECONDARY ACTIONS ──
              CBFadeSlide(
                key: const ValueKey('home_secondary'),
                delay: const Duration(milliseconds: 260),
                child: Row(
                  children: [
                    Expanded(
                      child: CBGhostButton(
                        label: 'GUIDES',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const GuidesScreen()),
                          );
                        },
                        color: scheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CBGhostButton(
                        label: 'HISTORY',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const GamesNightScreen()),
                          );
                        },
                        color: scheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CBSpace.x12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(
      BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                shadows: CBColors.textGlow(color, intensity: 0.3),
              ),
        ),
        Text(
          label,
          style: CBTypography.micro.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  bool _isSameJoinUrlInDebounceWindow(String url) {
    if (_lastHandledJoinUrl != url || _lastHandledJoinAt == null) {
      return false;
    }
    return DateTime.now().difference(_lastHandledJoinAt!) <
        _joinUrlDebounceWindow;
  }

  Future<void> _showConnectScreen(
    WidgetRef ref, {
    String? initialJoinUrl,
  }) async {
    if (_isConnectSheetOpen) {
      return;
    }
    _isConnectSheetOpen = true;

    final scheme = Theme.of(context).colorScheme;
    try {
      await showThemedBottomSheetBuilder<void>(
        context: context,
        accentColor: scheme.primary,
        builder: (_) => ConnectScreen(initialJoinUrl: initialJoinUrl),
      );
    } finally {
      _isConnectSheetOpen = false;
    }
  }
}

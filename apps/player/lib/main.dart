import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'join_link_state.dart';

import 'firebase_options.dart';
import 'screens/stats_screen.dart';
import 'screens/hall_of_fame_screen.dart';
import 'screens/intro_screen.dart';

Future<void> _initializeFirebaseServices() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  AnalyticsService.setProvider(
    FirebaseAnalyticsProvider(FirebaseAnalytics.instance),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _initializeFirebaseServices();

    final launchUri = Uri.base;
    final hasJoinPayload = launchUri.queryParameters.containsKey('code') &&
        (launchUri.queryParameters.containsKey('mode') ||
            launchUri.path.contains('join'));
    final initialJoinUrl = hasJoinPayload ? launchUri.toString() : null;

    runApp(
      ProviderScope(
        overrides: [
          pendingJoinUrlProvider.overrideWith(
            () => PendingJoinUrlNotifier()..setValue(initialJoinUrl),
          ),
        ],
        child: const PlayerApp(),
      ),
    );
  } catch (e) {
    final scheme = CBTheme.buildColorScheme(CBTheme.defaultSeedColor);
    final theme = CBTheme.buildTheme(scheme);
    runApp(MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: CBNeonBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: CBInsets.panel,
                child: CBPanel(
                  borderColor: scheme.error,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: scheme.error, size: 48),
                      const SizedBox(height: CBSpace.x4),
                      Text(
                        'Club Blackout Failed to Load',
                        style:
                            CBTypography.h2.copyWith(color: scheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: CBSpace.x2),
                      Text(
                        'Error: $e',
                        style: CBTypography.body.copyWith(
                          color: scheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: CBSpace.x6),
                      Text(
                        "Troubleshooting:\n1. Ensure Google authentication is enabled in Firebase Console.\n2. Verify Firestore rules allow user_profiles/{uid} create/read.",
                        style: CBTypography.body.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class PlayerApp extends ConsumerWidget {
  const PlayerApp({super.key});

  static final Future<Color> _seedFuture =
      ImageProcessingService.sampleSeedFromGlobalBackground();

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return FutureBuilder<Color>(
      future: _seedFuture,
      builder: (context, snapshot) => DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          final seed = snapshot.data ??
              darkDynamic?.primary ??
              lightDynamic?.primary ??
              CBTheme.defaultSeedColor;
          final scheme = CBTheme.buildColorScheme(seed);

          return MaterialApp(
            title: 'Club Blackout: PLAYER',
            theme: CBTheme.buildTheme(scheme),
            routes: {
              '/stats': (context) => const StatsScreen(),
              '/hall-of-fame': (context) => const HallOfFameScreen(),
            },
            home: const PlayerIntroScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

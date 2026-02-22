import 'dart:async';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'widgets/effects_overlay.dart';
import 'screens/intro_screen.dart';

import 'host_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await _initializePersistenceOfflineFirst();
  await _initializeFirebaseServices();

  runApp(const ProviderScope(
    child: HostApp(),
  ));
}

Future<void> _initializePersistenceOfflineFirst() async {
  try {
    await PersistenceService.init().timeout(const Duration(seconds: 5));
    return;
  } catch (e) {
    debugPrint('[HostApp] Persistence init failed/timed out: $e');
  }

  // Fallback: initialize non-encrypted local boxes so host can still launch
  // and run local/offline sessions even if secure persistence setup fails.
  try {
    final activeBox = await Hive.openBox<String>('active_game_fallback');
    final recordsBox = await Hive.openBox<String>('game_records_fallback');
    final sessionsBox = await Hive.openBox<String>('games_night_fallback');
    PersistenceService.initWithBoxes(activeBox, recordsBox, sessionsBox);
    debugPrint(
        '[HostApp] Using fallback persistence boxes for offline startup');
  } catch (e) {
    debugPrint('[HostApp] Fallback persistence init failed: $e');
  }
}

Future<void> _initializeFirebaseServices() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    AnalyticsService.setProvider(
      FirebaseAnalyticsProvider(FirebaseAnalytics.instance),
    );
  } catch (e) {
    // Startup must remain usable offline/local-mode even if Firebase init fails.
    debugPrint('[HostApp] Firebase init deferred/failed: $e');
  }
}

class HostApp extends ConsumerWidget {
  const HostApp({super.key});

  static final Future<Color> _seedFuture =
      ImageProcessingService.sampleSeedFromGlobalBackground();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(hostSettingsProvider);

    return FutureBuilder<Color>(
      future: _seedFuture,
      builder: (context, snapshot) => DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          final seed = snapshot.data ??
              darkDynamic?.primary ??
              lightDynamic?.primary ??
              CBTheme.defaultSeedColor;

          final baseScheme = CBTheme.buildColorScheme(seed);

          final scheme = settings.highContrast
              ? baseScheme.copyWith(
                  onSurface: CBColors.onSurface,
                  onSurfaceVariant: CBColors.onSurface.withValues(alpha: 0.85),
                  outline: CBColors.onSurface.withValues(alpha: 0.35),
                  outlineVariant: CBColors.onSurface.withValues(alpha: 0.2),
                )
              : baseScheme;

          return MaterialApp(
            title: 'Club Blackout Host',
            theme: CBTheme.buildTheme(scheme),
            home: const EffectsOverlay(
              child: HostIntroScreen(),
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

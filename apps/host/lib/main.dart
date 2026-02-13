import 'dart:io';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth/host_auth_screen.dart';
import 'auth/auth_provider.dart';
import 'widgets/effects_overlay.dart';
import 'screens/host_home_shell.dart';

import 'host_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await PersistenceService.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  String hostName = 'Club Host';
  if (!kIsWeb) {
    try {
      hostName = Platform.localHostname;
    } catch (_) {}
  }

  runApp(ProviderScope(
    overrides: [
      hostNameProvider.overrideWithValue(hostName),
    ],
    child: const HostApp(),
  ));
}

class HostApp extends ConsumerWidget {
  const HostApp({super.key});

  static final Future<Color> _seedFuture =
      CBTheme.sampleSeedFromGlobalBackground();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(hostSettingsProvider);
    final authState = ref.watch(authProvider);

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
            home: EffectsOverlay(
              child: authState.status == AuthStatus.authenticated
                  ? const HostHomeShell()
                  : const HostAuthScreen(),
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

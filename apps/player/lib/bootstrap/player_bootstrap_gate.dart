import 'dart:math' as math;

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/join_link_state.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_session_cache.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class PlayerBootstrapGate extends ConsumerStatefulWidget {
  const PlayerBootstrapGate({
    super.key,
    required this.child,
    this.skipPersistenceInit = false,
    this.skipFirestoreCacheConfig = false,
    this.skipAssetWarmup = false,
  });

  final Widget child;
  final bool skipPersistenceInit;
  final bool skipFirestoreCacheConfig;
  final bool skipAssetWarmup;

  @override
  ConsumerState<PlayerBootstrapGate> createState() =>
      _PlayerBootstrapGateState();
}

class _PlayerBootstrapGateState extends ConsumerState<PlayerBootstrapGate> {
  bool _ready = false;
  String _status = 'INITIALIZING CLUB SYSTEMS...';
  int _totalUnits = 1;
  int _completedUnits = 0;

  @override
  void initState() {
    super.initState();
    _runBootstrap();
  }

  Future<void> _runBootstrap() async {
    _initializeProgress();

    await _setStatus('PREPARING OFFLINE VAULT...');
    if (!widget.skipPersistenceInit) {
      await _initPersistence();
      _advanceProgress();
    }

    await _setStatus('CONFIGURING CLOUD CACHE...');
    if (!widget.skipFirestoreCacheConfig) {
      await _configureFirestoreCache();
      _advanceProgress();
    }

    await _setStatus('RESTORING LAST SESSION...');
    await _restoreCachedSession();
    _advanceProgress();

    if (!widget.skipAssetWarmup) {
      await _warmCriticalAssets();
    }

    if (!mounted) {
      return;
    }
    await _setStatus('BOOTSTRAP COMPLETE');
    setState(() => _ready = true);
  }

  void _initializeProgress() {
    var total = 1; // session restore always runs
    if (!widget.skipPersistenceInit) {
      total += 1;
    }
    if (!widget.skipFirestoreCacheConfig) {
      total += 1;
    }
    if (!widget.skipAssetWarmup) {
      total += _criticalAssetCount;
    }
    _totalUnits = math.max(1, total);
    _completedUnits = 0;
  }

  int get _criticalAssetCount => 1 + roleCatalog.length;

  void _advanceProgress([int units = 1]) {
    if (!mounted) {
      return;
    }
    setState(() {
      _completedUnits = math.min(_totalUnits, _completedUnits + units);
    });
  }

  double get _progress => (_completedUnits / _totalUnits).clamp(0.0, 1.0);

  String get _progressLabel =>
      '${(_progress * 100).toStringAsFixed(0)}% - $_completedUnits/$_totalUnits';

  Future<void> _setStatus(String status) async {
    if (!mounted) {
      return;
    }
    if (_status == status) {
      return;
    }
    setState(() => _status = status);
  }

  Future<void> _initPersistence() async {
    try {
      await Hive.initFlutter();
      await PersistenceService.init();
    } catch (_) {
      // Keep startup resilient; gameplay bridge does not depend on this path.
    }
  }

  Future<void> _configureFirestoreCache() async {
    if (kIsWeb) {
      return;
    }

    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {
      // Best effort only.
    }
  }

  Future<void> _restoreCachedSession() async {
    final cache = ref.read(playerSessionCacheRepositoryProvider);
    final entry = await cache.loadSession();
    if (entry == null) {
      return;
    }

    if (entry.mode == CachedSyncMode.cloud) {
      ref.read(cloudPlayerBridgeProvider.notifier).restoreFromCache(entry);
    } else {
      ref.read(playerBridgeProvider.notifier).restoreFromCache(entry);
    }

    final qp = <String, String>{
      'code': entry.joinCode,
      'mode': entry.mode == CachedSyncMode.cloud ? 'cloud' : 'local',
      'autoconnect': '1',
    };
    final host = entry.hostAddress?.trim();
    if (host != null && host.isNotEmpty) {
      qp['host'] = host;
    }
    ref.read(pendingJoinUrlProvider.notifier).setValue(
          Uri(path: '/join', queryParameters: qp).toString(),
        );
  }

  Future<void> _warmCriticalAssets() async {
    if (!mounted) {
      return;
    }

    final imageProviders = <ImageProvider>[
      const AssetImage(CBTheme.globalBackgroundAsset),
      for (final role in roleCatalog) AssetImage('assets/roles/${role.id}.png'),
    ];

    var index = 0;
    for (final provider in imageProviders) {
      index += 1;
      await _setStatus(
          'WARMING VISUAL ASSETS... ($index/${imageProviders.length})');
      if (!mounted) {
        return;
      }
      try {
        await precacheImage(provider, context);
      } catch (_) {
        // Continue warming remaining assets.
      }
      _advanceProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return widget.child;
    }

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: CBNeonBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: CBPanel(
                borderColor: scheme.primary.withValues(alpha: 0.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CBBreathingLoader(size: 54),
                    const SizedBox(height: 20),
                    Text(
                      'LOADING PLAYER CLIENT',
                      textAlign: TextAlign.center,
                      style: textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor:
                            scheme.onSurface.withValues(alpha: 0.15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(scheme.primary),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _progressLabel,
                      textAlign: TextAlign.center,
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.primary.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

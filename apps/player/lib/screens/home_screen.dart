import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/auth/auth_provider.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/join_link_state.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/custom_drawer.dart';

enum PlayerSyncMode {
  local,
  cloud,
}

const List<Duration> _resumeRetrySchedule = <Duration>[
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 12),
  Duration(seconds: 20),
  Duration(seconds: 30),
];

@visibleForTesting
Duration resumeRetryDelayForAttempt(int attempt) {
  if (attempt <= 0) {
    return _resumeRetrySchedule.first;
  }
  if (attempt >= _resumeRetrySchedule.length) {
    return _resumeRetrySchedule.last;
  }
  return _resumeRetrySchedule[attempt];
}

@visibleForTesting
bool shouldAcceptJoinUrlEvent({
  required String incomingUrl,
  required String? lastHandledUrl,
  required DateTime? lastHandledAt,
  required DateTime now,
  Duration debounceWindow = const Duration(seconds: 2),
}) {
  final trimmed = incomingUrl.trim();
  if (trimmed.isEmpty) {
    return false;
  }

  if (lastHandledUrl != null &&
      trimmed == lastHandledUrl.trim() &&
      lastHandledAt != null &&
      now.difference(lastHandledAt) <= debounceWindow) {
    return false;
  }

  return true;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const Duration _connectAttemptTimeout = Duration(seconds: 12);
  static const Duration _profileLookupTimeout = Duration(seconds: 5);
  static const int _maxResumeRetryAttempts = 8;

  StreamSubscription<Uri>? _linkSub;
  Timer? _resumeRetryTimer;
  bool _resumeAutoReconnectEnabled = false;
  int _resumeRetryAttempts = 0;
  static const Duration _joinUrlDebounceWindow = Duration(seconds: 2);
  String? _lastHandledJoinUrl;
  DateTime? _lastHandledJoinAt;

  // Connection State
  PlayerSyncMode _mode = PlayerSyncMode.cloud; // Default to cloud
  final TextEditingController _joinCodeController = TextEditingController();
  final TextEditingController _hostIpController =
      TextEditingController(text: 'ws://192.168.1.'); // Default local IP hint
  String? _connectionError;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    final appLinks = AppLinks();
    _linkSub = appLinks.uriLinkStream.listen((uri) {
      if (!mounted) return;
      final url = uri.toString();
      if (uri.queryParameters.containsKey('code')) {
        final now = DateTime.now();
        final shouldHandle = shouldAcceptJoinUrlEvent(
          incomingUrl: url,
          lastHandledUrl: _lastHandledJoinUrl,
          lastHandledAt: _lastHandledJoinAt,
          now: now,
          debounceWindow: _joinUrlDebounceWindow,
        );
        if (!shouldHandle) {
          return;
        }

        _lastHandledJoinUrl = url.trim();
        _lastHandledJoinAt = now;
        ref.read(pendingJoinUrlProvider.notifier).setValue(url);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final pending = ref.read(pendingJoinUrlProvider);
      if (pending != null) {
        _handlePendingJoinUrl(pending);
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _resumeRetryTimer?.cancel();
    _joinCodeController.dispose();
    _hostIpController.dispose();
    super.dispose();
  }

  bool _applyPendingJoinUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final code = uri.queryParameters['code'];
    final mode = uri.queryParameters['mode']; // Added for sync mode
    final host = uri.queryParameters['host']; // Added for local host
    final autoConnect = uri.queryParameters['autoconnect'] == '1';

    if (code != null) {
      _joinCodeController.text = _normalizeJoinCode(code);
    }

    // Set mode based on URL parameter
    if (mode == 'local') {
      setState(() {
        _mode = PlayerSyncMode.local;
        if (host != null) {
          _hostIpController.text = host;
        }
      });
    } else {
      setState(() => _mode = PlayerSyncMode.cloud);
    }

    return autoConnect;
  }

  String _normalizeJoinCode(String value) {
    final compact = value.toUpperCase().replaceAll('-', '').trim();
    if (compact.length != 10) return value.toUpperCase();
    return '${compact.substring(0, 4)}-${compact.substring(4)}';
  }

  void _handlePendingJoinUrl(String next) {
    final playerState = ref.read(playerBridgeProvider);
    final cloudState = ref.read(cloudPlayerBridgeProvider);
    final alreadyConnectedOutsideLobby =
        (playerState.isConnected && playerState.phase != 'lobby') ||
            (cloudState.isConnected && cloudState.phase != 'lobby');

    if (alreadyConnectedOutsideLobby) {
      _cancelResumeAutoReconnect(resetAttempts: true);
      ref.read(pendingJoinUrlProvider.notifier).setValue(null);
      return;
    }

    final shouldAutoConnect = _applyPendingJoinUrl(next);
    ref.read(pendingJoinUrlProvider.notifier).setValue(null);
    if (shouldAutoConnect && !_isConnecting) {
      _enableResumeAutoReconnect();
      Future<void>.microtask(() => _connect(fromResumeAutoReconnect: true));
    }
  }

  void _enableResumeAutoReconnect() {
    _resumeAutoReconnectEnabled = true;
    _resumeRetryAttempts = 0;
    _resumeRetryTimer?.cancel();
    _resumeRetryTimer = null;
  }

  void _cancelResumeAutoReconnect({required bool resetAttempts}) {
    _resumeAutoReconnectEnabled = false;
    _resumeRetryTimer?.cancel();
    _resumeRetryTimer = null;
    if (resetAttempts) {
      _resumeRetryAttempts = 0;
    }
  }

  void _scheduleResumeRetry() {
    if (!_resumeAutoReconnectEnabled || !mounted) {
      return;
    }
    if (_resumeRetryAttempts >= _maxResumeRetryAttempts) {
      _cancelResumeAutoReconnect(resetAttempts: false);
      return;
    }

    final delay = resumeRetryDelayForAttempt(_resumeRetryAttempts);
    _resumeRetryAttempts += 1;
    _resumeRetryTimer?.cancel();
    _resumeRetryTimer = Timer(delay, () {
      if (!mounted || !_resumeAutoReconnectEnabled || _isConnecting) {
        return;
      }
      unawaited(_connect(fromResumeAutoReconnect: true));
    });
  }

  Future<String> _resolveJoinIdentity() async {
    final authState = ref.read(authProvider);
    User? user;
    try {
      user = authState.user ?? FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = authState.user;
    }
    if (user == null) {
      return 'Player';
    }

    try {
      final profile = await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .get()
          .timeout(_profileLookupTimeout);
      final profileData = profile.data();
      final username = (profileData?['username'] as String?)?.trim();
      if (username != null && username.isNotEmpty) {
        return username;
      }
    } catch (_) {
      // Fall through to displayName/default.
    }

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    return 'Player';
  }

  Future<void> _performConnection() async {
    final playerName = await _resolveJoinIdentity();
    final code = _joinCodeController.text;

    if (_mode == PlayerSyncMode.local) {
      final host = _hostIpController.text.trim();
      if (host.isEmpty) {
        throw 'HOST IP/ADDRESS CANNOT BE EMPTY';
      }
      final normalizedHost = host.toLowerCase();
      if (!normalizedHost.startsWith('ws://') &&
          !normalizedHost.startsWith('wss://')) {
        throw 'LOCAL HOST MUST START WITH WS:// OR WSS:// (E.G. WS://192.168.1.100)';
      }
      await ref
          .read(cloudPlayerBridgeProvider.notifier)
          .disconnect()
          .timeout(_connectAttemptTimeout);
      await ref
          .read(playerBridgeProvider.notifier)
          .connect(host)
          .timeout(_connectAttemptTimeout);
      await ref
          .read(playerBridgeProvider.notifier)
          .joinGame(code, playerName)
          .timeout(_connectAttemptTimeout);
    } else {
      // Cloud mode
      await ref
          .read(playerBridgeProvider.notifier)
          .disconnect()
          .timeout(_connectAttemptTimeout);
      await ref
          .read(cloudPlayerBridgeProvider.notifier)
          .joinGame(code, playerName)
          .timeout(_connectAttemptTimeout);
    }
  }

  void _connectFromButton() {
    _enableResumeAutoReconnect();
    unawaited(_connect(fromResumeAutoReconnect: false));
  }

  Future<void> _connect({required bool fromResumeAutoReconnect}) async {
    var success = false;
    var retryableFailure = true;

    setState(() {
      _connectionError = null;
      _isConnecting = true;
    });

    // Clear focus
    FocusScope.of(context).unfocus();

    final code = _normalizeJoinCode(_joinCodeController.text);
    _joinCodeController.text = code;
    if (code.length != 11) {
      retryableFailure = false;
      setState(() {
        _connectionError = 'INVALID CODE FORMAT (XXXX-XXXXXX)';
      });
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
      return;
    }

    // Attempt connection
    try {
      await _performConnection();
      success = true;
    } on TimeoutException {
      setState(() {
        _connectionError =
            'CONNECTION TIMED OUT. PLEASE CHECK YOUR NETWORK AND TRY AGAIN.';
      });
    } catch (e) {
      setState(() {
        _connectionError = e.toString();
      });
    } finally {
      if (success) {
        _cancelResumeAutoReconnect(resetAttempts: true);
      } else if (fromResumeAutoReconnect && retryableFailure) {
        _scheduleResumeRetry();
      }
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Listen for pending join URL
    ref.listen<String?>(pendingJoinUrlProvider, (prev, next) {
      if (next != null) {
        _handlePendingJoinUrl(next);
      }
    });

    return CBPrismScaffold(
      title: 'JOIN THE CLUB',
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'CONNECT TO HOST',
                      textAlign: TextAlign.center,
                      style: textTheme.displayMedium!.copyWith(
                        color: scheme.primary,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w900,
                        shadows: CBColors.textGlow(scheme.primary),
                      ),
                    ),
                    const SizedBox(height: 48),
                    CBPanel(
                      borderColor: scheme.primary.withValues(alpha: 0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSyncModeSelector(context),
                          const SizedBox(height: 24),
                          CBTextField(
                            controller: _joinCodeController,
                            hintText: 'JOIN CODE (E.G. NEON-XXXXXX)',
                            textCapitalization: TextCapitalization.characters,
                          ),
                          if (_mode == PlayerSyncMode.local) ...[
                            const SizedBox(height: 16),
                            CBTextField(
                              controller: _hostIpController,
                              hintText:
                                  'HOST IP ADDRESS (E.G. WS://192.168.1.100)',
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'LOCAL MODE TIP: HOST + PLAYER MUST BE ON THE SAME NETWORK AND THE HOST APP MUST BE RUNNING. IF YOU ARE UNSURE, USE CLOUD MODE.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall!.copyWith(
                                color: scheme.primary.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          CBPrimaryButton(
                            label: _isConnecting
                                ? 'CONNECTING...'
                                : 'INITIATE UPLINK',
                            onPressed:
                                _isConnecting ? null : _connectFromButton,
                          ),
                          if (_connectionError != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _connectionError!,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall!
                                  .copyWith(color: scheme.error),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isConnecting)
            _LoadingDialogOverlay(
              title: 'CONNECTING TO HOST...',
              subtitle: 'Hang tight while we sync your invite.',
            ),
        ],
      ),
    );
  }

  Widget _buildSyncModeSelector(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: CBFilterChip(
              label: 'CLOUD',
              icon: Icons.cloud,
              selected: _mode == PlayerSyncMode.cloud,
              onSelected: () => setState(() => _mode = PlayerSyncMode.cloud),
              color: _mode == PlayerSyncMode.cloud ? scheme.primary : null,
              dense: false,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: CBFilterChip(
              label: 'LOCAL',
              icon: Icons.wifi,
              selected: _mode == PlayerSyncMode.local,
              onSelected: () => setState(() => _mode = PlayerSyncMode.local),
              color: _mode == PlayerSyncMode.local ? scheme.primary : null,
              dense: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingDialogOverlay extends StatelessWidget {
  const _LoadingDialogOverlay({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AbsorbPointer(
      absorbing: true,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: CBPanel(
            borderColor: scheme.primary.withValues(alpha: 0.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CBBreathingLoader(size: 54),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge!.copyWith(
                    color: scheme.primary,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

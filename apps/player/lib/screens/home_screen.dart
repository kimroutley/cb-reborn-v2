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

enum PlayerSyncMode { local, cloud }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  StreamSubscription<Uri>? _linkSub;

  // Connection State
  PlayerSyncMode _mode = PlayerSyncMode.cloud;
  final TextEditingController _joinCodeController = TextEditingController();
  final TextEditingController _hostIpController =
      TextEditingController(text: 'ws://192.168.1.');
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
        ref.read(pendingJoinUrlProvider.notifier).setValue(url);
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _joinCodeController.dispose();
    _hostIpController.dispose();
    super.dispose();
  }

  void _applyPendingJoinUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final code = uri.queryParameters['code'];
    final mode = uri.queryParameters['mode'];
    final host = uri.queryParameters['host'];

    if (code != null) {
      _joinCodeController.text = _normalizeJoinCode(code);
    }

    if (mode == 'local') {
      setState(() {
        _mode = PlayerSyncMode.local;
        if (host != null) {
          _hostIpController.text = Uri.decodeComponent(host);
        }
      });
    } else {
      setState(() => _mode = PlayerSyncMode.cloud);
    }
  }

  String _normalizeJoinCode(String value) {
    final compact = value.toUpperCase().replaceAll('-', '').trim();
    if (compact.length != 10) return value.toUpperCase();
    return '${compact.substring(0, 4)}-${compact.substring(4)}';
  }

  Future<String> _resolveJoinIdentity() async {
    final authState = ref.read(authProvider);
    final user = authState.user ?? FirebaseAuth.instance.currentUser;
    if (user == null) {
      return 'Player';
    }

    try {
      final profile = await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .get();
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

  Future<void> _connect() async {
    setState(() {
      _connectionError = null;
      _isConnecting = true;
    });

    // Clear focus
    FocusScope.of(context).unfocus();

    final code = _normalizeJoinCode(_joinCodeController.text);
    _joinCodeController.text = code;
    if (code.length != 11) {
      setState(() {
        _connectionError = 'INVALID CODE FORMAT (XXXX-XXXXXX)';
        _isConnecting = false;
      });
      return;
    }

    // Attempt connection
    try {
      final playerName = await _resolveJoinIdentity();

      if (_mode == PlayerSyncMode.local) {
        final host = _hostIpController.text.trim();
        if (host.isEmpty) {
          setState(() {
            _connectionError = 'HOST IP/ADDRESS CANNOT BE EMPTY';
          });
          return;
        }
        await ref.read(cloudPlayerBridgeProvider.notifier).disconnect();
        await ref.read(playerBridgeProvider.notifier).connect(host);
        await ref
            .read(playerBridgeProvider.notifier)
            .joinGame(code, playerName);
      } else {
        await ref.read(playerBridgeProvider.notifier).disconnect();
        await ref
            .read(cloudPlayerBridgeProvider.notifier)
            .joinGame(code, playerName);
      }
    } catch (e) {
      setState(() {
        _connectionError = e.toString();
      });
    } finally {
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
        _applyPendingJoinUrl(next);
        ref.read(pendingJoinUrlProvider.notifier).setValue(null);
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'JOIN A GAME',
          style: textTheme.titleLarge!,
        ),
        centerTitle: true,
      ),
      drawer: const CustomDrawer(),
      body: CBNeonBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'CLUB BLACKOUT',
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
                        ],
                        const SizedBox(height: 24),
                        if (_isConnecting)
                          const Center(child: CBBreathingLoader())
                        else
                          CBPrimaryButton(
                            label: 'CONNECT TO HOST',
                            onPressed: _connect,
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
      ),
    );
  }

  Widget _buildSyncModeSelector(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: CBFilterChip(
            label: 'CLOUD',
            icon: Icons.cloud,
            selected: _mode == PlayerSyncMode.cloud,
            onSelected: () => setState(() => _mode = PlayerSyncMode.cloud),
            color: _mode == PlayerSyncMode.cloud ? scheme.primary : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CBFilterChip(
            label: 'LOCAL',
            icon: Icons.wifi,
            selected: _mode == PlayerSyncMode.local,
            onSelected: () => setState(() => _mode = PlayerSyncMode.local),
            color: _mode == PlayerSyncMode.local ? scheme.primary : null,
          ),
        ),
      ],
    );
  }
}

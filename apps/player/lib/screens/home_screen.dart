import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/join_link_state.dart';
import 'package:cb_player/player_stats.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_drawer.dart';
import 'games_night_screen.dart';

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
  final TextEditingController _hostIpController = TextEditingController(text: 'ws://192.168.1.');
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

  Future<void> _connect() async {
    setState(() {
      _connectionError = null;
      _isConnecting = true;
    });

    // Clear focus
    FocusScope.of(context).unfocus();

    final code = _normalizeJoinCode(_joinCodeController.text);
    if (code.length != 11) {
      setState(() {
        _connectionError = 'INVALID CODE FORMAT (XXXX-XXXXXX)';
        _isConnecting = false;
      });
      return;
    }

    try {
      if (_mode == PlayerSyncMode.cloud) {
        await ref.read(playerBridgeProvider.notifier).disconnect();
        await ref.read(cloudPlayerBridgeProvider.notifier).joinWithCode(code);
      } else {
        await ref.read(cloudPlayerBridgeProvider.notifier).disconnect();
        final bridge = ref.read(playerBridgeProvider.notifier);
        final url = _hostIpController.text.trim();
        if (!url.startsWith('ws')) {
           setState(() {
            _connectionError = 'INVALID HOST URL';
            _isConnecting = false;
          });
          return;
        }
        await bridge.connect(url);
        bridge.joinWithCode(code);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionError = e.toString().replaceAll('Exception:', '').trim();
          _isConnecting = false;
        });
      }
    }

    // Note: If successful, GameRouter handles navigation.
    // If we are still here after a few seconds without navigation, it might have failed silently or is waiting.
    // We rely on bridge state updates for success.
    if (mounted) {
       Future.delayed(const Duration(seconds: 5), () {
         if (mounted && _isConnecting) {
           setState(() => _isConnecting = false);
         }
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen(playerBridgeProvider, (prev, next) {
      if (next.joinError != null || next.joinAccepted) {
        if (_isConnecting) setState(() => _isConnecting = false);
      }
    });

    ref.listen(cloudPlayerBridgeProvider, (prev, next) {
      if (next.joinError != null || next.joinAccepted) {
        if (_isConnecting) setState(() => _isConnecting = false);
      }
    });

    // Handle deep links
    final pendingJoinUrl = ref.watch(pendingJoinUrlProvider);
    if (pendingJoinUrl != null && pendingJoinUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyPendingJoinUrl(pendingJoinUrl);
        ref.read(pendingJoinUrlProvider.notifier).setValue(null);
      });
    }

    // Bridge error states
    final cloudState = ref.watch(cloudPlayerBridgeProvider);
    final localState = ref.watch(playerBridgeProvider);
    final bridgeError = _mode == PlayerSyncMode.cloud ? cloudState.joinError : localState.joinError;
    final displayError = _connectionError ?? bridgeError;

    // Stats for header
    final stats = ref.watch(playerStatsProvider);

    return CBPrismScaffold(
      title: 'CLUB LOBBY',
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: CBSpace.x6, vertical: CBSpace.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HEADER STATS ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniStat('GAMES', '${stats.gamesPlayed}', scheme.primary),
                const SizedBox(width: 24),
                _buildMiniStat('WINS', '${stats.gamesWon}', scheme.tertiary),
              ],
            ),
            const SizedBox(height: CBSpace.x8),

            // ── JOIN CARD ──
            CBGlassTile(
              title: "JOIN SESSION",
              subtitle: _mode == PlayerSyncMode.cloud ? "CLOUD SYNC" : "LOCAL NETWORK",
              accentColor: scheme.primary,
              isPrismatic: true,
              icon: Icon(_mode == PlayerSyncMode.cloud ? Icons.cloud : Icons.wifi, color: scheme.primary),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeTab(
                            label: 'CLOUD',
                            selected: _mode == PlayerSyncMode.cloud,
                            onTap: () => setState(() => _mode = PlayerSyncMode.cloud),
                          ),
                        ),
                        Expanded(
                          child: _ModeTab(
                            label: 'LOCAL',
                            selected: _mode == PlayerSyncMode.local,
                            onTap: () => setState(() => _mode = PlayerSyncMode.local),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Host IP (Local Only)
                  if (_mode == PlayerSyncMode.local) ...[
                    CBTextField(
                      controller: _hostIpController,
                      hintText: 'HOST IP (ws://...)',
                      decoration: const InputDecoration(
                        labelText: 'HOST ADDRESS',
                        prefixIcon: Icon(Icons.computer),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Join Code
                  CBTextField(
                    controller: _joinCodeController,
                    hintText: 'XXXX-XXXXXX',
                    textStyle: CBTypography.code.copyWith(
                      fontSize: 20,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'ACCESS CODE',
                      prefixIcon: Icon(Icons.key),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      _JoinCodeFormatter(),
                    ],
                    onSubmitted: (_) => _connect(),
                  ),

                  if (displayError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      displayError.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (_isConnecting)
                    const Center(child: CBBreathingSpinner(size: 32))
                  else
                    CBPrimaryButton(label: "CONNECT", onPressed: _connect),
                ],
              ),
            ),

            const SizedBox(height: CBSpace.x6),

            // ── HISTORY BUTTON ──
            CBGhostButton(
              label: 'VIEW HISTORY',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GamesNightScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: CBTypography.h2.copyWith(color: color)),
        Text(label, style: CBTypography.micro.copyWith(letterSpacing: 1.5)),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? scheme.primary.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: CBTypography.labelSmall.copyWith(
            color: selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.5),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _JoinCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.toUpperCase().replaceAll('-', '');
    if (text.length > 10) text = text.substring(0, 10);
    var newText = '';
    for (var i = 0; i < text.length; i++) {
      if (i == 4) newText += '-';
      newText += text[i];
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

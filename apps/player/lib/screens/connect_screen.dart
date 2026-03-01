import 'package:cb_theme/cb_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../active_bridge.dart';
import '../cloud_player_bridge.dart';
import '../player_bridge.dart';
import '../player_destinations.dart';
import '../player_navigation.dart';
import 'lobby_screen.dart';

enum PlayerSyncMode { cloud }

@immutable
class ParsedJoinUrl {
  const ParsedJoinUrl({
    required this.normalizedCode,
    required this.mode,
    required this.hostUrl,
  });

  final String normalizedCode;
  final PlayerSyncMode? mode;
  final String? hostUrl;
}

@visibleForTesting
String normalizeJoinCode(String value) {
  final compact = value.toUpperCase().replaceAll('-', '').trim();
  if (compact.length != 10) {
    return value.toUpperCase();
  }
  return '${compact.substring(0, 4)}-${compact.substring(4)}';
}

@visibleForTesting
ParsedJoinUrl? parseJoinUrlPayload(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || !trimmed.contains('://')) {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    return null;
  }

  final codeParam = uri.queryParameters['code'];
  if (codeParam == null || codeParam.trim().isEmpty) {
    return null;
  }

  final modeParam = uri.queryParameters['mode']?.toLowerCase();
  final hostParam = uri.queryParameters['host'];

  PlayerSyncMode? mode;
  if (modeParam == 'local') {
    mode = PlayerSyncMode.cloud;
  } else if (modeParam == 'cloud') {
    mode = PlayerSyncMode.cloud;
  }

  final decodedHost = hostParam != null && hostParam.trim().isNotEmpty
      ? Uri.decodeComponent(hostParam.trim())
      : null;

  return ParsedJoinUrl(
    normalizedCode: normalizeJoinCode(codeParam),
    mode: mode,
    hostUrl: decodedHost,
  );
}

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key, this.initialJoinUrl});

  final String? initialJoinUrl;

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final TextEditingController joinCodeController = TextEditingController();
  final TextEditingController joinUrlController = TextEditingController();
  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  String? localError;
  bool _isConnecting = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialJoinUrl;
    if (initial != null && initial.trim().isNotEmpty) {
      joinUrlController.text = initial.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ok = _tryApplyJoinUrl(initial);
        if (!ok) {
          setState(() => localError = 'INVALID JOIN URL');
          return;
        }
        _connect();
      });
    }
  }

  @override
  void dispose() {
    joinCodeController.dispose();
    joinUrlController.dispose();
    scannerController.dispose();
    super.dispose();
  }

  static const Duration _profileLookupTimeout = Duration(seconds: 4);

  Future<String> _resolvePlayerName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'Player';

      try {
        final profile = await FirebaseFirestore.instance
            .collection('user_profiles')
            .doc(user.uid)
            .get()
            .timeout(_profileLookupTimeout);
        final username = (profile.data()?['username'] as String?)?.trim();
        if (username != null && username.isNotEmpty) return username;
      } catch (_) {}

      final displayName = user.displayName?.trim();
      if (displayName != null && displayName.isNotEmpty) return displayName;
    } catch (_) {}
    return 'Player';
  }

  bool _tryApplyJoinUrl(String raw) {
    final parsed = parseJoinUrlPayload(raw);
    if (parsed == null) return false;

    setState(() {
      joinCodeController.text = parsed.normalizedCode;
    });
    return true;
  }

  Future<void> _connect() async {
    if (_isConnecting) return;
    setState(() {
      localError = null;
      _isConnecting = true;
    });

    final code = normalizeJoinCode(joinCodeController.text);

    if (code.length < 5) {
      HapticService.error();
      setState(() {
        localError = 'INVALID CODE FORMAT';
        _isConnecting = false;
      });
      return;
    }

    try {
      await ref.read(playerBridgeProvider.notifier).disconnect();
      final bridge = ref.read(cloudPlayerBridgeProvider.notifier);
      final playerName = await _resolvePlayerName();
      await bridge.joinGame(code, playerName);
      HapticService.medium();
    } catch (e) {
      HapticService.error();
      if (!mounted) return;
      final errorStr = e.toString();
      final raw = errorStr.startsWith('Exception: ')
          ? errorStr.replaceFirst('Exception: ', '')
          : errorStr;
      final displayError = raw.length > 60 ||
              raw.toLowerCase().contains('socket') ||
              raw.toLowerCase().contains('connection refused')
          ? 'COULD NOT ESTABLISH LINK. CHECK CODE AND TRY AGAIN.'
          : raw.toUpperCase();
      setState(() => localError = displayError);
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  void _onScan(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        if (_tryApplyJoinUrl(code)) {
          HapticService.selection();
          setState(() => _isScanning = false);
          _connect();
          return;
        }
        joinCodeController.text = code;
        HapticService.selection();
        setState(() => _isScanning = false);
        _connect();
        return;
      }
    }
  }

  void _navigateToLobby() {
    if (!mounted) return;
    ref
        .read(playerNavigationProvider.notifier)
        .setDestination(PlayerDestination.lobby);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen(cloudPlayerBridgeProvider, (prev, next) {
      if (prev != null && !prev.joinAccepted && next.joinAccepted) {
        _navigateToLobby();
      }
    });
    ref.listen(playerBridgeProvider, (prev, next) {
      if (prev != null && !prev.joinAccepted && next.joinAccepted) {
        _navigateToLobby();
      }
    });

    if (_isScanning) {
      return CBPrismScaffold(
        title: 'SCAN JOIN CODE',
        showAppBar: false,
        useSafeArea: false,
        body: Stack(
          children: [
            MobileScanner(
              controller: scannerController,
              onDetect: _onScan,
            ),
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: CBColors.boxGlow(scheme.primary, intensity: 0.3),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SCANNING...',
                          style: textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            shadows: CBColors.textGlow(scheme.primary),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close scanner',
                          icon: Icon(Icons.close_rounded, color: scheme.onSurface),
                          onPressed: () {
                            HapticService.light();
                            setState(() => _isScanning = false);
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    CBGlassTile(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'ALIGN THE CODE FROM THE HOST TERMINAL WITHIN THE FRAME.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final cloudState = ref.watch(cloudPlayerBridgeProvider);
    final bridgeState = ref.watch(activeBridgeProvider).state;
    final error = localError ?? cloudState.joinError;
    final hasJoined = bridgeState.joinAccepted;

    return CBPrismScaffold(
      title: 'ESTABLISH LINK',
      body: hasJoined
          ? _ConnectedWithChatView(
              bridgeState: bridgeState,
              scheme: scheme,
              textTheme: textTheme,
              onContinueToLobby: () {
                HapticService.medium();
                ref.read(playerNavigationProvider.notifier).setDestination(
                    PlayerDestination.lobby);
              },
            )
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CBFadeSlide(
                child: GestureDetector(
                  onTap: () {
                    HapticService.medium();
                    setState(() => _isScanning = true);
                  },
                  child: CBGlassTile(
                    isPrismatic: true,
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    borderColor: scheme.primary.withValues(alpha: 0.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded,
                            size: 64, color: scheme.primary),
                        const SizedBox(height: 20),
                        Text(
                          'SCAN TO JOIN',
                          style: textTheme.headlineSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            shadows: CBColors.textGlow(scheme.primary, intensity: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              CBFadeSlide(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR ENTER CODE',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.2))),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              CBFadeSlide(
                delay: const Duration(milliseconds: 200),
                child: CBTextField(
                  controller: joinCodeController,
                  hintText: 'NEON-XXXXXX',
                  textAlign: TextAlign.center,
                  monospace: true,
                  textStyle: textTheme.headlineSmall?.copyWith(
                    fontFamily: 'RobotoMono',
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
                    _JoinCodeFormatter(),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              CBFadeSlide(
                delay: const Duration(milliseconds: 300),
                child: CBPrimaryButton(
                  label: _isConnecting ? 'CONNECTING...' : 'ENTER THE CLUB',
                  onPressed: _isConnecting ? null : _connect,
                  icon: _isConnecting
                      ? Icons.hourglass_empty_rounded
                      : Icons.arrow_forward_rounded,
                ),
              ),

              if (error != null) ...[
                const SizedBox(height: 24),
                CBFadeSlide(
                  child: CBGlassTile(
                    borderColor: scheme.error.withValues(alpha: 0.5),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: scheme.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            error.toUpperCase(),
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.error,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 48),

              CBFadeSlide(
                delay: const Duration(milliseconds: 400),
                child: TextButton(
                  onPressed: () {
                    HapticService.selection();
                    ref
                        .read(playerNavigationProvider.notifier)
                        .setDestination(PlayerDestination.guides);
                  },
                  child: Column(
                    children: [
                      Text(
                        'JUST BROWSING?',
                        style: textTheme.labelLarge?.copyWith(
                          color: scheme.secondary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'READ THE CLUB BIBLE & ROLES',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectedWithChatView extends StatelessWidget {
  final PlayerGameState bridgeState;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback onContinueToLobby;

  const _ConnectedWithChatView({
    required this.bridgeState,
    required this.scheme,
    required this.textTheme,
    required this.onContinueToLobby,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            physics: const BouncingScrollPhysics(),
            children: [
              CBFadeSlide(
                child: CBGlassTile(
                  isPrismatic: true,
                  borderColor: scheme.tertiary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.tertiary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_circle_rounded, color: scheme.tertiary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LINK ESTABLISHED',
                              style: textTheme.labelLarge?.copyWith(
                                color: scheme.tertiary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PROCEED TO THE LOUNGE TO SECURE YOUR IDENTITY.',
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const CBFeedSeparator(label: 'GROUP CHAT'),
              const SizedBox(height: 12),
              ...buildBulletinList(
                  bridgeState, bridgeState.myPlayerSnapshot, scheme, includeSeparator: false),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: CBPrimaryButton(
              label: 'CONTINUE TO LOUNGE',
              icon: Icons.arrow_forward_rounded,
              onPressed: onContinueToLobby,
            ),
          ),
        ),
      ],
    );
  }
}

class _JoinCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
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

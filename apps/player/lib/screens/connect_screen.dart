import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cloud_player_bridge.dart';
import '../player_bridge.dart';
import 'claim_screen.dart';

/// Connection mode for the player app.
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
    // Legacy links with mode=local are treated as cloud-only.
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

@visibleForTesting
bool shouldNavigateToClaim({
  required bool isNavigating,
  required bool mounted,
}) {
  return mounted && !isNavigating;
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
  String? localError;
  bool _navigatingToClaim = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialJoinUrl;
    if (initial != null && initial.trim().isNotEmpty) {
      joinUrlController.text = initial.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
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
    super.dispose();
  }

  String _normalizeJoinCode(String value) {
    return normalizeJoinCode(value);
  }

  bool _tryApplyJoinUrl(String raw) {
    final parsed = parseJoinUrlPayload(raw);
    if (parsed == null) {
      return false;
    }

    setState(() {
      joinCodeController.text = parsed.normalizedCode;
    });

    return true;
  }

  Future<void> _connect() async {
    if (_isConnecting) {
      return;
    }
    setState(() {
      localError = null;
      _isConnecting = true;
    });

    if (joinUrlController.text.trim().isNotEmpty) {
      final ok = _tryApplyJoinUrl(joinUrlController.text);
      if (!ok) {
        HapticService.error();
        setState(() {
          localError = 'INVALID JOIN URL';
          _isConnecting = false;
        });
        return;
      }
    }

    final code = _normalizeJoinCode(joinCodeController.text);

    if (code.length != 11) {
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
      await bridge.joinWithCode(code);
      HapticService.medium();
    } catch (e) {
      HapticService.error();
      if (!mounted) return;
      setState(() => localError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    // Listen for successful join
    ref.listen(cloudPlayerBridgeProvider, (prev, next) {
      if (prev != null && !prev.joinAccepted && next.joinAccepted) {
        _navigateToClaim();
      }
    });
    ref.listen(playerBridgeProvider, (prev, next) {
      if (prev != null && !prev.joinAccepted && next.joinAccepted) {
        _navigateToClaim();
      }
    });

    // Get current error state
    final cloudState = ref.watch(cloudPlayerBridgeProvider);
    final error = localError ?? cloudState.joinError;
    final hasParsedUrl = joinUrlController.text.trim().isNotEmpty;
    final toneColor = _isConnecting
        ? scheme.primary
        : (error == null ? scheme.tertiary : scheme.error);
    final toneIcon = _isConnecting
        ? Icons.cloud_sync_rounded
        : (error == null
              ? Icons.cloud_done_rounded
              : Icons.error_outline_rounded);
    final toneTitle = _isConnecting
        ? 'UPLINK IN PROGRESS'
        : (error == null ? 'UPLINK READY' : 'UPLINK ISSUE DETECTED');
    final readyDetail = hasParsedUrl
        ? 'Join URL detected. Code can be prefilled from parser.'
        : 'Enter a join code or paste a join URL to continue.';
    final toneDetail = _isConnecting
        ? 'Connecting to host session. Keep this terminal active.'
        : (error ?? readyDetail);

    final accent = scheme.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ESTABLISH LINK',
              style: textTheme.headlineMedium!.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.close,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: CBSpace.x4),
        CBGlassTile(
          borderColor: toneColor.withValues(alpha: 0.35),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(toneIcon, size: 18, color: toneColor),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Column(
                    key: ValueKey('$toneTitle|$toneDetail'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        toneTitle,
                        style: textTheme.labelMedium?.copyWith(
                          color: toneColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        toneDetail,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.76),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CBSpace.x4),
        // Local-only: Host IP
        CBBadge(text: 'JOIN URL (OPTIONAL)', color: accent),
        const SizedBox(height: CBSpace.x2),
        CBTextField(
          controller: joinUrlController,
          hintText: 'https://.../join?mode=cloud&code=NEON-ABCDEF',
          textStyle: textTheme.bodySmall,
        ),
        const SizedBox(height: CBSpace.x2),
        Align(
          alignment: Alignment.centerRight,
          child: CBTextButton(
            label: 'PARSE URL',
            onPressed: _isConnecting
                ? null
                : () {
                    final ok = _tryApplyJoinUrl(joinUrlController.text);
                    if (!ok) {
                      HapticService.error();
                      setState(() => localError = 'INVALID JOIN URL');
                    } else {
                      HapticService.selection();
                      setState(() => localError = null);
                    }
                  },
            color: accent,
          ),
        ),
        const SizedBox(height: CBSpace.x4),

        CBBadge(text: 'JOIN CODE', color: accent),
        const SizedBox(height: CBSpace.x2),
        CBTextField(
          controller: joinCodeController,
          hintText: 'NEON-ABCDEF',
          textStyle: textTheme.bodyMedium?.copyWith(fontFamily: 'RobotoMono'),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            _JoinCodeFormatter(),
          ],
          errorText: error,
        ),

        if (error != null) ...[
          const SizedBox(height: CBSpace.x4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: CBStatusOverlay(
              key: ValueKey(error),
              icon: Icons.error_outline,
              label: 'CONNECTION FAILED',
              color: scheme.error,
              detail: error,
            ),
          ),
        ],

        const SizedBox(height: CBSpace.x6),
        CBPrimaryButton(
          label: _isConnecting ? 'CONNECTING...' : 'INITIATE UPLINK',
          icon: Icons.login_rounded,
          onPressed: _isConnecting ? null : _connect,
        ),
      ],
    );
  }

  void _navigateToClaim() {
    if (!shouldNavigateToClaim(
      isNavigating: _navigatingToClaim,
      mounted: mounted,
    )) {
      return;
    }
    _navigatingToClaim = true;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClaimScreen()),
    ).then((_) {
      if (mounted) {
        _navigatingToClaim = false;
      }
    });
  }
}

class _JoinCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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

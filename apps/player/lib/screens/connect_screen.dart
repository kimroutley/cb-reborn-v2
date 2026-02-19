import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cloud_player_bridge.dart';
import '../player_bridge.dart';
import 'claim_screen.dart';

/// Connection mode for the player app.
enum PlayerSyncMode { local, cloud }

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
    mode = PlayerSyncMode.local;
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
  PlayerSyncMode _mode = PlayerSyncMode.cloud;
  final TextEditingController hostIpController =
      TextEditingController(text: 'ws://192.168.1.');
  final TextEditingController joinCodeController = TextEditingController();
  final TextEditingController joinUrlController = TextEditingController();
  String? localError;
  bool _navigatingToClaim = false;

  Future<void> _switchMode(PlayerSyncMode nextMode) async {
    if (_mode == nextMode) {
      return;
    }

    setState(() {
      _mode = nextMode;
      localError = null;
    });

    if (nextMode == PlayerSyncMode.cloud) {
      await ref.read(playerBridgeProvider.notifier).disconnect();
      return;
    }

    await ref.read(cloudPlayerBridgeProvider.notifier).disconnect();
  }

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
    hostIpController.dispose();
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

      if (parsed.mode == PlayerSyncMode.local) {
        _mode = PlayerSyncMode.local;
        if (parsed.hostUrl != null) {
          hostIpController.text = parsed.hostUrl!;
        }
      } else if (parsed.mode == PlayerSyncMode.cloud) {
        _mode = PlayerSyncMode.cloud;
      }
    });

    return true;
  }

  void _connect() async {
    setState(() => localError = null);

    if (joinUrlController.text.trim().isNotEmpty) {
      final ok = _tryApplyJoinUrl(joinUrlController.text);
      if (!ok) {
        setState(() => localError = 'INVALID JOIN URL');
        return;
      }
    }

    final isCloud = _mode == PlayerSyncMode.cloud;
    final code = _normalizeJoinCode(joinCodeController.text);

    if (code.length != 11) {
      setState(() => localError = 'INVALID CODE FORMAT');
      return;
    }

    try {
      if (isCloud) {
        await ref.read(playerBridgeProvider.notifier).disconnect();
        final bridge = ref.read(cloudPlayerBridgeProvider.notifier);
        await bridge.joinWithCode(code);
      } else {
        await ref.read(cloudPlayerBridgeProvider.notifier).disconnect();
        final bridge = ref.read(playerBridgeProvider.notifier);
        final url = hostIpController.text.trim();
        if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
          setState(() =>
              localError = 'LOCAL HOST URL MUST START WITH ws:// OR wss://');
          return;
        }
        await bridge.connect(url);
        bridge.joinWithCode(code);
      }
    } catch (e) {
      setState(() => localError = e.toString());
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
    final localState = ref.watch(playerBridgeProvider);
    final error = localError ??
        (_mode == PlayerSyncMode.cloud
            ? cloudState.joinError
            : localState.joinError);

    final isCloud = _mode == PlayerSyncMode.cloud;
    // Note: isConnecting logic needs a proper state in the bridges.
    // For now, assume if error is null and not accepted, it's connecting.

    final accent = isCloud ? scheme.secondary : scheme.primary;

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
              icon: Icon(Icons.close,
                  color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
        const SizedBox(height: CBSpace.x4),
        // Mode Toggle
        CBPanel(
          padding: const EdgeInsets.all(CBSpace.x3),
          margin: const EdgeInsets.only(bottom: CBSpace.x4),
          borderColor: accent.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CBBadge(
                text: 'CONNECTION',
                color: accent,
              ),
              const SizedBox(height: CBSpace.x3),
              Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      icon: Icons.wifi,
                      label: 'LOCAL',
                      desc: 'Same Wi-Fi',
                      color: scheme.primary,
                      isSelected: !isCloud,
                      onTap: () => _switchMode(PlayerSyncMode.local),
                    ),
                  ),
                  const SizedBox(width: CBSpace.x2),
                  Expanded(
                    child: _ModeButton(
                      icon: Icons.cloud,
                      label: 'CLOUD',
                      desc: 'Internet',
                      color: scheme.secondary,
                      isSelected: isCloud,
                      onTap: () => _switchMode(PlayerSyncMode.cloud),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Local-only: Host IP
        CBBadge(
          text: 'JOIN URL (OPTIONAL)',
          color: accent,
        ),
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
            onPressed: () {
              final ok = _tryApplyJoinUrl(joinUrlController.text);
              if (!ok) {
                setState(() => localError = 'INVALID JOIN URL');
              } else {
                setState(() => localError = null);
              }
            },
            color: accent,
          ),
        ),
        const SizedBox(height: CBSpace.x4),

        if (!isCloud) ...[
          CBBadge(
            text: 'HOST ADDRESS',
            color: scheme.primary,
          ),
          const SizedBox(height: CBSpace.x2),
          CBTextField(
            controller: hostIpController,
            hintText: 'ws://192.168.1.X:8080',
            textStyle: textTheme.bodyLarge!,
          ),
          const SizedBox(height: CBSpace.x4),
        ],
        CBBadge(
          text: 'JOIN CODE',
          color: accent,
        ),
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
          CBStatusOverlay(
            icon: Icons.error_outline,
            label: 'CONNECTION FAILED',
            color: scheme.error,
            detail: error,
          ),
        ],

        const SizedBox(height: CBSpace.x6),
        CBPrimaryButton(
          label: 'INITIATE UPLINK',
          icon: Icons.login_rounded,
          onPressed: _connect,
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
      MaterialPageRoute(
        builder: (context) => const ClaimScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _navigatingToClaim = false;
      }
    });
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final activeColor =
        isSelected ? color : scheme.onSurface.withValues(alpha: 0.3);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(CBRadius.sm),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Ink(
          padding: const EdgeInsets.all(CBSpace.x3),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : CBColors.transparent,
            borderRadius: BorderRadius.circular(CBRadius.sm),
            border: Border.all(
              color: activeColor.withValues(alpha: isSelected ? 1.0 : 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: activeColor),
              const SizedBox(height: CBSpace.x2),
              Text(
                label,
                style: textTheme.labelMedium!.copyWith(color: activeColor),
              ),
              Text(
                desc,
                style: textTheme.labelSmall?.copyWith(
                  color: activeColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
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

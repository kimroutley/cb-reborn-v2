import 'dart:ui';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'full_role_reveal_content.dart';

class PrivacyRevealButton extends StatefulWidget {
  final PlayerSnapshot player;
  final double bottomOffset;
  final double rightOffset;

  const PrivacyRevealButton({
    super.key,
    required this.player,
    this.bottomOffset = CBSpace.x6,
    this.rightOffset = CBSpace.x6,
  });

  @override
  State<PrivacyRevealButton> createState() => _PrivacyRevealButtonState();
}

class _PrivacyRevealButtonState extends State<PrivacyRevealButton> {
  OverlayEntry? _overlayEntry;

  void _showRevealOverlay() {
    if (_overlayEntry != null) return;
    HapticService.light();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final roleColor = Color(int.parse(widget.player.roleColorHex.replaceAll('#', '0xff')));
        return Positioned.fill(
          child: Material(
            color: CBColors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: CBTheme.buildColorScheme(roleColor).scrim.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: CBInsets.screen,
                    child: SingleChildScrollView(
                      child: FullRoleRevealContent(
                        player: widget.player,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideRevealOverlay() {
    if (_overlayEntry != null) {
      HapticService.light();
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.player.roleId == 'unassigned') {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final roleColor = Color(int.parse(widget.player.roleColorHex.replaceAll('#', '0xff')));

    return Positioned(
      bottom: widget.bottomOffset,
      right: widget.rightOffset,
      child: GestureDetector(
        onTapDown: (_) => _showRevealOverlay(),
        onTapUp: (_) => _hideRevealOverlay(),
        onTapCancel: _hideRevealOverlay,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: roleColor.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
            border: Border.all(
              color: roleColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(CBSpace.x3),
          child: Icon(
            Icons.fingerprint_rounded,
            color: roleColor,
            size: 28,
            shadows: CBColors.iconGlow(roleColor, intensity: 0.5),
          ),
        ),
      ),
    );
  }
}

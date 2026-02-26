import 'dart:ui';

import 'package:cb_player/player_bridge.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A "Hold to Reveal" role identity header for secure, dramatic role checking.
class BiometricIdentityHeader extends StatefulWidget {
  final PlayerSnapshot player;
  final Color roleColor;
  final bool isMyTurn;

  const BiometricIdentityHeader({
    super.key,
    required this.player,
    required this.roleColor,
    required this.isMyTurn,
  });

  @override
  State<BiometricIdentityHeader> createState() =>
      _BiometricIdentityHeaderState();
}

class _BiometricIdentityHeaderState extends State<BiometricIdentityHeader>
    with SingleTickerProviderStateMixin {
  bool _isRevealed = false;
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!_isRevealed) {
      _revealController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (_revealController.value < 1.0) {
      _revealController.reverse();
    } else {
      setState(() => _isRevealed = true);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.7),
              border: Border(
                bottom: BorderSide(
                  color: widget.roleColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.roleColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CBRoleAvatar(
                      assetPath: _isRevealed
                          ? 'assets/roles/${widget.player.roleId}.png'
                          : null,
                      color: widget.roleColor,
                      size: 54,
                      pulsing: widget.isMyTurn,
                      breathing: _isRevealed,
                    ),
                    if (!_isRevealed)
                      AnimatedBuilder(
                        animation: _revealAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: _revealAnimation.value,
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.roleColor,
                              ),
                              backgroundColor: widget.roleColor.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.player.name.toUpperCase(),
                        style: textTheme.labelLarge!.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          shadows: _isRevealed
                              ? CBColors.textGlow(
                                  widget.roleColor,
                                  intensity: 0.4,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isRevealed)
                        Text(
                          widget.player.roleName.toUpperCase(),
                          style: textTheme.labelSmall!.copyWith(
                            color: widget.roleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        )
                      else
                        Text(
                          "SCANNING BIOMETRICS...",
                          style: textTheme.labelSmall!.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.4),
                            fontSize: 8,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (widget.isMyTurn)
                  CBBadge(text: "YOUR TURN", color: widget.roleColor)
                else
                  CBBadge(text: "ACTIVE", color: scheme.tertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

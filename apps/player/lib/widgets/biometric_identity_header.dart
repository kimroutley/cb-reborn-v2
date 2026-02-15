import 'package:cb_player/player_bridge.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

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
      HapticService.selection();
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (_revealController.value < 1.0) {
      _revealController.reverse();
    } else {
      setState(() => _isRevealed = true);
      HapticService.heavy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow.withValues(alpha: 0.85),
          border: Border(
            bottom: BorderSide(
              color: widget.roleColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
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
                  size: 48,
                  pulsing: widget.isMyTurn,
                ),
                if (!_isRevealed)
                  AnimatedBuilder(
                    animation: _revealAnimation,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: _revealAnimation.value,
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(widget.roleColor),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.player.name.toUpperCase(),
                    style: textTheme.labelSmall!.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
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
                        letterSpacing: 2,
                      ),
                    )
                  else
                    Text(
                      "HOLD TO SCAN BIOMETRICS",
                      style: textTheme.labelSmall!.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.3),
                        fontSize: 8,
                        letterSpacing: 1.0,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.isMyTurn)
              CBBadge(text: "YOUR TURN", color: widget.roleColor)
            else
              CBBadge(
                  text: "ALIVE", color: Theme.of(context).colorScheme.tertiary),
          ],
        ),
      ),
    );
  }
}

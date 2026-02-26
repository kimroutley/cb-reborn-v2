import 'dart:ui';

import 'package:cb_models/cb_models.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/strategy/player_strategy_engine.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A "Hold to Reveal" role identity header for secure, dramatic role checking.
/// When revealed, shows a TACTICAL BRIEF and a button to access the full guide.
class BiometricIdentityHeader extends StatefulWidget {
  final PlayerSnapshot player;
  final PlayerGameState gameState;
  final Color roleColor;
  final bool isMyTurn;
  final RoleStrategy? strategy;
  final VoidCallback? onBlackbookTap;

  const BiometricIdentityHeader({
    super.key,
    required this.player,
    required this.gameState,
    required this.roleColor,
    required this.isMyTurn,
    this.strategy,
    this.onBlackbookTap,
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
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
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
                                      widget.roleColor),
                                  backgroundColor:
                                      widget.roleColor.withValues(alpha: 0.1),
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
                                  ? CBColors.textGlow(widget.roleColor,
                                      intensity: 0.4)
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
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isMyTurn)
                          CBBadge(text: "YOUR TURN", color: widget.roleColor)
                        else
                          CBBadge(text: "ACTIVE", color: scheme.tertiary),
                      ],
                    ),
                  ],
                ),
                if (_isRevealed) ...[
                  const SizedBox(height: 16),
                  Divider(
                      height: 1, color: widget.roleColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  _buildTacticalBrief(theme, scheme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTacticalBrief(ThemeData theme, ColorScheme scheme) {
    final strategy = widget.strategy;
    // Get high-priority situation tips
    final tips = PlayerStrategyEngine.evaluateSituation(
      player: widget.player,
      gameState: widget.gameState,
    ).where((t) => t.priority <= 1).toList();

    final criticalTip = tips.isNotEmpty ? tips.first : null;
    final topDo = strategy?.dos.isNotEmpty == true ? strategy!.dos.first : null;
    final topDont =
        strategy?.donts.isNotEmpty == true ? strategy!.donts.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TACTICAL BRIEF',
              style: theme.textTheme.labelSmall!.copyWith(
                color: widget.roleColor.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            if (widget.onBlackbookTap != null)
              GestureDetector(
                onTap: widget.onBlackbookTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'FULL BLACKBOOK',
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: widget.roleColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 10,
                      color: widget.roleColor,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (criticalTip != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildBullet(
              criticalTip.text,
              scheme.error, // Critical tips are usually red/orange
              Icons.warning_amber_rounded,
              theme,
              scheme,
            ),
          ),
        if (topDo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildBullet(
              topDo,
              CBColors.neonGreen,
              Icons.check_circle_outline_rounded,
              theme,
              scheme,
            ),
          ),
        if (topDont != null)
          _buildBullet(
            topDont,
            scheme.error.withValues(alpha: 0.8),
            Icons.cancel_outlined,
            theme,
            scheme,
          ),
        if (criticalTip == null && topDo == null && topDont == null)
          Text(
            "No tactical data available.",
            style: theme.textTheme.bodySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildBullet(
    String text,
    Color color,
    IconData icon,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 8),
          child: Icon(icon, size: 12, color: color),
        ),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              fontSize: 11,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

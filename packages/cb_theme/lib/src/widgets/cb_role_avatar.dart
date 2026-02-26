import 'package:flutter/material.dart';

/// Unified role avatar with glowing border for the chat feed.
class CBRoleAvatar extends StatefulWidget {
  final String? assetPath;
  final IconData? icon;
  final Color? color;
  final double size;
  final bool pulsing;
  final bool breathing; // Enables role-color shimmer cycle

  const CBRoleAvatar({
    super.key,
    this.assetPath,
    this.icon,
    this.color,
    this.size = 36,
    this.pulsing = false,
    this.breathing = false,
  });

  @override
  State<CBRoleAvatar> createState() => _CBRoleAvatarState();
}

class _CBRoleAvatarState extends State<CBRoleAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.pulsing || widget.breathing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CBRoleAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldAnimate = widget.pulsing || widget.breathing;
    final wasAnimating = oldWidget.pulsing || oldWidget.breathing;

    if (shouldAnimate && !wasAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldAnimate && wasAnimating) {
      _controller.stop();
      _controller.value = 0.6;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.color ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Color effectiveColor = baseColor;
        double intensity = widget.pulsing ? _animation.value : 0.6;

        // Apply breathing gradient if enabled
        if (widget.breathing) {
          effectiveColor = Color.lerp(
              baseColor, theme.colorScheme.secondary, _controller.value)!;
          intensity = 0.5 + (_controller.value * 0.5); // 0.5 -> 1.0 glow
        }

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: effectiveColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withValues(alpha: intensity * 0.5),
                blurRadius: widget.size * 0.2,
              ),
            ],
          ),
          child: Center(
            child: widget.assetPath != null
                ? Image.asset(
                    widget.assetPath!,
                    width: widget.size * 0.6,
                    height: widget.size * 0.6,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      widget.icon ?? Icons.person,
                      color: effectiveColor,
                      size: widget.size * 0.5,
                    ),
                  )
                : Icon(
                    widget.icon ?? Icons.smart_toy,
                    color: effectiveColor,
                    size: widget.size * 0.5,
                  ),
          ),
        );
      },
    );
  }
}

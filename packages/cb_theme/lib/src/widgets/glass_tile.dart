import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../cb_theme.dart';

/// A high-impact, glassmorphic M3 tile for interactive game actions.
/// Uses the "Legacy Squircle" style with heavy glow and 10.0 sigma blur.
class CBGlassTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final Widget content;

  /// The accent color for the border and glow.
  /// If null, uses [Theme.of(context).colorScheme.primary].
  final Color? accentColor;
  final Color? shimmerBaseColor;

  final VoidCallback? onTap;
  final bool isResolved;
  final bool isCritical;
  final bool isPrismatic;

  const CBGlassTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.content,
    this.accentColor,
    this.shimmerBaseColor,
    this.onTap,
    this.isResolved = false,
    this.isCritical = false,
    this.isPrismatic = true,
  });

  @override
  State<CBGlassTile> createState() => _CBGlassTileState();
}

class _CBGlassTileState extends State<CBGlassTile>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: CBMotion.standardCurve),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _updateAnimations();
  }

  @override
  void didUpdateWidget(covariant CBGlassTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimations();
  }

  void _updateShimmerSpeed() {
    if (!widget.isPrismatic) return;

    final newDuration =
        _isHovering ? const Duration(seconds: 4) : const Duration(seconds: 8);

    if (_shimmerController.duration != newDuration) {
      _shimmerController.duration = newDuration;
      _shimmerController.repeat();
    }
  }

  void _updateAnimations() {
    if (widget.isCritical &&
        !widget.isResolved &&
        !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.isResolved || !widget.isCritical) {
      _pulseController.stop();
      _pulseController.value = 0;
    }

    if (widget.isPrismatic && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    } else if (!widget.isPrismatic) {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Resolve effective color from theme if not provided
    final baseColor = widget.accentColor ?? colorScheme.primary;
    final effectiveColor = widget.isCritical ? colorScheme.error : baseColor;
    final shimmerBase = widget.shimmerBaseColor ?? baseColor;
    final shimmerStops = CBColors.roleShimmerStops(shimmerBase);

    final glowIntensity =
        widget.isResolved ? 0.2 : (widget.isCritical ? 1.0 : 0.6);

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
          _updateShimmerSpeed();
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
          _updateShimmerSpeed();
        });
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _shimmerController]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isCritical ? _scaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: CBMotion.transition,
              margin: const EdgeInsets.symmetric(
                  vertical: CBSpace.x3, horizontal: CBSpace.x4),
              child: Opacity(
                opacity: widget.isResolved ? 0.5 : 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      CBRadius.dialog), // High M3 Squircle
                  child: Stack(
                    children: [
                      // LAYER 1: Base Surface & Blur
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: widget.isPrismatic
                              ? CBColors.deepSwamp.withValues(alpha: 0.56)
                              : CBColors.voidBlack.withValues(alpha: 0.52),
                        ),
                      ),

                      // LAYER 2: The animated oil-slick shimmer overlay
                      if (widget.isPrismatic)
                        Positioned(
                          top: -40,
                          left: -40,
                          right: -40,
                          bottom: -40,
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, _) {
                              final value = _shimmerController.value;
                              final rotation = value * 2 * math.pi;
                              final waveX = math.sin(rotation);
                              final waveY = math.cos(rotation * 0.9);

                              return Stack(
                                children: [
                                  Transform.rotate(
                                    angle: rotation,
                                    child: Opacity(
                                      opacity: _isHovering ? 0.34 : 0.24,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: SweepGradient(
                                            center: Alignment(
                                                0.16 * waveX, -0.18 * waveY),
                                            transform:
                                                GradientRotation(rotation),
                                            colors: [
                                              CBColors.transparent,
                                              shimmerStops[0]
                                                  .withValues(alpha: 0.18),
                                              shimmerStops[1]
                                                  .withValues(alpha: 0.30),
                                              CBColors.magentaShift
                                                  .withValues(alpha: 0.26),
                                              CBColors.cyanRefract
                                                  .withValues(alpha: 0.30),
                                              shimmerStops[3]
                                                  .withValues(alpha: 0.18),
                                              CBColors.transparent,
                                            ],
                                            stops: const [
                                              0.0,
                                              0.16,
                                              0.34,
                                              0.52,
                                              0.68,
                                              0.84,
                                              1.0
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: Offset(22 * waveX, -14 * waveY),
                                    child: Opacity(
                                      opacity: _isHovering ? 0.28 : 0.18,
                                      child: ImageFiltered(
                                        imageFilter: ImageFilter.blur(
                                            sigmaX: 18, sigmaY: 18),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment(
                                                  -1 + (0.55 * waveX), -1),
                                              end: Alignment(
                                                  1, 1 - (0.55 * waveY)),
                                              colors: [
                                                CBColors.transparent,
                                                shimmerStops[1]
                                                    .withValues(alpha: 0.14),
                                                CBColors.magentaShift
                                                    .withValues(alpha: 0.2),
                                                CBColors.cyanRefract
                                                    .withValues(alpha: 0.22),
                                                shimmerStops[2]
                                                    .withValues(alpha: 0.14),
                                                CBColors.transparent,
                                              ],
                                              stops: const [
                                                0.0,
                                                0.2,
                                                0.42,
                                                0.6,
                                                0.8,
                                                1.0
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                      // LAYER 2.5: Thin top glass sheen to avoid "solid fill" look
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  theme.colorScheme.onSurface
                                      .withValues(alpha: 0.065),
                                  theme.colorScheme.onSurface
                                      .withValues(alpha: 0.018),
                                  CBColors.transparent,
                                ],
                                stops: const [0.0, 0.25, 0.6],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // LAYER 3: Content Structure & Borders
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(CBRadius.dialog),
                          border: Border.all(
                            color: widget.isPrismatic
                                ? shimmerBase.withValues(alpha: 0.62)
                                : effectiveColor.withValues(
                                    alpha: widget.isCritical ? 0.8 : 0.4),
                            width: widget.isCritical ? 2.2 : 1.35,
                          ),
                          boxShadow: widget.isPrismatic
                              ? [
                                  BoxShadow(
                                    color: shimmerBase.withValues(alpha: 0.22),
                                    blurRadius: 30,
                                    spreadRadius: -5,
                                  ),
                                  ...CBColors.boxGlow(effectiveColor,
                                      intensity: glowIntensity)
                                ]
                              : CBColors.boxGlow(effectiveColor,
                                  intensity: glowIntensity),
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            onTap: (widget.isResolved || widget.onTap == null)
                                ? null
                                : () {
                                    HapticService.selection();
                                    widget.onTap!.call();
                                  },
                            borderRadius:
                                BorderRadius.circular(CBRadius.dialog),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header Section
                                Container(
                                  padding: const EdgeInsets.all(CBSpace.x5),
                                  decoration: BoxDecoration(
                                    color:
                                        effectiveColor.withValues(alpha: 0.07),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: effectiveColor.withValues(
                                            alpha: 0.18),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      if (widget.icon != null) ...[
                                        IconTheme(
                                          data: IconThemeData(
                                              color: effectiveColor, size: 24),
                                          child: widget.icon!,
                                        ),
                                        const SizedBox(width: CBSpace.x4),
                                      ],
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.title.toUpperCase(),
                                              style: theme.textTheme.labelLarge!
                                                  .copyWith(
                                                color: effectiveColor,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 2.0,
                                                shadows: CBColors.textGlow(
                                                    effectiveColor,
                                                    intensity: 0.3),
                                              ),
                                            ),
                                            if (widget.subtitle != null) ...[
                                              const SizedBox(
                                                  height: CBSpace.x1),
                                              Text(
                                                widget.subtitle!,
                                                style: theme
                                                    .textTheme.bodySmall!
                                                    .copyWith(
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withValues(alpha: 0.5),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (widget.isResolved)
                                        const Icon(Icons.verified,
                                            color: CBColors.matrixGreen,
                                            size: 24)
                                      else if (widget.onTap != null)
                                        Icon(Icons.chevron_right,
                                            color: effectiveColor.withValues(
                                                alpha: 0.5)),
                                    ],
                                  ),
                                ),

                                // Content Section
                                Padding(
                                  padding: const EdgeInsets.all(CBSpace.x5),
                                  child: widget.content,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../colors.dart';
import '../theme_data.dart';

/// Atmospheric background with blurring and solid overlay.
class CBNeonBackground extends StatefulWidget {
  final Widget child;
  final String? backgroundAsset;
  final double blurSigma;
  final bool showOverlay;
  final bool showRadiance;

  const CBNeonBackground({
    super.key,
    required this.child,
    this.backgroundAsset,
    this.blurSigma = 10.0,
    this.showOverlay = true,
    this.showRadiance = false,
  });

  @override
  State<CBNeonBackground> createState() => _CBNeonBackgroundState();
}

class _CBNeonBackgroundState extends State<CBNeonBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveBackgroundAsset =
        widget.backgroundAsset ?? CBTheme.globalBackgroundAsset;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget radianceLayer() {
      if (!widget.showRadiance) return const SizedBox.shrink();
      if (reduceMotion) {
        return _StaticRadiance(scheme: scheme);
      }

      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // Slow drift across the screen. Big radii keep it soft and "club" not "spinner".
          final a = 0.5 + 0.45 * math.sin(2 * math.pi * t);
          final b = 0.5 + 0.45 * math.cos(2 * math.pi * (t + 0.23));
          final c = 0.5 + 0.45 * math.sin(2 * math.pi * (t + 0.57));

          final primary = scheme.primary;
          final secondary = scheme.secondary;
          final shimmerCyan = scheme.tertiary;
          final shimmerMagenta = scheme.tertiaryContainer;

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.lerp(
                        Alignment.topLeft,
                        Alignment.bottomRight,
                        a,
                      )!,
                      radius: 1.25,
                      colors: [
                        primary.withValues(alpha: 0.18),
                        secondary.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Transform.rotate(
                  angle: (t * 2 * math.pi) * 0.15,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.lerp(
                          Alignment.bottomRight,
                          Alignment.topLeft,
                          b,
                        )!,
                        radius: 1.35,
                        colors: [
                          shimmerCyan.withValues(alpha: 0.08),
                          shimmerMagenta.withValues(alpha: 0.06),
                          CBColors.voidBlack.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.lerp(
                        const Alignment(-0.2, 0.8),
                        const Alignment(0.9, -0.3),
                        c,
                      )!,
                      radius: 1.6,
                      colors: [
                        secondary.withValues(alpha: 0.06),
                        primary.withValues(alpha: 0.05),
                        CBColors.voidBlack.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return Stack(
      children: [
        // Base Layer
        Positioned.fill(
          child: Image.asset(
            effectiveBackgroundAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: theme.scaffoldBackgroundColor),
          ),
        ),

        // Radiance (neon spill)
        if (widget.showRadiance) Positioned.fill(child: radianceLayer()),

        // Blur Layer
        if (widget.blurSigma > 0)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blurSigma,
                sigmaY: widget.blurSigma,
              ),
              child: const ColoredBox(color: CBColors.transparent),
            ),
          ),

        // Dark Overlay (keeps contrast and makes the neon feel like light, not background paint)
        if (widget.showOverlay)
          Positioned.fill(
            child: Container(
              color: CBColors.voidBlack.withValues(alpha: 0.66),
            ),
          ),

        // Content
        widget.child,
      ],
    );
  }
}

class _StaticRadiance extends StatelessWidget {
  final ColorScheme scheme;

  const _StaticRadiance({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.25),
          radius: 1.35,
          colors: [
            scheme.primary.withValues(alpha: 0.16),
            scheme.secondary.withValues(alpha: 0.08),
            CBColors.voidBlack.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

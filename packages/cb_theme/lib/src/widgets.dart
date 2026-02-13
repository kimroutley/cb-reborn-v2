import 'package:cb_theme/src/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'colors.dart';
import 'layout.dart';
import 'haptic_service.dart';
import 'theme_data.dart';
import 'dart:math' as math;
import 'dart:ui'; // For ImageFilter

// Export modular widgets
export 'widgets/chat_bubble.dart';
export 'widgets/glass_tile.dart';
export 'widgets/phase_interrupt.dart';
export 'widgets/ghost_lounge_view.dart';
export 'widgets/cb_breathing_loader.dart';
export 'widgets/cb_role_id_card.dart';

// ═══════════════════════════════════════════════
//  REUSABLE NEON SYNTHWAVE WIDGET KIT
// ═══════════════════════════════════════════════

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
          final shimmerCyan = CBColors.cyanRefract;
          final shimmerMagenta = CBColors.magentaShift;

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
                        CBColors.voidBlack.withValues(alpha: 0.0),
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
          child: widget.backgroundAsset != null
              ? Image.asset(
                  widget.backgroundAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: theme.scaffoldBackgroundColor),
                )
              : Container(color: theme.scaffoldBackgroundColor),
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

/// A glowing panel for grouping related content.
class CBPanel extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const CBPanel({
    super.key,
    required this.child,
    this.borderColor,
    this.borderWidth = 1,
    this.padding = const EdgeInsets.all(CBSpace.x4),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = borderColor ?? theme.colorScheme.primary;
    final panelRadius = BorderRadius.circular(CBRadius.md);

    return Container(
      width: double.infinity,
      margin: margin,
      child: ClipRRect(
        borderRadius: panelRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (theme.cardTheme.color ?? scheme.surfaceContainerLow)
                  .withValues(alpha: 0.44),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.onSurface.withValues(alpha: 0.06),
                  scheme.primary.withValues(alpha: 0.11),
                  scheme.secondary.withValues(alpha: 0.09),
                  CBColors.transparent,
                ],
                stops: const [0.0, 0.22, 0.56, 1.0],
              ),
              borderRadius: panelRadius,
              border: Border.all(
                  color: color.withValues(alpha: 0.54), width: borderWidth),
              boxShadow: [
                ...CBColors.boxGlow(scheme.primary, intensity: 0.1),
                ...CBColors.boxGlow(scheme.secondary, intensity: 0.08),
              ],
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Section header bar with label + optional count badge.
class CBSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color? color;
  final IconData? icon;

  const CBSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: CBSpace.x4, vertical: CBSpace.x3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(CBRadius.sm),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: CBSpace.x3),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.titleMedium!.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                shadows: CBColors.textGlow(accentColor, intensity: 0.35),
              ),
            ),
          ),
          if (count != null)
            CBBadge(text: count.toString(), color: accentColor),
        ],
      ),
    );
  }
}

/// Compact label chip (e.g., role badge, status tag).
class CBBadge extends StatelessWidget {
  final String text;
  final Color? color;

  const CBBadge({
    super.key,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: CBSpace.x3, vertical: CBSpace.x1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CBRadius.xs),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        text.toUpperCase(),
        style: CBTypography.micro.copyWith(color: badgeColor),
      ),
    );
  }
}

/// Standard bottom-sheet handle (used when you need a handle inside a custom sheet,
/// e.g. a [DraggableScrollableSheet]).
class CBBottomSheetHandle extends StatelessWidget {
  final EdgeInsets margin;

  const CBBottomSheetHandle({
    super.key,
    this.margin = const EdgeInsets.only(bottom: CBSpace.x4),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 44,
        height: 5,
        margin: margin,
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(CBRadius.pill),
        ),
      ),
    );
  }
}

/// Full-width primary action button. Inherits all styling from the central theme.
class CBPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CBPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor;
    final fg = foregroundColor ??
        (bg == null
            ? null
            : (ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
                ? theme.colorScheme.onSurface
                : CBColors.voidBlack));

    final button = FilledButton(
      style: (bg != null || fg != null)
          ? FilledButton.styleFrom(backgroundColor: bg, foregroundColor: fg)
          : null,
      onPressed: onPressed != null
          ? () {
              HapticService.light();
              onPressed!();
            }
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label.toUpperCase()),
        ],
      ),
    );

    if (!fullWidth) return button;

    return SizedBox(width: double.infinity, child: button);
  }
}

/// Outlined ghost button. Inherits styling from the central theme,
/// but can be customized with a specific color.
class CBGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color; // Retained for accent customization

  const CBGhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: buttonColor, width: 2),
        foregroundColor: buttonColor,
      ),
      onPressed: onPressed != null
          ? () {
              HapticService.light();
              onPressed!();
            }
          : null,
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

/// Dark input field. Inherits all styling from the central theme.
class CBTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final InputDecoration? decoration;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final TextCapitalization textCapitalization;
  final bool monospace;
  final bool hapticOnChange;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;
  final TextAlign textAlign;

  const CBTextField({
    super.key,
    this.controller,
    this.hintText,
    this.errorText,
    this.decoration,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.monospace = false,
    this.hapticOnChange = false,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.textStyle,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseDecoration = decoration ?? const InputDecoration();
    final effectiveDecoration = baseDecoration.copyWith(
      hintText: hintText ?? baseDecoration.hintText,
      errorText: errorText ?? baseDecoration.errorText,
    );
    return TextField(
      controller: controller,
      textAlign: textAlign,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: (val) {
        if (hapticOnChange && val.isNotEmpty) {
          HapticService.selection();
        }
        onChanged?.call(val);
      },
      onSubmitted: onSubmitted,
      textCapitalization: textCapitalization,
      textAlign: textAlign,
      style: textStyle ??
          (monospace ? CBTypography.code : theme.textTheme.bodyLarge!),
      textAlign: textAlign,
      inputFormatters: inputFormatters,
      cursorColor: theme.colorScheme.primary,
      decoration: effectiveDecoration,
    );
  }
}

/// Neon-styled switch with consistent track/thumb treatment + haptics.
class CBSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? color;

  const CBSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return Switch(
      value: value,
      onChanged: onChanged == null
          ? null
          : (v) {
              HapticService.selection();
              onChanged!(v);
            },
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return accent;
        return scheme.onSurfaceVariant.withValues(alpha: 0.85);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accent.withValues(alpha: 0.35);
        }
        return scheme.surfaceContainerHighest.withValues(alpha: 0.85);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accent.withValues(alpha: 0.55);
        }
        return scheme.outlineVariant.withValues(alpha: 0.7);
      }),
    );
  }
}

/// Neon-styled slider wrapper (thin track + clean thumb + subtle overlay).
class CBSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final Color? color;

  const CBSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: accent,
        inactiveTrackColor: scheme.outlineVariant.withValues(alpha: 0.35),
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.14),
        trackHeight: 4,
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        onChangeEnd: (v) {
          HapticService.light();
          onChangeEnd?.call(v);
        },
      ),
    );
  }
}

/// Simple "enter" animation: fade + slight slide. Useful for lists and sheets.
class CBFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset beginOffset;

  const CBFadeSlide({
    super.key,
    required this.child,
    this.duration = CBMotion.micro,
    this.delay = Duration.zero,
    this.curve = CBMotion.emphasizedCurve,
    this.beginOffset = const Offset(0, 0.06),
  });

  @override
  State<CBFadeSlide> createState() => _CBFadeSlideState();
}

class _CBFadeSlideState extends State<CBFadeSlide> {
  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _shown = true;
    } else {
      _timer = Timer(widget.delay, () {
        if (!mounted) return;
        setState(() => _shown = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: widget.duration,
      curve: widget.curve,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : widget.beginOffset,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

/// Status overlay card (ELIMINATED, SILENCED, etc.).
class CBStatusOverlay extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final String detail;

  const CBStatusOverlay({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CBSpace.x8),
      margin: const EdgeInsets.symmetric(vertical: CBSpace.x4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(CBRadius.md),
        border: Border.all(color: accentColor, width: 2),
        boxShadow: CBColors.boxGlow(accentColor, intensity: 0.3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: accentColor),
          const SizedBox(height: CBSpace.x4),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.displaySmall!.copyWith(color: accentColor),
          ),
          const SizedBox(height: CBSpace.x3),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!,
          ),
        ],
      ),
    );
  }
}

/// Connection status indicator dot.
class CBConnectionDot extends StatelessWidget {
  final bool isConnected;
  final String? label;

  const CBConnectionDot({super.key, required this.isConnected, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isConnected ? CBColors.success : theme.colorScheme.error;
    final text = label ?? (isConnected ? 'LIVE' : 'OFFLINE');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: CBSpace.x2),
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Countdown timer widget for timed phases.
class CBCountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback? onComplete;
  final Color? color;

  const CBCountdownTimer({
    super.key,
    required this.seconds,
    this.onComplete,
    this.color, // Allow overriding base color
  });

  @override
  State<CBCountdownTimer> createState() => _CBCountdownTimerState();
}

class _CBCountdownTimerState extends State<CBCountdownTimer> {
  late int _remaining;
  late final Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timerStream = Stream.periodic(
      const Duration(seconds: 1),
      (tick) => widget.seconds - tick - 1,
    ).take(widget.seconds);

    _timerStream.listen((seconds) {
      if (mounted) {
        setState(() => _remaining = seconds);
        if (_remaining <= 5) {
          HapticService.light();
        }
      }
      if (seconds == 0) {
        HapticService.heavy();
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isCritical = _remaining <= 30;
    final displayColor = widget.color ??
        (isCritical ? CBColors.warning : theme.colorScheme.primary);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CBSpace.x8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(CBRadius.md),
        border: Border.all(color: displayColor, width: 2),
        boxShadow: CBColors.boxGlow(displayColor, intensity: 0.3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeStr,
            style: CBTypography.timer.copyWith(color: displayColor),
          ),
          const SizedBox(height: CBSpace.x2),
          Text(
            (isCritical ? 'TIME RUNNING OUT' : 'TIME REMAINING').toUpperCase(),
            style: theme.textTheme.labelMedium!.copyWith(color: displayColor),
          ),
        ],
      ),
    );
  }
}

/// Report card showing a list of events or results.
class CBReportCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final Color? color;

  const CBReportCard({
    super.key,
    required this.title,
    required this.lines,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CBSpace.x4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(CBRadius.md),
        border: Border.all(color: accentColor, width: 1),
        boxShadow: CBColors.boxGlow(accentColor, intensity: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: accentColor,
                  shadows: CBColors.textGlow(accentColor, intensity: 0.4),
                ),
          ),
          const SizedBox(height: CBSpace.x4),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: CBSpace.x3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '// ',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                      child: Text(line, style: theme.textTheme.bodySmall!)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified role avatar with glowing border for the chat feed.
class CBRoleAvatar extends StatefulWidget {
  final String? assetPath;
  final Color? color;
  final double size;
  final bool pulsing;
  final bool breathing; // Enables role-color shimmer cycle

  const CBRoleAvatar({
    super.key,
    this.assetPath,
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
          effectiveColor =
              CBColors.roleShimmerColor(baseColor, _controller.value);
          intensity = 0.5 + (_controller.value * 0.5); // 0.5 -> 1.0 glow
        }

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: CBColors.offBlack,
            shape: BoxShape.circle,
            border: Border.all(color: effectiveColor, width: 2),
            boxShadow:
                CBColors.circleGlow(effectiveColor, intensity: intensity),
          ),
          child: ClipOval(
            child: widget.assetPath != null
                ? Image.asset(
                    widget.assetPath!,
                    width: widget.size * 0.6,
                    height: widget.size * 0.6,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      color: effectiveColor,
                      size: widget.size * 0.5,
                    ),
                  )
                : Icon(
                    Icons.smart_toy,
                    color: effectiveColor,
                    size: widget.size * 0.5,
                  ),
          ),
        );
      },
    );
  }
}

/// A compact player chip for inline selection in chat action bubbles.
class CBCompactPlayerChip extends StatelessWidget {
  final String name;
  final String? assetPath;
  final Color? color;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isDisabled;

  const CBCompactPlayerChip({
    super.key,
    required this.name,
    this.assetPath,
    this.color,
    this.onTap,
    this.isSelected = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;
    final effectiveOpacity = isDisabled ? 0.35 : 1.0;
    final bgColor = isSelected
        ? accentColor.withValues(alpha: 0.15)
        : theme.colorScheme.surface;
    final borderClr =
        isSelected ? accentColor : theme.colorScheme.outlineVariant;

    return Opacity(
      opacity: effectiveOpacity,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderClr, width: 1.5),
              boxShadow: isSelected
                  ? CBColors.boxGlow(accentColor, intensity: 0.2)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tiny avatar
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: CBColors.offBlack,
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 1),
                  ),
                  child: ClipOval(
                    child: assetPath != null
                        ? Image.asset(
                            assetPath!,
                            width: 14,
                            height: 14,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: accentColor,
                              size: 12,
                            ),
                          )
                        : Icon(Icons.person, color: accentColor, size: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name.toUpperCase(),
                  style: theme.textTheme.labelSmall!.copyWith(
                    color:
                        isSelected ? accentColor : theme.colorScheme.onSurface,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A lightweight, neon-friendly filter chip (no avatar) for small toggles.
class CBFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;
  final IconData? icon;
  final bool dense;

  const CBFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
    this.icon,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = color ?? scheme.primary;

    final bg = selected
        ? accent.withValues(alpha: 0.16)
        : scheme.surfaceContainerLow.withValues(alpha: 0.9);
    final border = selected
        ? accent.withValues(alpha: 0.9)
        : scheme.outlineVariant.withValues(alpha: 0.7);
    final fg = selected ? accent : scheme.onSurface.withValues(alpha: 0.8);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          HapticService.selection();
          onSelected();
        },
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: dense
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 7)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 1.5),
            boxShadow:
                selected ? CBColors.boxGlow(accent, intensity: 0.18) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  letterSpacing: 1.0,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Unified player status tile for the host feed.
class CBPlayerStatusTile extends StatelessWidget {
  final String playerName;
  final String roleName;
  final String? assetPath;
  final Color? roleColor;
  final bool isAlive;
  final List<String> statusEffects;

  const CBPlayerStatusTile({
    super.key,
    required this.playerName,
    required this.roleName,
    this.assetPath,
    this.roleColor,
    this.isAlive = true,
    this.statusEffects = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = roleColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: accentColor.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          // Avatar
          CBRoleAvatar(assetPath: assetPath, color: accentColor, size: 32),
          const SizedBox(width: 10),

          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  playerName.toUpperCase(),
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    shadows: CBColors.textGlow(accentColor, intensity: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleName.toUpperCase(),
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: accentColor,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          // Status chips
          if (!isAlive) CBBadge(text: 'DEAD', color: CBColors.dead),
          if (isAlive && statusEffects.isNotEmpty)
            ...statusEffects.map(
              (effect) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: CBBadge(
                  text: effect.toUpperCase(),
                  color: _statusColor(effect),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String effect) {
    return switch (effect.toLowerCase()) {
      'protected' => CBColors.fromHex('#FF0000'), // Medic (red)
      'silenced' => CBColors.fromHex('#00C853'), // Roofi (green)
      'id checked' => CBColors.fromHex('#4169E1'), // Bouncer (royal blue)
      'sighted' => CBColors.fromHex('#483C32'), // Club Manager (dark brown)
      'alibi' => CBColors.fromHex('#808000'), // Silver Fox (olive)
      'sent home' => CBColors.fromHex('#32CD32'), // Sober (lime green)
      'clinging' => CBColors.fromHex('#FFFF00'), // Clinger (yellow)
      'paralysed' || 'paralyzed' => CBColors.purple,
      _ => CBColors.dead,
    };
  }
}

/// High-density technical status rail.
class CBStatusRail extends StatelessWidget {
  final List<({String label, String value, Color color})> stats;

  const CBStatusRail({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 24,
      width: double.infinity,
      color: theme.scaffoldBackgroundColor,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stats.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '|',
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
        ),
        itemBuilder: (context, index) {
          final s = stats[index];
          return Row(
            children: [
              Text(
                '${s.label}: ',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              Text(
                s.value.toUpperCase(),
                style: theme.textTheme.bodySmall!.copyWith(
                  color: s.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// CBPrismScaffold: Neon-themed scaffold with glowing effects
class CBPrismScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool showAppBar;
  final bool useSafeArea;
  final List<Widget>? actions;
  final Widget? drawer;
  final String backgroundAsset;
  final bool showBackgroundRadiance;

  const CBPrismScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.showAppBar = true,
    this.useSafeArea = true,
    this.actions,
    this.drawer,
    this.backgroundAsset = CBTheme.globalBackgroundAsset,
    this.showBackgroundRadiance = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: showAppBar
          ? AppBar(
              title: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge!,
              ),
              centerTitle: true,
              actions: actions,
            )
          : null,
      drawer: drawer,
      body: CBNeonBackground(
        backgroundAsset: backgroundAsset,
        showRadiance: showBackgroundRadiance,
        child: useSafeArea ? SafeArea(child: body) : body,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

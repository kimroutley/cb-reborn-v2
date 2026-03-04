import 'dart:ui';

import 'package:flutter/material.dart';

import 'colors.dart';
import 'layout.dart';
import 'typography.dart';
import 'widgets.dart';

Future<T?> showThemedDialog<T>({
  required BuildContext context,
  required Widget child,
  Color? accentColor,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: CBColors.voidBlack.withValues(alpha: 0.82),
    transitionDuration: CBMotion.micro,
    pageBuilder: (context, animation, secondaryAnimation) {
      final scheme = Theme.of(context).colorScheme;
      final accent = accentColor ?? scheme.primary;

      return Center(
        child: Material(
          type: MaterialType.transparency,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: CBMotion.emphasizedCurve,
            ),
            child: FadeTransition(
              opacity: animation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: CBSpace.x6),
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(CBRadius.dialog),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                  boxShadow: [
                    ...CBColors.boxGlow(accent, intensity: 0.12),
                    BoxShadow(
                      color: CBColors.voidBlack.withValues(alpha: 0.55),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(CBRadius.dialog),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: CBInsets.panel,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showThemedLoadingDialog({
  required BuildContext context,
  String message = 'Loading...',
  Color? accentColor,
}) {
  return showThemedDialog<void>(
    context: context,
    accentColor: accentColor,
    barrierDismissible: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CBBreathingSpinner(size: 48),
        const SizedBox(height: 24),
        Text(
          message,
          style: CBTypography.h3.copyWith(color: accentColor ?? CBColors.radiantTurquoise),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const CBTypingIndicator(),
      ],
    ),
  );
}

Future<T?> showThemedBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  Color? accentColor,
  EdgeInsets padding = CBInsets.sheet,
}) {
  return showThemedBottomSheetBuilder<T>(
    context: context,
    accentColor: accentColor,
    padding: padding,
    builder: (_) => child,
  );
}

Future<void> showPhaseTransitionOverlay({
  required BuildContext context,
  required String title,
  required String subtitle,
  Color? accentColor,
  Duration duration = const Duration(seconds: 3),
}) async {
  final entry = OverlayEntry(
    builder: (context) => _CBPhaseTransitionOverlay(
      title: title,
      subtitle: subtitle,
      accentColor: accentColor,
      duration: duration,
    ),
  );

  Overlay.of(context).insert(entry);
  await Future.delayed(duration);
  entry.remove();
}

class _CBPhaseTransitionOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color? accentColor;
  final Duration duration;

  const _CBPhaseTransitionOverlay({
    required this.title,
    required this.subtitle,
    this.accentColor,
    required this.duration,
  });

  @override
  State<_CBPhaseTransitionOverlay> createState() => __CBPhaseTransitionOverlayState();
}

class __CBPhaseTransitionOverlayState extends State<_CBPhaseTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blurAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _blurAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 800), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accentColor ?? scheme.primary;

    return Material(
      color: CBColors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _blurAnimation.value,
              sigmaY: _blurAnimation.value,
            ),
            child: Container(
              color: CBColors.voidBlack.withValues(alpha: 0.6 * _controller.value),
              child: Center(
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CBFeedSeparator(
                          label: widget.title,
                          color: accent,
                        ),
                        const SizedBox(height: CBSpace.x4),
                        Text(
                          widget.subtitle.toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: accent,
                                letterSpacing: 4.0,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: accent.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                        ),
                      ],
                    ),
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

Future<T?> showThemedBottomSheetBuilder<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? accentColor,
  EdgeInsets padding = CBInsets.sheet,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  bool addHandle = true,
  bool wrapInScrollView = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: CBColors.transparent,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      final accent = accentColor ?? scheme.primary;
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

      final built = builder(context);
      final content =
          wrapInScrollView
              ? SingleChildScrollView(
                  padding: padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (addHandle)
                        const CBBottomSheetHandle(),
                      built,
                    ],
                  ),
                )
              : (addHandle
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CBBottomSheetHandle(
                          margin: EdgeInsets.only(top: CBSpace.x5, bottom: CBSpace.x5),
                        ),
                        built,
                      ],
                    )
                  : built);

      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Material(
          color: scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(CBRadius.dialog)),
            side: BorderSide(color: accent.withValues(alpha: 0.55), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      );
    },
  );
}

void showThemedSnackBar(
  BuildContext context,
  String message, {
  Color? accentColor,
  Duration? duration,
}) {
  final scheme = Theme.of(context).colorScheme;
  final accent = accentColor ?? scheme.primary;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
            ),
      ),
      backgroundColor: scheme.surfaceContainerHigh.withValues(alpha: 0.95),
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CBRadius.sm),
        side: BorderSide(
          color: accent.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
    ),
  );
}

Future<T?> showThemedFullScreenDialog<T>({
  required BuildContext context,
  required Widget child,
  Color? accentColor,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: CBColors.voidBlack.withValues(alpha: 0.84),
    transitionDuration: CBMotion.micro,
    pageBuilder: (context, animation, secondaryAnimation) {
      final scheme = Theme.of(context).colorScheme;
      final accent = accentColor ?? scheme.primary;

      return SafeArea(
        child: Padding(
          padding: CBInsets.screen,
          child: Material(
            color: scheme.surfaceContainerHigh.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CBRadius.xl),
              side: BorderSide(color: accent.withValues(alpha: 0.6), width: 1.6),
            ),
            clipBehavior: Clip.antiAlias,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: child,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

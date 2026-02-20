import 'dart:async';

import 'package:flutter/material.dart';

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
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
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

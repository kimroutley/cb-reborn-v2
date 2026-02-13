import 'package:flutter/material.dart';
import '../colors.dart';

/// A linear progress indicator with a breathing neon gradient effect.
class CBBreathingBar extends StatefulWidget {
  final double width;
  final double height;
  final Duration duration;

  const CBBreathingBar({
    super.key,
    this.width = double.infinity,
    this.height = 4.0,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<CBBreathingBar> createState() => _CBBreathingBarState();
}

class _CBBreathingBarState extends State<CBBreathingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height / 2),
            gradient: LinearGradient(
              colors: const [
                CBColors.radiantPink,
                CBColors.radiantTurquoise,
                CBColors.radiantPink,
              ],
              begin: Alignment(-1.0 - _controller.value, 0.0),
              end: Alignment(1.0 + _controller.value, 0.0),
              transform: GradientRotation(_controller.value * 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  CBColors.radiantPink,
                  CBColors.radiantTurquoise,
                  _controller.value,
                )!
                    .withValues(alpha: 0.5),
                blurRadius: 8 + (4 * _controller.value),
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A circular spinner with breathing neon colors.
class CBBreathingSpinner extends StatefulWidget {
  final double size;
  final double strokeWidth;

  const CBBreathingSpinner({
    super.key,
    this.size = 48.0,
    this.strokeWidth = 4.0,
  });

  @override
  State<CBBreathingSpinner> createState() => _CBBreathingSpinnerState();
}

class _CBBreathingSpinnerState extends State<CBBreathingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * 3.14159,
            child: CircularProgressIndicator(
              strokeWidth: widget.strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.lerp(
                  CBColors.radiantPink,
                  CBColors.radiantTurquoise,
                  (_controller.value * 2).clamp(0.0, 1.0) <= 0.5
                      ? (_controller.value * 2)
                      : (1.0 - (_controller.value * 2 - 1.0)),
                )!,
              ),
              backgroundColor: CBColors.voidBlack.withValues(alpha: 0.2),
            ),
          );
        },
      ),
    );
  }
}

/// A typing indicator with 3 bouncing active neon dots.
class CBTypingIndicator extends StatefulWidget {
  final double dotSize;
  final double spacing;

  const CBTypingIndicator({
    super.key,
    this.dotSize = 10.0,
    this.spacing = 6.0,
  });

  @override
  State<CBTypingIndicator> createState() => _CBTypingIndicatorState();
}

class _CBTypingIndicatorState extends State<CBTypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    // Staggered start
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
          child: AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -6 * _controllers[index].value),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      CBColors.radiantPink,
                      CBColors.radiantTurquoise,
                      _controllers[index].value,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.lerp(
                          CBColors.radiantPink,
                          CBColors.radiantTurquoise,
                          _controllers[index].value,
                        )!
                            .withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

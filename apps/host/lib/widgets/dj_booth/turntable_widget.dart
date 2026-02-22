import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';
import 'dart:math' as math;

enum GodModeFeature {
  kill,
  mute,
  shield,
  sinBin,
  shadowBan,
  kick,
  rumour,
  voiceOfGod,
}

class TurntableWidget extends StatefulWidget {
  const TurntableWidget({super.key});

  @override
  State<TurntableWidget> createState() => _TurntableWidgetState();
}

class _TurntableWidgetState extends State<TurntableWidget> {
  double _angle = 0.0;
  int _selectedIndex = 0;

  final List<GodModeFeature> _features = GodModeFeature.values;

  void _onPanUpdate(DragUpdateDetails details) {
    const center = Offset(150, 150);
    final angle = (details.localPosition - center).direction;
    setState(() {
      _angle = angle;
      _selectedIndex = ((_angle / (2 * math.pi)) * _features.length).round() %
          _features.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CBColors.darkGrey,
          border: Border.all(
            color: CBColors.primary.withValues(alpha: 0.5),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: CBColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          children: [
            ..._buildFeatureLabels(scheme),
            Center(
              child: Transform.rotate(
                angle: _angle,
                child: Container(
                  width: 20,
                  height: 100,
                  decoration: BoxDecoration(
                    color: CBColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerHigh,
                ),
                child: Center(
                  child: Text(
                    _features[_selectedIndex].name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeatureLabels(ColorScheme scheme) {
    final List<Widget> labels = [];
    final angleStep = (2 * math.pi) / _features.length;

    for (int i = 0; i < _features.length; i++) {
      final angle = i * angleStep;
      final x = 150 + 120 * math.cos(angle);
      final y = 150 + 120 * math.sin(angle);

      labels.add(
        Positioned(
          left: x - 30,
          top: y - 15,
          child: SizedBox(
            width: 60,
            child: Text(
              _features[i].name.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: i == _selectedIndex
                    ? CBColors.primary
                    : scheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
      );
    }
    return labels;
  }
}

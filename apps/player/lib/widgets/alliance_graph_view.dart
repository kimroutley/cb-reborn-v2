import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

/// A visual graph showing a role's synergies (Allies) and counters (Threats).
/// Renders the central role connected to surrounding roles with glowing lines.
class AllianceGraphView extends StatelessWidget {
  final String roleId;
  final List<String> synergies;
  final List<String> counters;
  final Color roleColor;

  const AllianceGraphView({
    super.key,
    required this.roleId,
    required this.synergies,
    required this.counters,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    if (synergies.isEmpty && counters.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        // Graph Container
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: roleColor.withValues(alpha: 0.1),
            ),
          ),
          child: Stack(
            children: [
              // Connection Lines Painter
              CustomPaint(
                size: Size.infinite,
                painter: _GraphPainter(
                  synergiesCount: synergies.length,
                  countersCount: counters.length,
                  synergyColor: CBColors.neonGreen,
                  counterColor: scheme.error,
                  scheme: scheme,
                ),
              ),

              // Layout Nodes
              LayoutBuilder(
                builder: (context, constraints) {
                  final center = Offset(
                    constraints.maxWidth / 2,
                    constraints.maxHeight / 2,
                  );
                  final radius = constraints.maxHeight * 0.35;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Central Node (My Role)
                      Positioned(
                        left: center.dx - 32,
                        top: center.dy - 32,
                        child: _buildNode(
                          roleId,
                          roleColor,
                          true,
                          'YOU',
                          theme,
                        ),
                      ),

                      // Synergy Nodes (Right Side)
                      ..._buildSatelliteNodes(
                        ids: synergies,
                        center: center,
                        radius: radius,
                        startAngle: -0.5, // Right side arc
                        sweepAngle: 1.0,
                        color: CBColors.neonGreen,
                        theme: theme,
                      ),

                      // Counter Nodes (Left Side)
                      ..._buildSatelliteNodes(
                        ids: counters,
                        center: center,
                        radius: radius,
                        startAngle: 2.6, // Left side arc
                        sweepAngle: 1.0,
                        color: scheme.error,
                        theme: theme,
                      ),
                    ],
                  );
                },
              ),

              // Labels
              if (counters.isNotEmpty)
                Positioned(
                  top: 12,
                  left: 16,
                  child: _buildLabel('THREATS', scheme.error, theme),
                ),
              if (synergies.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 16,
                  child: _buildLabel('ALLIES', CBColors.neonGreen, theme),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall!.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  List<Widget> _buildSatelliteNodes({
    required List<String> ids,
    required Offset center,
    required double radius,
    required double startAngle,
    required double sweepAngle,
    required Color color,
    required ThemeData theme,
  }) {
    if (ids.isEmpty) return [];

    final widgets = <Widget>[];
    final count = ids.length;

    for (int i = 0; i < count; i++) {
      // Simple radial distribution logic
      // Right side: -pi/4 to pi/4 approx
      // Left side: 3pi/4 to 5pi/4 approx
      
      double theta = 0;
      if (startAngle < 0) {
        // Right side (Synergies)
        theta = (i - (count - 1) / 2) * 0.6; 
      } else {
        // Left side (Counters)
        theta = 3.14159 + (i - (count - 1) / 2) * 0.6;
      }

      // Explicit offsets using polar coordinates
      final x = center.dx + radius * (theta.abs() > 1.5 ? -1 : 1) * 0.8;
      final y = center.dy + radius * 0.8 * (i - (count - 1) / 2);

      widgets.add(Positioned(
        left: x - 24,
        top: y - 30, // Adjust for text height
        child: _buildNode(ids[i], color, false, null, theme),
      ));
    }
    return widgets;
  }

  Widget _buildNode(
    String id,
    Color color,
    bool isCenter,
    String? label,
    ThemeData theme,
  ) {
    final role = roleCatalogMap[id];
    final size = isCenter ? 64.0 : 42.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CBRoleAvatar(
          assetPath: 'assets/roles/$id.png',
          color: color,
          size: size,
          breathing: isCenter,
          pulsing: isCenter,
        ),
        const SizedBox(height: 6),
        Text(
          label ?? role?.name.toUpperCase() ?? id.toUpperCase(),
          style: theme.textTheme.labelSmall!.copyWith(
            color: color,
            fontSize: isCenter ? 10 : 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            shadows: isCenter ? CBColors.textGlow(color) : null,
          ),
        ),
      ],
    );
  }
}

class _GraphPainter extends CustomPainter {
  final int synergiesCount;
  final int countersCount;
  final Color synergyColor;
  final Color counterColor;
  final ColorScheme scheme;

  _GraphPainter({
    required this.synergiesCount,
    required this.countersCount,
    required this.synergyColor,
    required this.counterColor,
    required this.scheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height * 0.35;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw Synergy Lines (Right)
    paint.color = synergyColor.withValues(alpha: 0.3);
    for (int i = 0; i < synergiesCount; i++) {
      final y = center.dy + radius * 0.8 * (i - (synergiesCount - 1) / 2);
      final x = center.dx + radius * 0.8;
      canvas.drawLine(center, Offset(x, y), paint);
    }

    // Draw Counter Lines (Left)
    paint.color = counterColor.withValues(alpha: 0.3);
    for (int i = 0; i < countersCount; i++) {
      final y = center.dy + radius * 0.8 * (i - (countersCount - 1) / 2);
      final x = center.dx - radius * 0.8;
      canvas.drawLine(center, Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

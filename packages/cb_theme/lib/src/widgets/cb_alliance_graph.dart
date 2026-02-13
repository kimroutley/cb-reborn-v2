import 'package:flutter/material.dart';
import '../colors.dart';
import '../haptic_service.dart';

enum AllianceNode { dealers, partyAnimals, wildcards }

class CBAllianceGraph extends StatefulWidget {
  const CBAllianceGraph({super.key});

  @override
  State<CBAllianceGraph> createState() => _CBAllianceGraphState();
}

class _CBAllianceGraphState extends State<CBAllianceGraph>
    with SingleTickerProviderStateMixin {
  AllianceNode _selectedNode = AllianceNode.partyAnimals;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNodeTap(AllianceNode node) {
    if (_selectedNode == node) return;
    HapticService.selection();
    setState(() => _selectedNode = node);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.2,
          child: Stack(
            children: [
              // ── THE GRAPH CANVAS ──
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _AllianceGraphPainter(
                        selectedNode: _selectedNode,
                        animationValue: _controller.value,
                        primaryColor: scheme.primary,
                        secondaryColor: scheme.secondary,
                        tertiaryColor: scheme.tertiary,
                      ),
                    );
                  },
                ),
              ),

              // ── DEALERS NODE (Top) ──
              _buildNode(
                alignment: const Alignment(0, -0.85),
                node: AllianceNode.dealers,
                label: "THE DEALERS",
                icon: Icons.dangerous_rounded,
                color: scheme.primary, // Using primary for Dealers per design
              ),

              // ── PARTY ANIMALS NODE (Bottom Left) ──
              _buildNode(
                alignment: const Alignment(-0.85, 0.7),
                node: AllianceNode.partyAnimals,
                label: "PARTY ANIMALS",
                icon: Icons.celebration_rounded,
                color: scheme.secondary, // Using secondary for Party Animals
              ),

              // ── WILDCARDS NODE (Bottom Right) ──
              _buildNode(
                alignment: const Alignment(0.85, 0.7),
                node: AllianceNode.wildcards,
                label: "WILDCARDS",
                icon: Icons.question_mark_rounded,
                color: scheme.tertiary, // Using tertiary for Wildcards
              ),
            ],
          ),
        ),

        // ── MISSION BRIEF PANEL ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildBriefPanel(context),
          ),
        ),
      ],
    );
  }

  Widget _buildNode({
    required Alignment alignment,
    required AllianceNode node,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedNode == node;
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: () => _onNodeTap(node),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 72 : 60,
              height: isSelected ? 72 : 60,
              decoration: BoxDecoration(
                color: CBColors.voidBlack,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : color.withValues(alpha: 0.3),
                  width: isSelected ? 3 : 1.5,
                ),
                boxShadow: isSelected
                    ? CBColors.circleGlow(color, intensity: 0.8)
                    : [],
              ),
              child: Icon(
                icon,
                color: isSelected ? color : color.withValues(alpha: 0.5),
                size: isSelected ? 32 : 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: isSelected ? color : color.withValues(alpha: 0.4),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    letterSpacing: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBriefPanel(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final info = switch (_selectedNode) {
      AllianceNode.dealers => (
          title: "THE DEALERS",
          objective: "ELIMINATE THE COMPETITION",
          desc:
              "Club Staff by day, ruthless killers by night. They hide in plain sight, coordinating murders until they control the majority vote.",
          color: scheme.primary,
        ),
      AllianceNode.partyAnimals => (
          title: "THE PARTY ANIMALS",
          objective: "EXPOSE THE TRUTH",
          desc:
              "The true life of the party. Their only weapon is discussion and the daytime vote. They win if all Dealers are identified and exiled.",
          color: scheme.secondary,
        ),
      AllianceNode.wildcards => (
          title: "WILDCARDS",
          objective: "VARIABLE ENDGAMES",
          desc:
              "Agents of chaos. They often have personal win conditions that don't depend on either team. Trust them at your own peril.",
          color: scheme.tertiary,
        ),
    };

    return Container(
      key: ValueKey(_selectedNode),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: info.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                color: info.color,
              ),
              const SizedBox(width: 12),
              Text(
                info.objective,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: info.color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            info.desc,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllianceGraphPainter extends CustomPainter {
  final AllianceNode selectedNode;
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  _AllianceGraphPainter({
    required this.selectedNode,
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final dealersPos = Offset(centerX, size.height * 0.15);
    final animalsPos = Offset(size.width * 0.15, size.height * 0.85);
    final wildcardsPos = Offset(size.width * 0.85, size.height * 0.85);

    // ── DRAW CONNECTIONS ──
    _drawPath(canvas, dealersPos, animalsPos, primaryColor, secondaryColor);
    _drawPath(canvas, animalsPos, wildcardsPos, secondaryColor, tertiaryColor);
    _drawPath(canvas, wildcardsPos, dealersPos, tertiaryColor, primaryColor);
  }

  void _drawPath(Canvas canvas, Offset p1, Offset p2, Color c1, Color c2) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final gradient = LinearGradient(
      colors: [c1.withValues(alpha: 0.3), c2.withValues(alpha: 0.3)],
    );

    paint.shader = gradient.createShader(Rect.fromPoints(p1, p2));
    canvas.drawLine(p1, p2, paint);

    // ── ANIMATED PULSE ──
    final pulsePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final t = (animationValue + (p1.dx * 0.001)) % 1.0;
    final pulsePos = Offset.lerp(p1, p2, t)!;
    canvas.drawCircle(pulsePos, 2, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

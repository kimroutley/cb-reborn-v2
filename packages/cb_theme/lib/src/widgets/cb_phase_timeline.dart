import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';

class CBPhaseTimeline extends StatelessWidget {
  const CBPhaseTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhaseStep(
          context,
          "01. NIGHTFALL",
          "Shadow operations commence. Silent actions, hidden identities.",
          scheme.primary,
          Icons.nights_stay_rounded,
          true,
        ),
        _buildPhaseStep(
          context,
          "02. RECKONING",
          "Casualties revealed. Secret intel delivered to private feeds.",
          scheme.secondary,
          Icons.notification_important_rounded,
          true,
        ),
        _buildPhaseStep(
          context,
          "03. DISCOURSE",
          "Public debate. Identifying anomalies in the narrative.",
          scheme.tertiary,
          Icons.forum_rounded,
          true,
        ),
        _buildPhaseStep(
          context,
          "04. EXECUTION",
          "Majority vote. One suspect is exiled to the Bar Tab.",
          scheme.error,
          Icons.gavel_rounded,
          false,
        ),
      ],
    );
  }

  Widget _buildPhaseStep(
    BuildContext context,
    String title,
    String desc,
    Color color,
    IconData icon,
    bool showConnector,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TIMELINE TRACK ──
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: CBColors.voidBlack,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                    boxShadow: CBColors.circleGlow(color, intensity: 0.4),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [color, color.withValues(alpha: 0.1)],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // ── CONTENT ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.labelLarge!.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: textTheme.bodySmall!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

/// Collapsible report section for night/day events on the player screen.
class PlayerReportSection extends StatefulWidget {
  final String title;
  final List<String> lines;
  final Color? color;

  const PlayerReportSection({
    super.key,
    required this.title,
    required this.lines,
    this.color,
  });

  @override
  State<PlayerReportSection> createState() => _PlayerReportSectionState();
}

class _PlayerReportSectionState extends State<PlayerReportSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final effectiveColor = widget.color ?? scheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: CBSpace.x3),
      child: CBFadeSlide(
        child: CBGlassTile(
          borderColor: effectiveColor.withValues(alpha: 0.4),
          padding: EdgeInsets.zero,
          isPrismatic: _expanded && widget.lines.isNotEmpty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () {
                  HapticService.selection();
                  setState(() => _expanded = !_expanded);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: CBSpace.x3),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: effectiveColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.assignment_rounded,
                            color: effectiveColor, size: 16),
                      ),
                      const SizedBox(width: CBSpace.x3),
                      Expanded(
                        child: Text(
                          widget.title.toUpperCase(),
                          style: textTheme.labelLarge?.copyWith(
                            color: effectiveColor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            shadows: CBColors.textGlow(effectiveColor,
                                intensity: 0.3),
                          ),
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: effectiveColor.withValues(alpha: 0.6),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: Padding(
                  padding: const EdgeInsets.fromLTRB(CBSpace.x4, 0, CBSpace.x4, CBSpace.x4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(bottom: CBSpace.x3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              effectiveColor.withValues(alpha: 0.3),
                              CBColors.transparent
                            ],
                          ),
                        ),
                      ),
                      if (widget.lines.isEmpty)
                        Text(
                          'NO DATA ENTRIES RECORDED.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.4),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else
                        ...widget.lines.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: CBSpace.x2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.key + 1}. ',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: effectiveColor,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'RobotoMono',
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.value.toUpperCase(),
                                        style: textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                secondChild: const SizedBox.shrink(),
                crossFadeState: _expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: CBMotion.transition,
                sizeCurve: CBMotion.emphasizedCurve,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../cb_theme.dart';

/// A collapsible day-recap card used in both player and host feeds.
///
/// Shows a header + first [collapsedBulletCount] bullets by default;
/// tapping "EXPAND" reveals the rest.
class CBDayRecapCard extends StatefulWidget {
  /// Card headline (e.g. "DAY 2 RECAP").
  final String title;

  /// Bullet-point strings to display.
  final List<String> bullets;

  /// How many bullets to show while collapsed.
  final int collapsedBulletCount;

  /// Accent color for the header icon and expand control.
  final Color? accentColor;

  /// Optional tag text shown next to the title (e.g. "HOST ONLY").
  final String? tagText;

  /// Optional tag color override.
  final Color? tagColor;

  const CBDayRecapCard({
    super.key,
    required this.title,
    required this.bullets,
    this.collapsedBulletCount = 3,
    this.accentColor,
    this.tagText,
    this.tagColor,
  });

  @override
  State<CBDayRecapCard> createState() => _CBDayRecapCardState();
}

class _CBDayRecapCardState extends State<CBDayRecapCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = widget.accentColor ?? scheme.primary;

    final hasOverflow = widget.bullets.length > widget.collapsedBulletCount;
    final visibleBullets = _expanded
        ? widget.bullets
        : widget.bullets.take(widget.collapsedBulletCount).toList();

    return CBFadeSlide(
      child: CBGlassTile(
        borderColor: accent.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(CBSpace.x5),
        isPrismatic: _expanded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(CBSpace.x2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.summarize_rounded,
                    size: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(width: CBSpace.x3),
                Expanded(
                  child: Text(
                    widget.title.toUpperCase(),
                    style: textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      fontSize: 11,
                      shadows: CBColors.textGlow(accent, intensity: 0.3),
                    ),
                  ),
                ),
                if (widget.tagText != null)
                  CBMiniTag(
                    text: widget.tagText!,
                    color: widget.tagColor ?? CBColors.alertOrange,
                  ),
              ],
            ),
            const SizedBox(height: CBSpace.x4),
            if (widget.bullets.isEmpty)
              Text(
                'NO RECAP DATA AVAILABLE FOR THIS CYCLE.',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.3),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              )
            else
              ...visibleBullets.map(
                (bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '> ',
                        style: textTheme.bodySmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bullet.toUpperCase(),
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.8),
                            fontSize: 11,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (hasOverflow) ...[
              const SizedBox(height: CBSpace.x2),
              Material(
                color: CBColors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticService.selection();
                    setState(() => _expanded = !_expanded);
                  },
                  borderRadius: BorderRadius.circular(CBRadius.xs),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _expanded
                              ? Icons.keyboard_double_arrow_up_rounded
                              : Icons.keyboard_double_arrow_down_rounded,
                          size: 18,
                          color: accent.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (_expanded ? 'COLLAPSE' : 'EXPAND').toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: accent.withValues(alpha: 0.7),
                            letterSpacing: 2.0,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

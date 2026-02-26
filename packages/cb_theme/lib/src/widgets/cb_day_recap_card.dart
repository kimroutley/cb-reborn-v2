import 'package:flutter/material.dart';
import 'glass_tile.dart';
import 'cb_mini_tag.dart';
import '../colors.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: CBGlassTile(
        borderColor: accent.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row ──
            Row(
              children: [
                Icon(
                  Icons.summarize_rounded,
                  size: 16,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 10,
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

            const SizedBox(height: 10),

            // ── Bullets ──
            if (widget.bullets.isEmpty)
              Text(
                'No recap available.',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...visibleBullets.map(
                (bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•  ',
                        style: textTheme.bodySmall?.copyWith(
                          color: accent.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          bullet,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.8),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Expand / Collapse ──
            if (hasOverflow) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: accent.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expanded ? 'COLLAPSE' : 'EXPAND',
                      style: textTheme.labelSmall?.copyWith(
                        color: accent.withValues(alpha: 0.7),
                        letterSpacing: 1.0,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

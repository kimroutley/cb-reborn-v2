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
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = widget.color ?? scheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CBPanel(
        borderColor: effectiveColor,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  CBBadge(text: widget.title, color: effectiveColor),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: effectiveColor,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              for (var i = 0; i < widget.lines.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${i + 1}. ${widget.lines[i]}',
                    style: textTheme.bodySmall!,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../colors.dart';
import 'cb_panel.dart';

class CBSlidingPanel extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final Widget child;
  final double width;
  final String title;
  final Color? accentColor;

  const CBSlidingPanel({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.child,
    this.width = 420,
    this.title = 'DETAILS',
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    const curve = Curves.easeOutExpo;
    const duration = Duration(milliseconds: 400);
    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? scheme.primary;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final panelWidth = width.clamp(320.0, screenWidth * 0.92);

    return Stack(
      children: [
        if (isOpen)
          Positioned.fill(
            child: Semantics(
              button: true,
              label: 'Dismiss',
              onTap: onClose,
              child: GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: AnimatedOpacity(
                  duration: duration,
                  curve: curve,
                  opacity: isOpen ? 1 : 0,
                  child: Container(color: Colors.black.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ),

        AnimatedPositioned(
          duration: duration,
          curve: curve,
          top: 0,
          bottom: 0,
          right: isOpen ? 0 : -panelWidth,
          width: panelWidth,
          child: CBPanel(
            padding: EdgeInsets.zero,
            borderColor: accent.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.06),
                    border: Border(
                      bottom: BorderSide(
                        color: accent.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    letterSpacing: 2.5,
                                    fontWeight: FontWeight.w900,
                                    color: accent,
                                    shadows: CBColors.textGlow(accent),
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        button: true,
                        label: 'Close panel',
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: onClose,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

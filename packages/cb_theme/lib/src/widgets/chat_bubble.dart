import 'dart:ui';
import 'package:flutter/material.dart';
import '../../cb_theme.dart';

/// Visual variants for message bubbles in the feed.
enum CBMessageVariant {
  /// Standard role narration.
  narrative,

  /// Host-only directive (maroon background).
  directive,

  /// Centered system text.
  system,

  /// Outcome result summary.
  result,
}

/// A high-fidelity, polished M3 message bubble with "Legacy Synthwave" glow.
class CBMessageBubble extends StatefulWidget {
  final String content;
  final String? senderName;
  final Widget? avatar;
  final CBPlayerStatusTile? playerHeader;

  /// The accent color for the border and glow.
  /// If null, uses [Theme.of(context).colorScheme.primary].
  final Color? accentColor;

  final CBMessageVariant variant;
  final List<Widget>? actions;
  final bool isClustered;
  final bool isResolved;

  const CBMessageBubble({
    super.key,
    required this.content,
    this.senderName,
    this.avatar,
    this.playerHeader,
    this.accentColor,
    this.variant = CBMessageVariant.narrative,
    this.actions,
    this.isClustered = false,
    this.isResolved = false,
  });

  @override
  State<CBMessageBubble> createState() => _CBMessageBubbleState();
}

class _CBMessageBubbleState extends State<CBMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation =
        Tween<double>(begin: 0.1, end: 0.4).animate(_glowController);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variant == CBMessageVariant.system &&
        widget.content.startsWith('STIM:')) {
      return const SizedBox.shrink();
    }

    return switch (widget.variant) {
      CBMessageVariant.system => _buildSystemBubble(context),
      CBMessageVariant.directive => _buildDirectiveBubble(context),
      CBMessageVariant.result => _buildResultBubble(context),
      _ => _buildNarrativeBubble(context),
    };
  }

  Widget _buildSystemBubble(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.accentColor ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildDivider(color: color)),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.content.toUpperCase(),
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: color,
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.w800,
                  shadows: CBColors.textGlow(color, intensity: 0.5),
                ),
              ),
            ),
          ),
          Expanded(child: _buildDivider(color: color)),
        ],
      ),
    );
  }

  // Modified: No gradient, just a solid line
  Widget _buildDivider({required Color color}) {
    return Container(
      height: 1,
      color: color.withValues(alpha: 0.4),
    );
  }

  Widget _buildDirectiveBubble(BuildContext context) {
    final theme = Theme.of(context);
    final neonRed = theme.colorScheme.error;
    final maroon =
        Color.alphaBlend(neonRed.withValues(alpha: 0.14), CBColors.voidBlack);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: maroon,
              border:
                  Border.all(color: neonRed.withValues(alpha: 0.5), width: 1),
              boxShadow: CBColors.boxGlow(neonRed, intensity: 0.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, size: 14, color: neonRed),
                    const SizedBox(width: 8),
                    Text(
                      'HOST DIRECTIVE',
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: neonRed.withValues(alpha: 0.9),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.content,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBubble(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.accentColor ?? theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.content,
              style: theme.textTheme.labelSmall!.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrativeBubble(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.accentColor ?? theme.colorScheme.primary;
    final hasHeader = widget.playerHeader != null;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.symmetric(
            vertical: widget.isClustered ? 2 : 8,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: CBColors.boxGlow(color, intensity: _glowAnimation.value),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: CBColors.glassmorphism(
                  color: color,
                  borderColor: color,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasHeader)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: widget.playerHeader!,
                      ),
                    Padding(
                      padding: hasHeader
                          ? const EdgeInsets.fromLTRB(16, 0, 16, 16)
                          : const EdgeInsets.all(16),
                      child: Text(
                        widget.content,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    if (widget.actions != null &&
                        widget.actions!.isNotEmpty) ...[
                      const Divider(height: 1, thickness: 0.5),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.actions!,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

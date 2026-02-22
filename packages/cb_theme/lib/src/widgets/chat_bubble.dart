import 'package:flutter/material.dart';
import 'package:cb_theme/src/widgets/cb_role_avatar.dart';

enum CBMessageStyle {
  system, // Centered, pill-style, low emphasis
  narrative, // Centered, story text, medium emphasis
  standard, // Left/Right bubble (chat)
  action, // Interactive/Command prompt style
  result, // High impact outcome
}

enum CBMessageGroupPosition {
  single,
  top,
  middle,
  bottom,
}

/// A modern, messaging-app style chat bubble.
class CBMessageBubble extends StatelessWidget {
  final String sender;
  final String message;
  final DateTime? timestamp;
  final CBMessageStyle style;
  final Color? color;
  final String? avatarAsset;
  final bool isSender;
  final CBMessageGroupPosition groupPosition;

  /// Deprecated: Use style instead.
  final bool? isSystemMessage;

  const CBMessageBubble({
    super.key,
    required this.sender,
    required this.message,
    this.timestamp,
    this.style = CBMessageStyle.standard,
    this.color,
    this.avatarAsset,
    this.isSender = false,
    this.groupPosition = CBMessageGroupPosition.single,
    @Deprecated('Use style: CBMessageStyle.system instead')
    this.isSystemMessage,
  });

  CBMessageStyle get _effectiveStyle =>
      (isSystemMessage ?? false) ? CBMessageStyle.system : style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isSystem = _effectiveStyle == CBMessageStyle.system;
    final bool isNarrative = _effectiveStyle == CBMessageStyle.narrative;

    if (isSystem || isNarrative) {
      return _buildCenteredMessage(context);
    }
    return _buildBubbleMessage(context);
  }

  Widget _buildCenteredMessage(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveStyle = _effectiveStyle == CBMessageStyle.system
        ? CBMessageStyle.system
        : style;
    final isNarrative = effectiveStyle == CBMessageStyle.narrative;
    final accentColor =
        color ?? (isNarrative ? scheme.secondary : scheme.outline);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
          border: isNarrative
              ? Border.all(color: accentColor.withValues(alpha: 0.3))
              : null,
        ),
        child: Text(
          message.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: accentColor,
            letterSpacing: 1.0,
            fontSize: 10,
            fontWeight: isNarrative ? FontWeight.w700 : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBubbleMessage(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accentColor = color ?? scheme.primary;

    // Bubble shape constants
    const radius = Radius.circular(20);
    const smallRadius = Radius.circular(4);

    BorderRadius borderRadius;

    if (isSender) {
      borderRadius = BorderRadius.only(
        topLeft: radius,
        topRight: (groupPosition == CBMessageGroupPosition.top ||
                groupPosition == CBMessageGroupPosition.single)
            ? radius
            : smallRadius,
        bottomLeft: radius,
        bottomRight: (groupPosition == CBMessageGroupPosition.bottom ||
                groupPosition == CBMessageGroupPosition.single)
            ? smallRadius
            : smallRadius, // Sender tail usually bottom right? Actually standard messaging apps smooth the corners between bubbles.
        // Let's adopt standard messaging logic:
        // Top: Top corners round, bottom same-side corner small
        // Middle: Both same-side corners small
        // Bottom: Top same-side corner small, bottom round (and maybe has tail)
      );

      if (groupPosition == CBMessageGroupPosition.top) {
        borderRadius = const BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: radius,
            bottomRight: smallRadius);
      } else if (groupPosition == CBMessageGroupPosition.middle) {
        borderRadius = const BorderRadius.only(
            topLeft: radius,
            topRight: smallRadius,
            bottomLeft: radius,
            bottomRight: smallRadius);
      } else if (groupPosition == CBMessageGroupPosition.bottom) {
        borderRadius = const BorderRadius.only(
            topLeft: radius,
            topRight: smallRadius,
            bottomLeft: radius,
            bottomRight: radius);
      } else {
        // single
        borderRadius = const BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: radius,
            bottomRight: radius);
      }
    } else {
      // Received message (Avatar on left)
      if (groupPosition == CBMessageGroupPosition.top) {
        borderRadius = const BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: smallRadius,
            bottomRight: radius);
      } else if (groupPosition == CBMessageGroupPosition.middle) {
        borderRadius = const BorderRadius.only(
            topLeft: smallRadius,
            topRight: radius,
            bottomLeft: smallRadius,
            bottomRight: radius);
      } else if (groupPosition == CBMessageGroupPosition.bottom) {
        borderRadius = const BorderRadius.only(
            topLeft: smallRadius,
            topRight: radius,
            bottomLeft: radius,
            bottomRight: radius);
      } else {
        // single
        borderRadius = const BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: radius,
            bottomRight: radius);
      }
    }

    final showAvatar = !isSender &&
        (groupPosition == CBMessageGroupPosition.bottom ||
            groupPosition == CBMessageGroupPosition.single);
    final showSenderName = !isSender &&
        sender.isNotEmpty &&
        (groupPosition == CBMessageGroupPosition.top ||
            groupPosition == CBMessageGroupPosition.single);

    return Padding(
      padding: EdgeInsets.only(
          top: (groupPosition == CBMessageGroupPosition.top ||
                  groupPosition == CBMessageGroupPosition.single)
              ? 4
              : 1,
          bottom: (groupPosition == CBMessageGroupPosition.bottom ||
                  groupPosition == CBMessageGroupPosition.single)
              ? 4
              : 1,
          left: 8,
          right: 8),
      child: Row(
        mainAxisAlignment:
            isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender) ...[
            if (showAvatar)
              _buildAvatar(accentColor)
            else
              const SizedBox(width: 32), // Preserve space for alignment
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSenderName)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      sender.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSender
                        ? accentColor.withValues(alpha: 0.2)
                        : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: borderRadius,
                    border: isSender
                        ? Border.all(color: accentColor.withValues(alpha: 0.5))
                        : null,
                  ),
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
                if (groupPosition == CBMessageGroupPosition.bottom ||
                    groupPosition == CBMessageGroupPosition.single)
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                      child: Text(
                        _formatTime(timestamp!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 9,
                        ),
                      ),
                    ),
              ],
            ),
          ),
          if (isSender) ...[
            const SizedBox(width: 8),
            // Host usually doesn't need avatar on right for every message,
            // but if we want it, we can apply similar logic.
            // For now, let's keep it simple and just show it if single/bottom or always?
            // "Advanced messaging" often skips own avatar.
            // The previous implementation showed it. I'll hide it for cleaner look unless single.
            const SizedBox(width: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(Color color) {
    if (avatarAsset == null) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.2),
        child: Icon(Icons.person, size: 16, color: color),
      );
    }
    return CBRoleAvatar(
      assetPath: avatarAsset,
      color: color,
      size: 32,
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}

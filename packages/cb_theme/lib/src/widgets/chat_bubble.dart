import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

enum CBMessageStyle {
  standard,
  system,
  narrative,
  whisper,
}

enum CBMessageGroupPosition {
  single,
  top,
  middle,
  bottom,
}

/// Delivery status for WhatsApp-style ticks on sent messages.
enum CBDeliveryStatus {
  /// No ticks shown (default for received messages).
  none,

  /// Single tick: message sent.
  sent,

  /// Single tick: message delivered to host.
  delivered,

  /// Double tick: message seen/acknowledged by host.
  seen,
}

class CBMessageBubble extends StatelessWidget {
  final String sender;
  final String message;
  final DateTime? timestamp;
  final CBMessageStyle style;
  final Color? color;
  final String? avatarAsset;
  final bool isSender;
  final CBMessageGroupPosition groupPosition;
  final VoidCallback? onAvatarTap;

  /// Delivery status ticks (only rendered for sender messages).
  final CBDeliveryStatus deliveryStatus;

  /// Callback when the bubble is tapped (e.g. to show timestamp details).
  final VoidCallback? onTap;

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
    this.onAvatarTap,
    this.deliveryStatus = CBDeliveryStatus.none,
    this.onTap,
    @Deprecated('Use style: CBMessageStyle.system instead')
    this.isSystemMessage,
  });

  CBMessageStyle get _effectiveStyle =>
      (isSystemMessage ?? false) ? CBMessageStyle.system : style;

  @override
  Widget build(BuildContext context) {
    final bool isSystem = _effectiveStyle == CBMessageStyle.system;
    final bool isNarrative = _effectiveStyle == CBMessageStyle.narrative;

    if (isSystem || isNarrative) {
      return _buildCenteredMessage(context);
    }
    return _buildBubbleMessage(context);
  }

  Widget _buildCenteredMessage(BuildContext context) {
    final effectiveStyle = _effectiveStyle == CBMessageStyle.system
        ? CBMessageStyle.system
        : style;
    final isNarrative = effectiveStyle == CBMessageStyle.narrative;
    final accentColor = color ??
        (isNarrative
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.outline);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(CBRadius.pill),
          border: isNarrative
              ? Border.all(color: accentColor.withValues(alpha: 0.3))
              : null,
        ),
        child: Text(
          message.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
    final accentColor = color ?? Theme.of(context).colorScheme.primary;

    // Bubble shape constants - increased for M3 aesthetic
    const radius = Radius.circular(28);
    const smallRadius = Radius.circular(4);

    BorderRadius borderRadius;

    if (isSender) {
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
        borderRadius = const BorderRadius.all(radius);
      }
    }

    final showAvatar = !isSender &&
        (groupPosition == CBMessageGroupPosition.bottom ||
            groupPosition == CBMessageGroupPosition.single);
    final showSenderName = !isSender &&
        sender.isNotEmpty &&
        (groupPosition == CBMessageGroupPosition.top ||
            groupPosition == CBMessageGroupPosition.single);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
      padding: EdgeInsets.only(
          top: (groupPosition == CBMessageGroupPosition.top ||
                  groupPosition == CBMessageGroupPosition.single)
              ? 8 // Tighter spacing adjustments
              : 2,
          bottom: (groupPosition == CBMessageGroupPosition.bottom ||
                  groupPosition == CBMessageGroupPosition.single)
              ? 8
              : 2,
          left: 16, // Increase horizontal padding for M3
          right: 16),
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
                    padding: const EdgeInsets.only(left: 12, bottom: 2),
                    child: Text(
                      sender,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSender
                        ? Theme.of(context).colorScheme.primaryContainer 
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: borderRadius,
                  ),
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isSender 
                            ? Theme.of(context).colorScheme.onPrimaryContainer 
                            : Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                          fontSize: 16,
                        ),
                  ),
                ),
                if (groupPosition == CBMessageGroupPosition.bottom ||
                    groupPosition == CBMessageGroupPosition.single)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (timestamp != null)
                          Text(
                            _formatTime(timestamp!),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                  fontSize: 9,
                                ),
                          ),
                        if (isSender && deliveryStatus != CBDeliveryStatus.none) ...[
                          const SizedBox(width: 3),
                          _buildDeliveryTicks(context),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isSender) ...[
            const SizedBox(width: 8),
            const SizedBox(width: 32),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildAvatar(Color color) {
    final avatar = avatarAsset == null
        ? CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(Icons.person, size: 16, color: color),
          )
        : CBRoleAvatar(
            assetPath: avatarAsset,
            color: color,
            size: 32,
          );

    if (onAvatarTap != null) {
      return GestureDetector(
        onTap: onAvatarTap,
        child: avatar,
      );
    }
    return avatar;
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildDeliveryTicks(BuildContext context) {
    final tickColor = Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: 0.5);
    const tickSize = 12.0;

    // Sent: bouncing three-dot animation
    if (deliveryStatus == CBDeliveryStatus.sent) {
      return _BouncingDots(color: tickColor, size: 4.0);
    }

    // Seen: double tick ✓✓ in primary color
    if (deliveryStatus == CBDeliveryStatus.seen) {
      final seenColor = Theme.of(context).colorScheme.primary;
      return SizedBox(
        width: tickSize + 4,
        height: tickSize,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: Icon(Icons.check, size: tickSize, color: seenColor),
            ),
            Positioned(
              left: 5,
              child: Icon(Icons.check, size: tickSize, color: seenColor),
            ),
          ],
        ),
      );
    }

    // Delivered: single tick ✓
    return Icon(Icons.check, size: tickSize, color: tickColor);
  }
}

/// Animated bouncing three-dot indicator for "sending..." status.
class _BouncingDots extends StatefulWidget {
  final Color color;
  final double size;

  const _BouncingDots({required this.color, this.size = 4.0});

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 5,
      height: widget.size * 3,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              // Stagger each dot by 0.2 of the animation cycle
              final delay = i * 0.2;
              final t = (_controller.value - delay) % 1.0;
              // Bounce only in the first half of each dot's cycle
              final bounce = t < 0.5
                  ? (-4.0 * widget.size * 0.6) * (1 - (2 * t - 1) * (2 * t - 1))
                  : 0.0;
              return Padding(
                padding: EdgeInsets.only(right: i < 2 ? widget.size * 0.5 : 0),
                child: Transform.translate(
                  offset: Offset(0, bounce),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

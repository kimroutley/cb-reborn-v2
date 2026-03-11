import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';

/// CBChatInput
/// 
/// A persistent bottom input row mimicking the Google Messages input field.
/// Features a left attachment (+) button, a central pill-shaped text field,
/// and trailing actions for media/voice.
class CBChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAddAttachment;
  final bool isRestricted;
  final String restrictedMessage;
  final IconData restrictedIcon;
  final Color? restrictedColor;
  final String hintText;
  final Widget? prefixIcon;

  const CBChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAddAttachment,
    this.isRestricted = false,
    this.restrictedMessage = 'Comms restricted.',
    this.restrictedIcon = Icons.mic_off_rounded,
    this.restrictedColor,
    this.hintText = 'RCS message',
    this.prefixIcon,
  });

  @override
  State<CBChatInput> createState() => _CBChatInputState();
}

class _CBChatInputState extends State<CBChatInput> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rColor = widget.restrictedColor ?? scheme.error;

    if (widget.isRestricted) {
      return Container(
        color: scheme.surface,
        padding: EdgeInsets.only(
          left: CBSpace.x4, 
          right: CBSpace.x4, 
          top: CBSpace.x3,
          bottom: MediaQuery.of(context).padding.bottom + CBSpace.x3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.restrictedIcon, size: 16, color: rColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.restrictedMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: scheme.surface,
      padding: EdgeInsets.only(
        left: CBSpace.x2,
        right: CBSpace.x2,
        top: CBSpace.x2,
        bottom: MediaQuery.of(context).padding.bottom + CBSpace.x2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Add Attachment Button (+)
          IconButton(
            icon: Icon(Icons.add_circle_rounded, color: scheme.onSurfaceVariant, size: 28),
            onPressed: widget.onAddAttachment,
            splashRadius: 24,
          ),
          
          // Pill Text Field
          Expanded(
            child: Container(
              padding: EdgeInsets.only(
                left: widget.prefixIcon != null ? CBSpace.x2 : CBSpace.x4, 
                right: CBSpace.x2,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.prefixIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, right: 8),
                      child: widget.prefixIcon!,
                    ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onSubmitted: (_) => widget.onSend(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: widget.controller,
                      builder: (context, value, child) {
                        final hasText = value.text.trim().isNotEmpty;
                        
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                          child: hasText
                              ? Container(
                                  key: const ValueKey('send_btn'),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: scheme.primary.withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: scheme.primary.withValues(alpha: 0.5),
                                    ),
                                    boxShadow: CBColors.circleGlow(scheme.primary, intensity: 0.3),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.send_rounded, color: scheme.primary, size: 20),
                                    onPressed: widget.onSend,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                  ),
                                )
                              : Container(
                                  key: const ValueKey('mic_btn'),
                                  child: IconButton(
                                    icon: Icon(Icons.mic_none_rounded, color: scheme.onSurfaceVariant, size: 24),
                                    onPressed: null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                  ),
                                ),
                        );
                      },
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

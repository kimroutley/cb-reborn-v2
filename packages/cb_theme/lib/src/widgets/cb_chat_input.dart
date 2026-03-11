import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';

/// CBChatInput
/// 
/// A persistent bottom input row mimicking modern messaging apps (e.g., Google Messages).
/// Features a left attachment (+) button, a central pill-shaped text field,
/// and an embedded or trailing action for sending.
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: widget.isRestricted
          ? _buildRestrictedState(context, theme, scheme, rColor)
          : _buildActiveState(context, theme, scheme),
    );
  }

  Widget _buildRestrictedState(BuildContext context, ThemeData theme, ColorScheme scheme, Color rColor) {
    return Container(
      key: const ValueKey('restricted_input'),
      color: scheme.surface,
      padding: EdgeInsets.only(
        left: CBSpace.x3, 
        right: CBSpace.x3, 
        top: CBSpace.x2,
        bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 4 : CBSpace.x3,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: rColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: rColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.restrictedIcon, size: 18, color: rColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.restrictedMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: rColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveState(BuildContext context, ThemeData theme, ColorScheme scheme) {
    return Container(
      key: const ValueKey('active_input'),
      color: scheme.surface,
      padding: EdgeInsets.only(
        left: CBSpace.x2,
        right: CBSpace.x2,
        top: CBSpace.x2,
        bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 4 : CBSpace.x3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Add Attachment Button (+)
          Padding(
            padding: const EdgeInsets.only(bottom: 1, right: 4), // 1px bottom matches pill's 1px border
            child: IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: scheme.onSurfaceVariant, size: 28),
              onPressed: widget.onAddAttachment,
              splashRadius: 24,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
          
          // Pill Text Field
          Expanded(
            child: Container(
              padding: EdgeInsets.only(
                left: widget.prefixIcon != null ? CBSpace.x2 : CBSpace.x3, 
                right: CBSpace.x1,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(28), // Fully rounded pill
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
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
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                        color: scheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onSubmitted: (_) => widget.onSend(),
                    ),
                  ),
                  
                  // Send/Mic Button Area
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, top: 4, right: 4),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: widget.controller,
                      builder: (context, value, child) {
                        final hasText = value.text.trim().isNotEmpty;
                        
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOutBack,
                          switchOutCurve: Curves.easeInQuint,
                          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                          child: hasText
                              ? Container(
                                  key: const ValueKey('send_btn'),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: scheme.primary,
                                    boxShadow: CBColors.circleGlow(scheme.primary, intensity: 0.4),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.send_rounded, color: scheme.onPrimary, size: 20),
                                    onPressed: widget.onSend,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                    tooltip: 'Send message',
                                  ),
                                )
                              : Container(
                                  key: const ValueKey('mic_btn'),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.mic_none_rounded, color: scheme.onSurfaceVariant, size: 24),
                                    onPressed: null, // Disabled for now, add callback if needed
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

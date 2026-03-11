import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';

/// CBMessagingAppBar
/// 
/// A unified top AppBar designed to instantly mimic a messaging thread header.
/// 
/// Left: Back button arrow and a circular Profile/Group Avatar.
/// Center: Contact Name/Group Title stacked above a subtle member count or status.
/// Right: Action icons matching Google Messages.
class CBMessagingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? avatar;
  final VoidCallback? onAvatarTap;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final Color? backgroundColor;

  const CBMessagingAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.avatar,
    this.onAvatarTap,
    this.actions,
    this.onBackPressed,
    this.showBackButton = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor ?? Colors.transparent,
      leading: showBackButton 
        ? IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
            onPressed: onBackPressed ?? () => Navigator.maybePop(context),
          )
        : null,
      titleSpacing: showBackButton ? 0 : NavigationToolbar.kMiddleSpacing,
      title: InkWell(
        onTap: onAvatarTap,
        borderRadius: BorderRadius.circular(CBRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: CBSpace.x1, horizontal: CBSpace.x1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (avatar != null) ...[
                avatar!,
                const SizedBox(width: CBSpace.x3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

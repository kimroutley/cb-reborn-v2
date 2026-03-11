import 'package:flutter/material.dart';

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
      toolbarHeight: 64, // Taller M3 app bar
      elevation: 0,
      scrolledUnderElevation: 2,
      surfaceTintColor: scheme.primary.withValues(alpha: 0.05),
      shadowColor: scheme.shadow.withValues(alpha: 0.1),
      backgroundColor: backgroundColor ?? scheme.surface,
      leading: showBackButton 
        ? IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
            onPressed: onBackPressed ?? () => Navigator.maybePop(context),
            splashRadius: 24,
          )
        : null,
      titleSpacing: showBackButton ? 0 : 16,
      title: InkWell(
        onTap: onAvatarTap,
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (avatar != null) ...[
                avatar!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800, // Stronger weight for neon aesthetic
                        letterSpacing: -0.5,
                        fontSize: 22, // Larger title for M3
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                          fontSize: 14,
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
  Size get preferredSize => const Size.fromHeight(64.0); // Match new toolbarHeight
}

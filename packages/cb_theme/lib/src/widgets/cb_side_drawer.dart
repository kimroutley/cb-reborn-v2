import 'package:flutter/material.dart';
import 'dart:ui'; // Required for BackdropFilter
import 'package:cb_theme/cb_theme.dart';

/// CBSideDrawer: A shared base widget for consistent side navigation across apps.
/// It provides a glassmorphic-inspired design and handles common theming.
class CBSideDrawer extends StatelessWidget {
  final int? selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget drawerHeader;
  final List<Widget> children;

  const CBSideDrawer({
    super.key,
    this.selectedIndex,
    this.onDestinationSelected,
    required this.drawerHeader,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: CBColors.transparent,
      elevation: 0,
      width: 320,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.25), // Stronger glass base
          border: Border(
            right: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.4), 
              width: 1.5,
            ),
          ),
          boxShadow: CBColors.boxGlow(colorScheme.primary, intensity: 0.15),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0), // Deep M3 Blur
            child: SafeArea(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  drawerHeader,
                  const SizedBox(height: CBSpace.x2),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A standard drawer tile designed for the CB aesthetic, handling selected state
/// and providing glassmorphic/neon hover effects.
class CBDrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const CBDrawerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeColor = color ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CBSpace.x3, vertical: 4),
      child: Material(
        color: CBColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: activeColor.withValues(alpha: 0.1),
          highlightColor: activeColor.withValues(alpha: 0.05),
          child: Container(
            height: 56, // M3 standard height
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.15)
                  : CBColors.transparent,
              borderRadius: BorderRadius.circular(28),
              border: isSelected
                  ? Border.all(
                      color: activeColor.withValues(alpha: 0.4),
                      width: 1.0,
                    )
                  : Border.all(color: Colors.transparent),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: -2,
                      )
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? activeColor
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                  shadows: isSelected
                      ? CBColors.iconGlow(activeColor, intensity: 0.6)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? activeColor
                          : colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.5,
                      shadows: isSelected
                          ? CBColors.textGlow(activeColor, intensity: 0.2)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Common header for the drawer showing app title and role label.
class CBDrawerHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? color;

  const CBDrawerHeader({
    super.key,
    this.title = 'CLUB BLACKOUT',
    required this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeColor = color ?? scheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CBSpace.x6,
        CBSpace.x6,
        CBSpace.x4,
        CBSpace.x4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: activeColor,
              fontWeight: FontWeight.w900,
              fontFamily: 'Orbitron',
              letterSpacing: 1.5,
              shadows: CBColors.textGlow(activeColor, intensity: 0.5),
            ),
          ),
          const SizedBox(height: CBSpace.x1),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

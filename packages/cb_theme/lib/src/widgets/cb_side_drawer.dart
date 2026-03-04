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

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(
            alpha: 0.15), // Subtle transparency for glassmorphism
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.35), // Vibrant neon border
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(CBSpace.x3),
        boxShadow: CBColors.boxGlow(colorScheme.primary, intensity: 0.25), // Neon glow
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CBSpace.x3),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0), // Strong blur effect
          child: NavigationDrawer(
            backgroundColor: CBColors.transparent, // Make NavigationDrawer itself transparent
            indicatorColor: colorScheme.secondary.withValues(alpha: 0.15), // Neon pink indicator tint
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CBSpace.x3),
              side: BorderSide(
                color: colorScheme.secondary.withValues(alpha: 0.5), // Neon highlight for selected item
                width: 1.0,
              ),
            ),
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            children: [
              drawerHeader,
              const SizedBox(height: CBSpace.x2), // Spacing after the header
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

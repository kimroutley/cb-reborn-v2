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

    return ClipRRect(
      borderRadius: BorderRadius.circular(CBSpace.x3), // Rounded corners for the glass effect
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Blur effect
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.1), // Subtle transparency for glassmorphism
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.1), // Light border
            ),
            borderRadius: BorderRadius.circular(CBSpace.x3),
          ),
          child: NavigationDrawer(
            backgroundColor: Colors.transparent, // Make NavigationDrawer itself transparent
            indicatorColor: colorScheme.secondaryContainer.withValues(alpha: 0.7),
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

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

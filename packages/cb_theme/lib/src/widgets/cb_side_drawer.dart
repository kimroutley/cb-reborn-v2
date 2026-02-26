import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';

// ── Data Types ──────────────────────────────────────────────────────────────

sealed class CBDrawerEntry {
  const CBDrawerEntry();
}

class CBDrawerSection extends CBDrawerEntry {
  final String title;
  final IconData? icon;
  const CBDrawerSection({required this.title, this.icon});
}

class CBDrawerDestination extends CBDrawerEntry {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  const CBDrawerDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

// ── Main Drawer ─────────────────────────────────────────────────────────────

class CBSideDrawer extends StatelessWidget {
  final int? selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget drawerHeader;
  final List<CBDrawerEntry> entries;

  const CBSideDrawer({
    super.key,
    this.selectedIndex,
    this.onDestinationSelected,
    required this.drawerHeader,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    int destIdx = -1;
    final tiles = <Widget>[];
    for (final entry in entries) {
      switch (entry) {
        case CBDrawerSection():
          tiles.add(_SectionLabel(title: entry.title, icon: entry.icon));
        case CBDrawerDestination():
          destIdx++;
          final idx = destIdx;
          final selected = idx == selectedIndex;
          tiles.add(_DrawerTile(
            icon: selected ? (entry.selectedIcon ?? entry.icon) : entry.icon,
            label: entry.label,
            isSelected: selected,
            onTap: () => onDestinationSelected?.call(idx),
          ));
      }
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.75),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.08),
                  scheme.surface.withValues(alpha: 0.85),
                  scheme.surface.withValues(alpha: 0.90),
                  scheme.secondary.withValues(alpha: 0.05),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
              border: Border(
                right: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  drawerHeader,
                  _AccentDivider(scheme: scheme),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        scrollbars: false,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        children: tiles,
                      ),
                    ),
                  ),
                  _AccentDivider(scheme: scheme, subtle: true),
                  _DrawerFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Accent Divider ──────────────────────────────────────────────────────────

class _AccentDivider extends StatelessWidget {
  final ColorScheme scheme;
  final bool subtle;
  const _AccentDivider({required this.scheme, this.subtle = false});

  @override
  Widget build(BuildContext context) {
    final alpha = subtle ? 0.25 : 0.5;
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            scheme.primary.withValues(alpha: alpha),
            scheme.secondary.withValues(alpha: alpha),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        boxShadow: subtle
            ? null
            : [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
      ),
    );
  }
}

// ── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData? icon;
  const _SectionLabel({required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: scheme.primary.withValues(alpha: 0.45)),
            const SizedBox(width: 8),
          ],
          Text(
            title.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer Tile ─────────────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = isSelected ? scheme.primary : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: scheme.primary.withValues(alpha: 0.1),
          highlightColor: scheme.primary.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28), // M3 Pill Shape
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? scheme.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: accent,
                  shadows: isSelected
                      ? CBColors.iconGlow(scheme.primary, intensity: 0.5)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      color:
                          isSelected ? scheme.primary : scheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: isSelected ? 0.5 : 0.2,
                      shadows: isSelected
                          ? [
                              Shadow(
                                color: scheme.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ]
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

// ── Footer ──────────────────────────────────────────────────────────────────

class _DrawerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Text(
        'v2.0  ·  CLUB BLACKOUT',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.25),
              letterSpacing: 1.2,
              fontSize: 9,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

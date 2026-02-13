import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import '../screens/games_night_screen.dart';
import '../screens/guides_screen.dart';
import '../screens/home_screen.dart';
import '../screens/lobby_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      backgroundColor: scheme.surfaceContainerLow,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),

          _DrawerTile(
            icon: Icons.home_rounded,
            title: 'Home',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
          _DrawerTile(
            icon: Icons.group_rounded,
            title: 'Club Lobby',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LobbyScreen()),
              );
            },
          ),
          _DrawerTile(
            icon: Icons.menu_book_rounded,
            title: 'Game Bible',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GuidesScreen()),
              );
            },
          ),
          _DrawerTile(
            icon: Icons.wine_bar_rounded,
            title: 'Games Night',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GamesNightScreen(),
                ),
              );
            },
          ),

          Divider(color: scheme.outlineVariant.withValues(alpha: 0.25)),

          // BAR TAB PREVIEW (Visual only stub)
          Padding(
            padding: CBInsets.panel,
            child: Container(
              padding: CBInsets.screen,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(CBRadius.md),
                border: Border.all(
                  color: scheme.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        color: scheme.tertiary,
                        size: 16,
                      ),
                      const SizedBox(width: CBSpace.x2),
                      Text(
                        "YOUR BAR TAB",
                        style: textTheme.labelSmall!.copyWith(
                          color: scheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CBSpace.x3),
                  Text(
                    "0 DRINKS OWED",
                    style: textTheme.headlineSmall!.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    "NO ACTIVE PENALTIES",
                    style: CBTypography.nano.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.35),
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

  Widget _buildDrawerHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return DrawerHeader(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
              color: scheme.primary.withValues(alpha: 0.4), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBRoleAvatar(color: scheme.primary, size: 48, pulsing: true),
          const SizedBox(height: CBSpace.x4),
          Text(
            'CLUB BLACKOUT',
            style: textTheme.headlineMedium!.copyWith(
              color: scheme.onSurface,
              shadows: CBColors.textGlow(scheme.primary, intensity: 0.5),
            ),
          ),
          Text(
            'THE ULTIMATE SOCIAL DECEPTION',
            style: CBTypography.nano.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.35),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading:
          Icon(icon, color: scheme.primary.withValues(alpha: 0.75), size: 20),
      title: Text(
        title.toUpperCase(),
        style: textTheme.labelSmall!.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.85),
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
}

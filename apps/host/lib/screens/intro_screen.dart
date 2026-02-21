import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'host_navigation_shell.dart';

class HostIntroScreen extends StatefulWidget {
  const HostIntroScreen({super.key});

  @override
  State<HostIntroScreen> createState() => _HostIntroScreenState();
}

class _HostIntroScreenState extends State<HostIntroScreen> {
  bool _loading = true;
  bool _seen = false;

  @override
  void initState() {
    super.initState();
    _checkIntro();
  }

  Future<void> _checkIntro() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('host_intro_seen') ?? false;
    if (mounted) {
      setState(() {
        _seen = seen;
        _loading = false;
      });
    }
  }

  Future<void> _enterClub() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('host_intro_seen', true);
    if (mounted) {
      setState(() {
        _seen = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CBPrismScaffold(
        title: '',
        showAppBar: false,
        body: Center(child: CBBreathingLoader()),
      );
    }

    if (_seen) {
      return const HostNavigationShell();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return CBPrismScaffold(
      title: '',
      showAppBar: false,
      body: CBNeonBackground(
        showOverlay: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 80,
                  color: scheme.primary,
                  shadows: CBColors.iconGlow(scheme.primary),
                ),
                const SizedBox(height: 32),
                Text(
                  'COMMAND THE NIGHT',
                  textAlign: TextAlign.center,
                  style: textTheme.displayMedium!.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: CBColors.textGlow(scheme.primary, intensity: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'CLUB BLACKOUT REBORN',
                  style: textTheme.labelLarge!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: 48),
                CBPanel(
                  borderColor: scheme.primary.withValues(alpha: 0.5),
                  child: Column(
                    children: [
                      Text(
                        'YOU ARE THE HOST. THE DIRECTOR. THE GOD OF THIS CLUB.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge!.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Manage roles, trigger narrative events, and control the chaos from your dashboard. Keep the party alive... or watch it burn.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                CBPrimaryButton(
                  label: 'ENTER THE CLUB',
                  icon: Icons.login_rounded,
                  onPressed: _enterClub,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


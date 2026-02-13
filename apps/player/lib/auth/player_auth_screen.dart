import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_theme/cb_theme.dart';
import 'auth_provider.dart';

class PlayerAuthScreen extends ConsumerWidget {
  const PlayerAuthScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'CLUB BLACKOUT',
      showAppBar: false,
      showBackgroundRadiance: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _buildUIForState(context, ref, authState, scheme),
      ),
    );
  }

  Widget _buildUIForState(BuildContext context, WidgetRef ref,
      AuthState authState, ColorScheme scheme) {
    switch (authState.status) {
      case AuthStatus.needsProfile:
        return _ProfileSetupForm(key: const ValueKey('profile'));
      case AuthStatus.loading:
        return Center(
          key: const ValueKey('loading'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CBBreathingSpinner(),
              const SizedBox(height: 24),
              Text(
                'SYNCING BIOMETRICS...',
                style: CBTypography.labelSmall.copyWith(
                  color: scheme.primary,
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.bold,
                  shadows: CBColors.textGlow(scheme.primary),
                ),
              ),
            ],
          ),
        );
      case AuthStatus.error:
        return _AuthSplash(
          key: const ValueKey('auth_error'),
          errorMessage: authState.error,
        );
      case AuthStatus.authenticated:
        return child;
      default:
        return const _AuthSplash(key: ValueKey('auth_splash'));
    }
  }
}

class _AuthSplash extends ConsumerWidget {
  final String? errorMessage;

  const _AuthSplash({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(authProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Column(
        children: [
          // ── CINEMATIC LOGO ──
          CBFadeSlide(
            key: const ValueKey('auth_logo'),
            beginOffset: const Offset(0, -0.1),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Hero(
                tag: 'auth_icon',
                child: CBRoleAvatar(
                  color: scheme.primary,
                  size: 80,
                  pulsing: true,
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // ── HYPE / BLURB SECTION ──
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: Column(
              children: [
                Text(
                  'CLUB BLACKOUT',
                  style: textTheme.displaySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    shadows: CBColors.textGlow(scheme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PATRON ACCESS GRANTED',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.secondary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'A neon-drenched social deduction experience. Step into the VIP lounge where shadows move, alliances shift, and survival is the only currency that matters.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 64),

          // ── LOGIN SECTION ──
          CBFadeSlide(
            delay: const Duration(milliseconds: 400),
            child: CBGlassTile(
              title: 'ENTRY PROTOCOL',
              accentColor: scheme.primary,
              isPrismatic: true,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Scan your biometric ID to enter the club.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Enhanced Google Button
                  _buildGoogleButton(context, notifier, scheme),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: scheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.gpp_bad_rounded,
                              color: scheme.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'IDENTIFICATION FAILED: ${errorMessage!.toUpperCase()}',
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.error,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 64),
          Text(
            'PATRON-NET v4.0.8 - SECURED BY BLACKOUT',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.15),
              fontSize: 9,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton(
      BuildContext context, AuthNotifier notifier, ColorScheme scheme) {
    return InkWell(
      onTap: () {
        HapticService.heavy();
        notifier.signInWithGoogle();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.1),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
              height: 22,
              errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.account_circle_outlined,
                  color: scheme.primary,
                  size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              'SYNC VIA GOOGLE',
              style: CBTypography.bodyBold.copyWith(
                letterSpacing: 2.0,
                fontSize: 13,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSetupForm extends ConsumerWidget {
  const _ProfileSetupForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(authProvider.notifier);
    final authState = ref.watch(authProvider);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Hero(
              tag: 'auth_icon',
              child:
                  Icon(Icons.badge_rounded, color: scheme.secondary, size: 80),
            ),
            const SizedBox(height: 32),
            Text(
              'IDENTITY REGISTRATION',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                color: scheme.secondary,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: CBColors.textGlow(scheme.secondary),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose your moniker. This name will be visible to everyone in the club.',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 64),
            CBGlassTile(
              title: 'REGISTER MONIKER',
              accentColor: scheme.secondary,
              isPrismatic: true,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CBTextField(
                    controller: notifier.usernameController,
                    hintText: 'YOUR NICKNAME',
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.person_outline, color: scheme.secondary),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CBPrimaryButton(
                    label: 'ENTER THE CLUB',
                    backgroundColor: scheme.secondary,
                    onPressed: () {
                      HapticService.heavy();
                      notifier.saveUsername();
                    },
                  ),
                  const SizedBox(height: 16),
                  CBGhostButton(
                    label: 'CANCEL ENTRY',
                    onPressed: () => notifier.signOut(),
                    color: scheme.error,
                  ),
                  if (authState.error != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      authState.error!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: scheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

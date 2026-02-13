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
      title: '', // No AppBar title for immersive feel
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
              const CBBreathingSpinner(size: 64),
              const SizedBox(height: 32),
              Text(
                'CHECKING GUEST LIST...',
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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── CINEMATIC LOGO ──
            CBFadeSlide(
              key: const ValueKey('auth_logo'),
              beginOffset: const Offset(0, -0.1),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.2),
                      scheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                  border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.2),
                      blurRadius: 40,
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
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [scheme.primary, scheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'CLUB BLACKOUT',
                      textAlign: TextAlign.center,
                      style: textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        height: 0.9,
                        color: Colors.white, // Masked
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'MEMBERS ONLY',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "Tonight is the night. The music is loud, the lights are low, and everyone has a secret.\n\nCan you survive until the lights come on?",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.8),
                        height: 1.6,
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
                title: 'GUEST LIST CHECK',
                accentColor: scheme.secondary, // Contrast color
                isPrismatic: true,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Show your invite to the Bouncer.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Enhanced Google Button
                    _buildGoogleButton(context, notifier, scheme),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: scheme.error.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.gpp_bad_rounded,
                                color: scheme.error, size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'ACCESS DENIED: ${errorMessage!.toUpperCase()}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.error,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
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

            const SizedBox(height: 48),
            Text(
              'SECURED BY BLACKOUT-NET',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.2),
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.login, color: scheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              'SHOW VIP PASS (GOOGLE)',
              style: CBTypography.bodyBold.copyWith(
                letterSpacing: 1.5,
                fontSize: 14,
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
              'PRINT YOUR ID CARD',
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
              'What do they call you on the dance floor?',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 64),
            CBGlassTile(
              title: 'NEW PATRON REGISTRATION',
              accentColor: scheme.secondary,
              isPrismatic: true,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CBTextField(
                    controller: notifier.usernameController,
                    hintText: 'YOUR MONIKER',
                    autofocus: true,
                    textStyle: textTheme.headlineSmall!
                        .copyWith(color: scheme.onSurface),
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.person_outline, color: scheme.secondary),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CBPrimaryButton(
                    label: 'PAY COVER CHARGE & ENTER',
                    backgroundColor: scheme.secondary,
                    onPressed: () {
                      HapticService.heavy();
                      notifier.saveUsername();
                    },
                  ),
                  const SizedBox(height: 16),
                  CBGhostButton(
                    label: 'WALK AWAY',
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

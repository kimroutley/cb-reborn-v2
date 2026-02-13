import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cb_theme/cb_theme.dart';

import 'auth_provider.dart';

class HostAuthScreen extends ConsumerWidget {
  const HostAuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'HOST COMMAND',
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
      case AuthStatus.error:
        return _AuthSplash(
          key: const ValueKey('auth_error'),
          errorMessage: authState.error,
        );
      case AuthStatus.loading:
        return Center(
          key: const ValueKey('loading'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CBBreathingSpinner(),
              const SizedBox(height: 24),
              Text(
                'VERIFYING BIOMETRICS...',
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
      case AuthStatus.linkSent:
        return const _LinkSentMessage(key: ValueKey('link_sent'));
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
    final currentLink = Uri.base.toString();
    final isSignInLink =
        FirebaseAuth.instance.isSignInWithEmailLink(currentLink);

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
                child: Icon(
                  Icons.terminal_rounded,
                  color: scheme.primary,
                  size: 80,
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
                  'HOST COMMAND',
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
                    'ARCHITECT PROTOCOL ACTIVE',
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
                    'Welcome, Architect. You are about to orchestrate a night of neon-drenched deception. Control the pulse of the club, manage the chaos, and ensure the House always wins.',
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

          // ── AUTH PANEL ──
          CBFadeSlide(
            delay: const Duration(milliseconds: 400),
            child: CBGlassTile(
              title: 'ESTABLISH TERMINAL LINK',
              accentColor: scheme.primary,
              isPrismatic: true,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Identify yourself to assume command.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Enhanced Google Button
                  _buildGoogleButton(context, notifier, scheme),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              color: scheme.onSurface.withValues(alpha: 0.1))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'SECURE FALLBACK',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.3),
                            fontSize: 8,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Expanded(
                          child: Divider(
                              color: scheme.onSurface.withValues(alpha: 0.1))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Email Field
                  CBTextField(
                    controller: notifier.emailController,
                    hintText: 'REGISTERED EMAIL',
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.alternate_email_rounded,
                          size: 18, color: scheme.primary.withValues(alpha: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CBPrimaryButton(
                    label: 'SEND ACCESS LINK',
                    onPressed: () => notifier.sendSignInLink(),
                  ),

                  if (isSignInLink) ...[
                    const SizedBox(height: 12),
                    CBGhostButton(
                      label: 'COMPLETE OPEN LINK',
                      color: scheme.tertiary,
                      onPressed: () => notifier.completeSignInFromCurrentLink(),
                    ),
                  ],

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
                              'ACCESS DENIED: ${errorMessage!.toUpperCase()}',
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
            'TERMINAL v4.0.8 - ENCRYPTED VIA BLACKOUT-NET',
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

class _LinkSentMessage extends ConsumerWidget {
  const _LinkSentMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(authProvider.notifier);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.tertiary.withValues(alpha: 0.1),
                border: Border.all(
                    color: scheme.tertiary.withValues(alpha: 0.5), width: 2),
              ),
              child: Icon(Icons.mark_email_read_rounded,
                  color: scheme.tertiary, size: 64),
            ),
            const SizedBox(height: 48),
            Text(
              'LINK DISPATCHED',
              style: textTheme.headlineMedium?.copyWith(
                color: scheme.tertiary,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Check your encrypted inbox. Opening the link will grant you full terminal access.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 64),
            CBGhostButton(
              label: 'USE DIFFERENT CREDENTIALS',
              onPressed: () => notifier.reset(),
            )
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
              'Establish your moniker for the House files.',
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
                    hintText: 'HOST NICKNAME',
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person_pin_rounded,
                          color: scheme.secondary),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CBPrimaryButton(
                    label: 'SAVE & ENTER COMMAND',
                    backgroundColor: scheme.secondary,
                    onPressed: () {
                      HapticService.heavy();
                      notifier.saveUsername();
                    },
                  ),
                  const SizedBox(height: 16),
                  CBGhostButton(
                    label: 'ABORT ACCESS',
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

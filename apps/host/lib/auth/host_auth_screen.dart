import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cb_comms/cb_comms.dart';
import 'package:cb_theme/cb_theme.dart';

import 'auth_provider.dart';

class HostAuthScreen extends ConsumerWidget {
  const HostAuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CBNeonBackground(
        showRadiance: true,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _buildUIForState(context, ref, authState, scheme),
        ),
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
              const CBBreathingSpinner(size: 64),
              const SizedBox(height: 32),
              Text(
                'VERIFYING SECURITY CLEARANCE...',
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
                      scheme.primary.withValues(alpha: 0.1),
                      scheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                  border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 5,
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
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'CLUB MANAGEMENT',
                      textAlign: TextAlign.center,
                      style: textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        height: 0.9,
                        color: Colors.white,
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
                      'ARCHITECT PROTOCOL',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.tertiary,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'You run this town. Control the music, the lights, and the fate of everyone on the floor.\n\nKeep the party alive... or shut it down.',
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

            // ── AUTH PANEL ──
            CBFadeSlide(
              delay: const Duration(milliseconds: 400),
              child: CBPanel(
                borderColor: scheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Manager clearance required.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Enhanced Google Button
                    _buildGoogleButton(context, notifier, scheme),

                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color:
                                    scheme.onSurface.withValues(alpha: 0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'MANUAL OVERRIDE',
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        Expanded(
                            child: Divider(
                                color:
                                    scheme.onSurface.withValues(alpha: 0.1))),
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
                            size: 20,
                            color: scheme.primary.withValues(alpha: 0.5)),
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
                        onPressed: () =>
                            notifier.completeSignInFromCurrentLink(),
                      ),
                    ],

                    if (errorMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: scheme.error.withValues(alpha: 0.3)),
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
              'ENCRYPTED VIA BLACKOUT-NET',
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
          border: Border.all(color: scheme.primary.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.account_circle_outlined,
                  color: scheme.primary,
                  size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              'SCAN MANAGER BADGE (GOOGLE)',
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
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.tertiary.withValues(alpha: 0.1),
                border: Border.all(
                    color: scheme.tertiary.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: scheme.tertiary.withValues(alpha: 0.2),
                    blurRadius: 30,
                  ),
                ],
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
                color: scheme.onSurface.withValues(alpha: 0.8),
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

class _ProfileSetupForm extends ConsumerStatefulWidget {
  const _ProfileSetupForm({super.key});

  @override
  ConsumerState<_ProfileSetupForm> createState() => _ProfileSetupFormState();
}

class _ProfileSetupFormState extends ConsumerState<_ProfileSetupForm> {
  late final TextEditingController _publicPlayerIdController;
  late String _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _publicPlayerIdController = TextEditingController();
    _selectedAvatar = clubAvatarEmojis.first;
  }

  @override
  void dispose() {
    _publicPlayerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(authProvider.notifier);
    final authState = ref.watch(authProvider);
    final avatarChoices = clubAvatarEmojis.take(20).toList(growable: false);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Hero(
              tag: 'auth_icon',
              child:
                  Icon(Icons.badge_rounded, color: scheme.secondary, size: 100),
            ),
            const SizedBox(height: 48),
            Text(
              'ISSUE MANAGER LICENSE',
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
              'Name on the office door. Make it official.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 64),
            CBPanel(
              borderColor: scheme.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CBTextField(
                    controller: notifier.usernameController,
                    hintText: 'MANAGER NAME',
                    autofocus: true,
                    textStyle: textTheme.headlineSmall!
                        .copyWith(color: scheme.onSurface),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person_pin_rounded,
                          color: scheme.secondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CBTextField(
                    controller: _publicPlayerIdController,
                    hintText: 'PUBLIC PLAYER ID (OPTIONAL)',
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.alternate_email_rounded,
                          color: scheme.secondary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CHOOSE AVATAR',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.secondary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: avatarChoices.map((emoji) {
                      final selected = emoji == _selectedAvatar;
                      return _AvatarEmojiChip(
                        emoji: emoji,
                        selected: selected,
                        onTap: () => setState(() => _selectedAvatar = emoji),
                      );
                    }).toList(growable: false),
                  ),
                  const SizedBox(height: 32),
                  CBPrimaryButton(
                    label: 'UNLOCK OFFICE',
                    backgroundColor: scheme.secondary,
                    onPressed: () {
                      HapticService.heavy();
                      notifier.saveUsername(
                        publicPlayerId: _publicPlayerIdController.text.trim(),
                        avatarEmoji: _selectedAvatar,
                      );
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

class _AvatarEmojiChip extends StatelessWidget {
  const _AvatarEmojiChip({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? scheme.secondary.withValues(alpha: 0.22)
              : scheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? scheme.secondary
                : scheme.outline.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

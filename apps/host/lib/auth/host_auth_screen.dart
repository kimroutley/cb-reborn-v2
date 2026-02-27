import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cb_comms/cb_comms.dart';
import 'package:cb_theme/cb_theme.dart';

import 'auth_provider.dart';

class HostAuthScreen extends ConsumerWidget {
  const HostAuthScreen({super.key, this.onSignedIn, this.isEmbedded = false});

  final VoidCallback? onSignedIn;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        onSignedIn?.call();
      }
    });

    final body = AnimatedSwitcher(
      duration: CBMotion.transition,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _buildUIForState(context, ref, authState, scheme),
    );

    if (isEmbedded) return body;

    return CBPrismScaffold(
      title: 'Club Management Login',
      showAppBar: false,
      showBackgroundRadiance: true,
      body: body,
    );
  }

  Widget _buildUIForState(BuildContext context, WidgetRef ref,
      AuthState authState, ColorScheme scheme) {
    switch (authState.status) {
      case AuthStatus.authenticated:
        if (!isEmbedded && Navigator.of(context).canPop()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
        return const _AuthSplash(key: ValueKey('auth_authenticated'));
      case AuthStatus.needsProfile:
        return const _ProfileSetupForm(key: ValueKey('profile'));
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

class _AuthSplash extends ConsumerStatefulWidget {
  final String? errorMessage;

  const _AuthSplash({super.key, this.errorMessage});

  @override
  ConsumerState<_AuthSplash> createState() => _AuthSplashState();
}

class _AuthSplashState extends ConsumerState<_AuthSplash> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isCreatingAccount = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignIn(AuthNotifier notifier) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    if (_isCreatingAccount) {
      if (password != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Passwords do not match.')));
        return;
      }
      await notifier.createAccountWithEmailPassword(email, password);
    } else {
      await notifier.signInWithEmailPassword(email, password);
    }
  }

  Future<void> _handleForgotPassword(AuthNotifier notifier) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter your email first.')));
      return;
    }
    final sent = await notifier.sendPasswordReset(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sent
              ? 'Password reset email sent.'
              : 'Could not send reset email.')));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        color: scheme.onSurface,
                        shadows: CBColors.textGlow(scheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: CBSpace.x4),
                  CBBadge(
                    text: 'ARCHITECT PROTOCOL',
                    color: scheme.tertiary,
                  ),
                  const SizedBox(height: CBSpace.x8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4),
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

            const SizedBox(height: CBSpace.x16),

            // ── AUTH PANEL ──
            CBFadeSlide(
              delay: const Duration(milliseconds: 400),
              child: CBPanel(
                borderColor: scheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SYSTEM STATUS: ENCRYPTED.\nACCESS CLEARANCE REQUIRED.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: CBSpace.x6),

                    // Google Button
                    CBGlassTile(
                      onTap: () {
                        HapticService.heavy();
                        notifier.signInWithGoogle();
                      },
                      borderColor: scheme.primary,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: CBSpace.x4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google_logo.png',
                              height: 24,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.g_mobiledata,
                                  color: CBColors.onSurface,
                                  size: 28),
                            ),
                            const SizedBox(width: CBSpace.x4),
                            Text(
                              'SCAN MANAGER BADGE (GOOGLE)',
                              style: textTheme.titleMedium?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                shadows: CBColors.textGlow(scheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: CBSpace.x8),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color:
                                    scheme.onSurface.withValues(alpha: 0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: CBSpace.x4),
                          child: Text(
                            'OR EMAIL',
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
                    const SizedBox(height: CBSpace.x6),

                    // Email + Password Fields
                    CBTextField(
                      controller: _emailController,
                      hintText: 'EMAIL',
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.alternate_email_rounded,
                            size: 20,
                            color: scheme.primary.withValues(alpha: 0.5)),
                      ),
                    ),
                    const SizedBox(height: CBSpace.x3),
                    CBTextField(
                      controller: _passwordController,
                      hintText: 'PASSWORD',
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock_rounded,
                            size: 20,
                            color: scheme.primary.withValues(alpha: 0.5)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: scheme.onSurface.withValues(alpha: 0.4),
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                    ),
                    if (_isCreatingAccount) ...[
                      const SizedBox(height: CBSpace.x3),
                      CBTextField(
                        controller: _confirmPasswordController,
                        hintText: 'CONFIRM PASSWORD',
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline_rounded,
                              size: 20,
                              color: scheme.primary.withValues(alpha: 0.5)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: scheme.onSurface.withValues(alpha: 0.4),
                              size: 18,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        obscureText: _obscureConfirm,
                      ),
                    ],
                    const SizedBox(height: CBSpace.x4),

                    CBPrimaryButton(
                      label: _isCreatingAccount
                          ? 'CREATE ACCOUNT'
                          : 'SIGN IN',
                      icon: _isCreatingAccount
                          ? Icons.how_to_reg_rounded
                          : Icons.login_rounded,
                      onPressed: () => _handleEmailSignIn(notifier),
                    ),
                    const SizedBox(height: CBSpace.x3),

                    // Toggle create/sign-in + forgot password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => setState(
                              () => _isCreatingAccount = !_isCreatingAccount),
                          child: Text(
                            _isCreatingAccount
                                ? 'ALREADY HAVE AN ACCOUNT?'
                                : 'CREATE ACCOUNT',
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.primary.withValues(alpha: 0.7),
                              fontSize: 9,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        if (!_isCreatingAccount)
                          TextButton(
                            onPressed: () =>
                                _handleForgotPassword(notifier),
                            child: Text(
                              'FORGOT PASSWORD?',
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 9,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                      ],
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

                    if (widget.errorMessage != null) ...[
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
                                'ACCESS DENIED: ${widget.errorMessage!.toUpperCase()}',
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
        padding: const EdgeInsets.all(CBSpace.x8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(CBSpace.x8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.tertiary.withValues(alpha: 0.1),
                border: Border.all(
                    color: scheme.tertiary.withValues(alpha: 0.5), width: 2),
                boxShadow: CBColors.circleGlow(scheme.tertiary),
              ),
              child: Icon(Icons.mark_email_read_rounded,
                  color: scheme.tertiary, size: 64),
            ),
            const SizedBox(height: CBSpace.x12),
            Text(
              'LINK DISPATCHED',
              style: textTheme.headlineMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                shadows: CBColors.textGlow(scheme.tertiary),
              ),
            ),
            const SizedBox(height: CBSpace.x6),
            Text(
              'Check your encrypted inbox. Opening the link will grant you full terminal access.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: CBSpace.x16),
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
              child: CBBadge(
                text: 'MANAGER CLEARANCE',
                color: scheme.secondary,
              ),
            ),
            const SizedBox(height: CBSpace.x6),
            Text(
              'ISSUE MANAGER LICENSE',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: CBColors.textGlow(scheme.secondary),
              ),
            ),
            const SizedBox(height: CBSpace.x3),
            Text(
              'The name on the office door. Make it official.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: CBSpace.x12),
            CBPanel(
              borderColor: scheme.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'PERSONAL IDENTIFICATION',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: CBSpace.x4),
                  CBTextField(
                    controller: notifier.usernameController,
                    hintText: 'LEGAL ALIAS',
                    autofocus: true,
                    textStyle: textTheme.headlineSmall!
                        .copyWith(color: scheme.onSurface),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person_pin_rounded,
                          color: scheme.secondary.withValues(alpha: 0.5)),
                    ),
                  ),
                  const SizedBox(height: CBSpace.x4),
                  CBTextField(
                    controller: _publicPlayerIdController,
                    hintText: 'PUBLIC PLAYER ID (OPTIONAL)',
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.alternate_email_rounded,
                          color: scheme.secondary.withValues(alpha: 0.5)),
                    ),
                  ),
                  const SizedBox(height: CBSpace.x8),
                  Text(
                    'DIGITAL REPRESENTATION',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: CBSpace.x4),
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
                  const SizedBox(height: CBSpace.x8),
                  CBPrimaryButton(
                    label: 'ACTIVATE PROTOCOL',
                    backgroundColor: scheme.secondary,
                    onPressed: () {
                      HapticService.heavy();
                      notifier.saveUsername(
                        publicPlayerId: _publicPlayerIdController.text.trim(),
                        avatarEmoji: _selectedAvatar,
                      );
                    },
                  ),
                  const SizedBox(height: CBSpace.x4),
                  CBGhostButton(
                    label: 'ABORT ACCESS',
                    onPressed: () => notifier.signOut(),
                    color: scheme.error,
                  ),
                  if (authState.error != null) ...[
                    const SizedBox(height: CBSpace.x4),
                    Text(
                      'STATION ERROR: ${authState.error!.toUpperCase()}',
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          boxShadow: selected ? CBColors.boxGlow(scheme.secondary) : null,
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}

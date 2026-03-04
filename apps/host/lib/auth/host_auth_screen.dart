import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cb_comms/cb_comms.dart';
import 'package:cb_theme/cb_theme.dart';

import 'auth_provider.dart';

class HostAuthScreen extends ConsumerWidget {
  const HostAuthScreen({super.key, this.isEmbedded = false, this.onSignedIn});

  final bool isEmbedded;
  final VoidCallback? onSignedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        onSignedIn?.call();
      }
    });

    return CBPrismScaffold(
      title: 'SECURITY GATE',
      showAppBar: !isEmbedded,
      showBackgroundRadiance: true,
      body: AnimatedSwitcher(
        duration: CBMotion.transition,
        switchInCurve: CBMotion.emphasizedCurve,
        switchOutCurve: CBMotion.emphasizedCurve,
        child: _buildUIForState(context, ref, authState, scheme),
      ),
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
              const SizedBox(height: CBSpace.x8),
              Text(
                'VERIFYING SECURITY CLEARANCE...',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.w900,
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
        padding: const EdgeInsets.symmetric(horizontal: CBSpace.x6, vertical: CBSpace.x12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── CINEMATIC LOGO ──
            CBFadeSlide(
              key: const ValueKey('auth_logo'),
              beginOffset: const Offset(0, -0.1),
              child: Container(
                padding: const EdgeInsets.all(CBSpace.x8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.1),
                      scheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                  border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.4), width: 2),
                  boxShadow: CBColors.circleGlow(scheme.primary, intensity: 0.4),
                ),
                child: Hero(
                  tag: 'host_auth_icon',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(CBRadius.md),
                    child: Image.asset(
                      'assets/images/neon_x_brand.png',
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: CBSpace.x12),

            // ── HYPE / BLURB SECTION ──
            CBFadeSlide(
              delay: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  Text(
                    'COMMAND THE NIGHT',
                    textAlign: TextAlign.center,
                    style: textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      height: 0.9,
                      color: scheme.onSurface,
                      shadows: CBColors.textGlow(scheme.primary, intensity: 0.6),
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
                      'YOU RUN THIS TOWN. CONTROL THE MUSIC, THE LIGHTS, AND THE FATE OF EVERYONE ON THE FLOOR.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                        height: 1.6,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
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
                borderColor: scheme.primary.withValues(alpha: 0.5),
                padding: CBInsets.panel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'MANAGER CLEARANCE REQUIRED',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: CBSpace.x6),

                    // Enhanced Google Button
                    CBPrimaryButton(
                      label: 'SCAN MANAGER BADGE',
                      icon: Icons.account_circle_outlined,
                      onPressed: () {
                        HapticService.heavy();
                        notifier.signInWithGoogle();
                      },
                    ),

                    const SizedBox(height: CBSpace.x8),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color:
                                    scheme.onSurface.withValues(alpha: 0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4),
                          child: Text(
                            'MANUAL OVERRIDE',
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.3),
                              fontSize: 9,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w900,
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

                    // Email Field
                    CBTextField(
                      controller: notifier.emailController,
                      hintText: 'REGISTERED EMAIL',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.alternate_email_rounded,
                      monospace: true,
                    ),
                    const SizedBox(height: CBSpace.x4),
                    CBGhostButton(
                      label: 'SEND ACCESS LINK',
                      icon: Icons.send_rounded,
                      onPressed: () {
                        HapticService.medium();
                        notifier.sendSignInLink();
                      },
                    ),

                    if (isSignInLink) ...[
                      const SizedBox(height: CBSpace.x3),
                      CBPrimaryButton(
                        label: 'COMPLETE AUTHENTICATION',
                        backgroundColor: scheme.tertiary,
                        onPressed: () {
                          HapticService.heavy();
                          notifier.completeSignInFromCurrentLink();
                        },
                      ),
                    ],

                    if (errorMessage != null) ...[
                      const SizedBox(height: CBSpace.x6),
                      CBGlassTile(
                        borderColor: scheme.error.withValues(alpha: 0.5),
                        padding: CBInsets.screen,
                        child: Row(
                          children: [
                            Icon(Icons.gpp_bad_rounded,
                                color: scheme.error, size: 24),
                            const SizedBox(width: CBSpace.x4),
                            Expanded(
                              child: Text(
                                'ACCESS DENIED: ${errorMessage!.toUpperCase()}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.error,
                                  fontWeight: FontWeight.w900,
                                  height: 1.4,
                                  letterSpacing: 0.5,
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

            const SizedBox(height: CBSpace.x12),
            Text(
              'ENCRYPTED VIA BLACKOUT-NET',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.2),
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
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
            CBFadeSlide(
              child: Container(
                padding: const EdgeInsets.all(CBSpace.x8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.tertiary.withValues(alpha: 0.1),
                  border: Border.all(
                      color: scheme.tertiary.withValues(alpha: 0.5), width: 2),
                  boxShadow: CBColors.circleGlow(scheme.tertiary, intensity: 0.4),
                ),
                child: Icon(Icons.mark_email_read_rounded,
                    color: scheme.tertiary, size: 64),
              ),
            ),
            const SizedBox(height: CBSpace.x12),
            CBFadeSlide(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'LINK DISPATCHED',
                style: textTheme.headlineMedium?.copyWith(
                  color: scheme.tertiary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: CBColors.textGlow(scheme.tertiary),
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x6),
            CBFadeSlide(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'CHECK YOUR ENCRYPTED INBOX. OPENING THE LINK WILL GRANT YOU FULL TERMINAL ACCESS.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x16),
            CBFadeSlide(
              delay: const Duration(milliseconds: 300),
              child: CBGhostButton(
                label: 'USE DIFFERENT CREDENTIALS',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  HapticService.light();
                  notifier.reset();
                },
              ),
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
        padding: const EdgeInsets.all(CBSpace.x8),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            CBFadeSlide(
              child: Hero(
                tag: 'host_auth_icon',
                child: Container(
                  padding: CBInsets.panel,
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.secondary.withValues(alpha: 0.4), width: 2),
                    boxShadow: CBColors.circleGlow(scheme.secondary, intensity: 0.3),
                  ),
                  child: Icon(Icons.badge_rounded, color: scheme.secondary, size: 64),
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x10),
            CBFadeSlide(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'ISSUE MANAGER LICENSE',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: CBColors.textGlow(scheme.secondary),
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x3),
            CBFadeSlide(
              delay: const Duration(milliseconds: 150),
              child: Text(
                'NAME ON THE OFFICE DOOR. MAKE IT OFFICIAL.',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x12),
            CBFadeSlide(
              delay: const Duration(milliseconds: 200),
              child: CBPanel(
                borderColor: scheme.secondary.withValues(alpha: 0.5),
                padding: CBInsets.panel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CBTextField(
                      controller: notifier.usernameController,
                      hintText: 'MANAGER NAME',
                      autofocus: true,
                      prefixIcon: Icons.person_pin_rounded,
                    ),
                    const SizedBox(height: CBSpace.x4),
                    CBTextField(
                      controller: _publicPlayerIdController,
                      hintText: 'PUBLIC PLAYER ID (OPTIONAL)',
                      prefixIcon: Icons.alternate_email_rounded,
                      monospace: true,
                    ),
                    const SizedBox(height: CBSpace.x6),
                    Text(
                      'CHOOSE AVATAR',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.secondary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: CBSpace.x3),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: avatarChoices.map((emoji) {
                        final selected = emoji == _selectedAvatar;
                        return CBProfileAvatarChip(
                          emoji: emoji,
                          selected: selected,
                          enabled: authState.status != AuthStatus.loading,
                          onTap: () {
                            HapticService.selection();
                            setState(() => _selectedAvatar = emoji);
                          },
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: CBSpace.x8),
                    CBPrimaryButton(
                      label: authState.status == AuthStatus.loading
                          ? 'ENCRYPTING...'
                          : 'UNLOCK OFFICE',
                      backgroundColor: scheme.secondary,
                      onPressed: authState.status == AuthStatus.loading
                          ? null
                          : () {
                              HapticService.heavy();
                              notifier.saveUsername(
                                publicPlayerId: _publicPlayerIdController.text.trim(),
                                avatarEmoji: _selectedAvatar,
                              );
                            },
                    ),
                    const SizedBox(height: CBSpace.x3),
                    CBGhostButton(
                      label: 'ABORT ACCESS',
                      onPressed: () {
                        HapticService.light();
                        notifier.signOut();
                      },
                      color: scheme.error,
                    ),
                    if (authState.error != null) ...[
                      const SizedBox(height: CBSpace.x5),
                      Text(
                        authState.error!.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: textTheme.labelSmall?.copyWith(color: scheme.error, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CBProfileAvatarChip extends StatelessWidget {
  const CBProfileAvatarChip({
    super.key,
    required this.emoji,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(CBRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: CBSpace.x3, vertical: CBSpace.x2),
        decoration: BoxDecoration(
          color: selected
              ? scheme.secondary.withValues(alpha: 0.22)
              : scheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(CBRadius.pill),
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

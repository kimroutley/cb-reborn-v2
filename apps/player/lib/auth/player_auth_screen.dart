import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_comms/cb_comms_player.dart';
import 'package:cb_theme/cb_theme.dart';
import 'auth_provider.dart';
import '../player_destinations.dart';
import '../player_navigation.dart';

class PlayerAuthScreen extends ConsumerWidget {
  const PlayerAuthScreen({super.key, this.onSignedIn, this.isEmbedded = false});

  final VoidCallback? onSignedIn;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        onSignedIn?.call();
      }
    });

    final loadingTitle = authState.user == null
        ? 'VERIFYING VIP PASS...'
        : 'SYNCING PLAYER PROFILE...';
    final loadingSubtitle = authState.user == null
        ? 'Please wait while we validate your invite.'
        : 'Preparing your identity and restoring session state.';

    return CBPrismScaffold(
      title: '',
      showAppBar: false,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: CBMotion.transition,
            switchInCurve: CBMotion.emphasizedCurve,
            switchOutCurve: CBMotion.emphasizedCurve,
            child: _buildUIForState(context, ref, authState, scheme),
          ),
          if (isLoading)
            _AuthLoadingDialog(
              title: loadingTitle,
              subtitle: loadingSubtitle,
            ),
        ],
      ),
    );
  }

  Widget _buildUIForState(BuildContext context, WidgetRef ref,
      AuthState authState, ColorScheme scheme) {
    switch (authState.status) {
      case AuthStatus.initial:
        return const _AuthBootScreen(key: ValueKey('auth_boot'));
      case AuthStatus.needsProfile:
        return _ProfileSetupForm(key: const ValueKey('profile'));
      case AuthStatus.loading:
        return authState.user != null
            ? const _AuthBootScreen(key: ValueKey('auth_boot_loading'))
            : _AuthSplash(key: const ValueKey('auth_splash_loading'));
      case AuthStatus.error:
        return _AuthSplash(
          key: const ValueKey('auth_error'),
          errorMessage: authState.error,
        );
      case AuthStatus.authenticated:
        return Container();
      default:
        return const _AuthSplash(key: ValueKey('auth_splash'));
    }
  }
}

class _AuthBootScreen extends StatelessWidget {
  const _AuthBootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: CBPanel(
        borderColor: scheme.primary.withValues(alpha: 0.45),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CBBreathingLoader(size: 50),
            const SizedBox(height: CBSpace.x4),
            Text(
              'SYNCING SESSION...',
              textAlign: TextAlign.center,
              style: textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                shadows: CBColors.textGlow(scheme.primary, intensity: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthLoadingDialog extends StatelessWidget {
  const _AuthLoadingDialog({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AbsorbPointer(
      absorbing: true,
      child: Container(
        color: scheme.scrim.withValues(alpha: 0.6),
        alignment: Alignment.center,
        padding: CBInsets.panel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: CBPanel(
            borderColor: scheme.primary.withValues(alpha: 0.45),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CBBreathingLoader(size: 56),
                const SizedBox(height: CBSpace.x5),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge!.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: CBColors.textGlow(scheme.primary, intensity: 0.4),
                  ),
                ),
                const SizedBox(height: CBSpace.x2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.8),
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
                      scheme.primary.withValues(alpha: 0.2),
                      scheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                  border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.5), width: 2),
                  boxShadow: CBColors.circleGlow(scheme.primary, intensity: 0.4),
                ),
                child: Hero(
                  tag: 'auth_icon',
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
                        color: scheme.onSurface, // Masked by ShaderMask
                        shadows: CBColors.textGlow(scheme.primary, intensity: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: CBSpace.x4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: 6),
                    decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(CBRadius.pill),
                        border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.3))),
                    child: Text(
                      'MEMBERS ONLY',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: CBSpace.x8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4),
                    child: Text(
                      "TONIGHT IS THE NIGHT. THE MUSIC IS LOUD, THE LIGHTS ARE LOW, AND EVERYONE HAS A SECRET.\n\nCAN YOU SURVIVE UNTIL THE LIGHTS COME ON?",
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

            // ── LOGIN SECTION ──
            CBFadeSlide(
              delay: const Duration(milliseconds: 400),
              child: CBPanel(
                borderColor: scheme.primary.withValues(alpha: 0.5),
                padding: CBInsets.panel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'GUEST LIST CHECK',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: CBColors.textGlow(scheme.primary, intensity: 0.4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: CBSpace.x2),
                    Text(
                      'SHOW YOUR INVITE TO THE BOUNCER.',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: CBSpace.x8),

                    // Enhanced Google Button
                    _buildGoogleButton(context, notifier, scheme),

                    const SizedBox(height: CBSpace.x6),

                    // Just Browsing CTA
                    TextButton(
                      onPressed: () {
                        HapticService.selection();
                        ref.read(playerNavigationProvider.notifier).setDestination(PlayerDestination.guides);
                      },
                      child: Column(
                        children: [
                          Text(
                            'JUST BROWSING?',
                            style: textTheme.labelLarge?.copyWith(
                              color: scheme.secondary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Read the Blackbook',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

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
              'SECURED BY BLACKOUT-NET',
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

  Widget _buildGoogleButton(
      BuildContext context, AuthNotifier notifier, ColorScheme scheme) {
    return InkWell(
      onTap: () {
        HapticService.heavy();
        notifier.signInWithGoogle();
      },
      borderRadius: BorderRadius.circular(CBRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: CBSpace.x5),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(CBRadius.md),
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
            const SizedBox(width: CBSpace.x4),
            Text(
              'SHOW VIP PASS (GOOGLE)',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    letterSpacing: 1.5,
                    fontSize: 14,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
            ),
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
    final isLoading = authState.status == AuthStatus.loading;
    final avatarChoices = clubAvatarEmojis.take(20).toList(growable: false);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CBSpace.x8),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            CBFadeSlide(
              child: Hero(
                tag: 'auth_icon',
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
            const SizedBox(height: CBSpace.x8),
            CBFadeSlide(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'PRINT YOUR ID CARD',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: CBColors.textGlow(scheme.secondary, intensity: 0.6),
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x3),
            CBFadeSlide(
              delay: const Duration(milliseconds: 150),
              child: Text(
                'WHAT DO THEY CALL YOU ON THE DANCE FLOOR?',
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
                    Text(
                      'NEW PATRON REGISTRATION',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: CBColors.textGlow(scheme.secondary, intensity: 0.4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: CBSpace.x6),
                    CBTextField(
                      controller: notifier.usernameController,
                      hintText: 'YOUR MONIKER',
                      autofocus: true,
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: CBSpace.x4),
                    CBTextField(
                      controller: _publicPlayerIdController,
                      hintText: 'PUBLIC PLAYER ID (OPTIONAL)',
                      prefixIcon: Icons.alternate_email_rounded,
                      monospace: true,
                    ),
                    const SizedBox(height: CBSpace.x8),
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
                      spacing: CBSpace.x3,
                      runSpacing: CBSpace.x3,
                      alignment: WrapAlignment.center,
                      children: avatarChoices.map((emoji) {
                        final selected = emoji == _selectedAvatar;
                        return CBProfileAvatarChip(
                          emoji: emoji,
                          selected: selected,
                          onTap: () {
                            HapticService.selection();
                            setState(() => _selectedAvatar = emoji);
                          },
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: CBSpace.x10),
                    CBPrimaryButton(
                      label: isLoading
                          ? 'SETTING UP...'
                          : 'PAY COVER CHARGE & ENTER',
                      backgroundColor: scheme.secondary,
                      onPressed: isLoading
                          ? null
                          : () {
                              HapticService.heavy();
                              notifier.saveUsername(
                                publicPlayerId:
                                    _publicPlayerIdController.text.trim(),
                                avatarEmoji: _selectedAvatar,
                              );
                            },
                    ),
                    const SizedBox(height: CBSpace.x4),
                    CBGhostButton(
                      label: 'WALK AWAY',
                      onPressed: isLoading ? null : () {
                        HapticService.light();
                        notifier.signOut();
                      },
                    ),
                    if (authState.error != null) ...[
                      const SizedBox(height: CBSpace.x5),
                      Text(
                        authState.error!.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w800,
                        ),
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

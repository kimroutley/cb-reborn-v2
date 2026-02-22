import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_comms/cb_comms_player.dart';
import 'package:cb_theme/cb_theme.dart';
import 'auth_provider.dart';

class PlayerAuthScreen extends ConsumerWidget {
  const PlayerAuthScreen({super.key, this.onSignedIn});

  final VoidCallback? onSignedIn;

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

    return Scaffold(
      body: Stack(
        children: [
          CBNeonBackground(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildUIForState(context, ref, authState, scheme),
            ),
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
            const SizedBox(height: 16),
            Text(
              'SYNCING SESSION...',
              textAlign: TextAlign.center,
              style: textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
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
        color: Colors.black.withValues(alpha: 0.58),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: CBPanel(
            borderColor: scheme.primary.withValues(alpha: 0.45),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CBBreathingLoader(size: 56),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge!.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
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
                      scheme.primary.withAlpha(51),
                      scheme.primary.withAlpha(0),
                    ],
                  ),
                  border: Border.all(
                      color: scheme.primary.withAlpha(128), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withAlpha(51),
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
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "Tonight is the night. The music is loud, the lights are low, and everyone has a secret.\n\nCan you survive until the lights come on?",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
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
              child: CBPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'GUEST LIST CHECK',
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Show your invite to the Bouncer.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withAlpha(153),
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
                            color: scheme.error.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: scheme.error.withAlpha(102))),
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
                color: scheme.onSurface.withAlpha(51),
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
        HapticFeedback.heavyImpact();
        notifier.signInWithGoogle();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: scheme.surface.withAlpha(204),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withAlpha(153)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withAlpha(38),
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
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    letterSpacing: 1.5,
                    fontSize: 14,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.bold,
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
                shadows: [
                  BoxShadow(
                    color: scheme.secondary.withAlpha(128),
                    blurRadius: 24,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'What do they call you on the dance floor?',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withAlpha(179),
              ),
            ),
            const SizedBox(height: 64),
            CBPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'NEW PATRON REGISTRATION',
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
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
                    label: isLoading
                        ? 'SETTING UP...'
                        : 'PAY COVER CHARGE & ENTER',
                    onPressed: isLoading
                        ? null
                        : () {
                            HapticFeedback.heavyImpact();
                            notifier.saveUsername(
                              publicPlayerId:
                                  _publicPlayerIdController.text.trim(),
                              avatarEmoji: _selectedAvatar,
                            );
                          },
                  ),
                  const SizedBox(height: 16),
                  CBTextButton(
                    label: 'WALK AWAY',
                    onPressed: isLoading ? null : () => notifier.signOut(),
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

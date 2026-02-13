import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return CBPrismScaffold(
      title: "",
      showAppBar: false,
      body: Stack(
        children: [
          // ── ATMOSPHERIC BACKGROUND ──
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/backgrounds/club_silhouette.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── BRANDING & HYPE ──
                  CBFadeSlide(
                    key: const ValueKey('login_hype'),
                    child: Column(
                      children: [
                        CBRoleAvatar(
                          color: scheme.secondary,
                          size: 80,
                          pulsing: true,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'CLUB BLACKOUT',
                          style: textTheme.displayMedium!.copyWith(
                            color: scheme.primary,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w900,
                            shadows: CBColors.textGlow(scheme.primary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'THE ULTIMATE SOCIAL DECEPTION',
                          style: textTheme.labelSmall!.copyWith(
                            color: scheme.secondary,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── INTRO PANEL ──
                  CBFadeSlide(
                    key: const ValueKey('login_intro'),
                    delay: const Duration(milliseconds: 200),
                    child: CBPanel(
                      borderColor: scheme.primary.withValues(alpha: 0.4),
                      child: Column(
                        children: [
                          Text(
                            "\"THE CLUB IS VIBRATING. THE MUSIC IS LOUD. SOMEONE JUST DIED IN THE VIP LOUNGE. ARE YOU A PARTY ANIMAL, OR ARE YOU THE ONE WITH THE KNIFE?\"",
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium!.copyWith(
                              fontStyle: FontStyle.italic,
                              color: scheme.onSurface.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "WELCOME TO THE DIRTY NIGHT OUT YOU'LL NEVER REMEMBER.",
                            textAlign: TextAlign.center,
                            style: textTheme.labelSmall!.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── LOGIN FORM ──
                  CBFadeSlide(
                    key: const ValueKey('login_form'),
                    delay: const Duration(milliseconds: 400),
                    child: Column(
                      children: [
                        CBTextField(
                          controller: _emailController,
                          hintText: "EMAIL ADDRESS",
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email_outlined,
                                color: scheme.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        CBTextField(
                          controller: _passwordController,
                          hintText: "PASSWORD",
                          decoration: InputDecoration(
                            prefixIcon:
                                Icon(Icons.lock_outline, color: scheme.primary),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_isLoading)
                          const CBBreathingSpinner()
                        else
                          CBPrimaryButton(
                            label: "ENTER THE BLACKOUT",
                            onPressed: () {
                              setState(() => _isLoading = true);
                              HapticService.heavy();
                              // Simulation: wait and then navigate
                              Future.delayed(const Duration(seconds: 2), () {
                                if (!mounted) return;
                                Navigator.of(context)
                                    .pushReplacementNamed('/home');
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── RECOVERY / SIGNUP ──
                  CBFadeSlide(
                    key: const ValueKey('login_footer'),
                    delay: const Duration(milliseconds: 600),
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        "FORGOT YOUR ALIBI? (RESET PASSWORD)",
                        style: textTheme.labelSmall!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          letterSpacing: 1.0,
                        ),
                      ),
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
}

import 'package:cb_player/auth/auth_provider.dart';
import 'package:cb_comms/cb_comms_player.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../active_bridge.dart';
import '../player_onboarding_provider.dart';
import '../widgets/custom_drawer.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  static const int _minimumPlayersHintThreshold = 4;

  final TextEditingController _nameController = TextEditingController();
  bool _savingName = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final seenGuide = prefs.getBool('player_guide_seen') ?? false;
        if (!seenGuide && mounted) {
          await _showPlayerGuideDialog(context);
          await prefs.setBool('player_guide_seen', true);
        }
      }
    });
  }

  Future<void> _showPlayerGuideDialog(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showThemedDialog(
      context: context,
      accentColor: scheme.secondary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'WELCOME, PATRON',
            style: textTheme.headlineSmall!.copyWith(
              color: scheme.secondary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              shadows: CBColors.textGlow(scheme.secondary),
            ),
          ),
          const SizedBox(height: 24),
          _buildGuideRow(
            context,
            Icons.chat_bubble_outline_rounded,
            'STAY INFORMED',
            'Watch the feed for game events, narrative clues, and voting results.',
          ),
          const SizedBox(height: 16),
          _buildGuideRow(
            context,
            Icons.fingerprint_rounded,
            'YOUR IDENTITY',
            'When the game starts, hold your identity card to reveal your secret role.',
          ),
          const SizedBox(height: 16),
          _buildGuideRow(
            context,
            Icons.menu_rounded,
            'THE BLACKBOOK',
            'Check the side menu for role guides and game rules at any time.',
          ),
          const SizedBox(height: 32),
          CBPrimaryButton(
            label: 'ACKNOWLEDGED',
            backgroundColor: scheme.secondary.withValues(alpha: 0.2),
            foregroundColor: scheme.secondary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.secondary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final candidate = _nameController.text.trim();
    if (candidate.length < 3) {
      _showSnack('Username must be at least 3 characters.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Sign in required to update your username.');
      return;
    }

    setState(() => _savingName = true);
    try {
      final repository = ProfileRepository(
        firestore: FirebaseFirestore.instance,
      );
      final isAvailable = await repository.isUsernameAvailable(
        candidate,
        excludingUid: user.uid,
      );

      if (!isAvailable) {
        _showSnack('Username is already taken.');
        return;
      }

      await repository.upsertBasicProfile(
        uid: user.uid,
        username: candidate,
        email: user.email,
        isHost: false,
      );

      try {
        await user.updateDisplayName(candidate);
      } catch (_) {
        // Keep profile write even if display-name update fails.
      }

      _showSnack('Username updated for your account.');
    } catch (_) {
      _showSnack('Could not update username right now.');
    } finally {
      if (mounted) {
        setState(() => _savingName = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    showThemedSnackBar(
      context,
      message,
      accentColor: Theme.of(context).colorScheme.tertiary,
    );
  }

  ({String title, String detail, _LobbyStatusTone tone}) _buildLobbyStatus({
    required int playerCount,
    required bool awaitingStartConfirmation,
    required String phase,
  }) {
    if (awaitingStartConfirmation) {
      return (
        title: 'READY TO JOIN',
        detail: 'Host started the game. Confirm your join now.',
        tone: _LobbyStatusTone.readyToJoin,
      );
    }

    if (playerCount < _minimumPlayersHintThreshold) {
      return (
        title: 'WAITING FOR MORE PLAYERS',
        detail:
            'Need at least $_minimumPlayersHintThreshold players for a full session.',
        tone: _LobbyStatusTone.waitingPlayers,
      );
    }

    if (phase == 'setup') {
      return (
        title: 'WAITING FOR HOST TO ASSIGN YOU A ROLE',
        detail: 'Role cards are being assigned. Stay ready.',
        tone: _LobbyStatusTone.setup,
      );
    }

    return (
      title: 'WAITING FOR HOST TO START',
      detail: 'Review the Game Bible in the side drawer while you wait.',
      tone: _LobbyStatusTone.waitingHost,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final gameState = ref.watch(activeBridgeProvider).state;
    final authState = ref.watch(authProvider);
    final onboarding = ref.watch(playerOnboardingProvider);

    final preferredName = gameState.myPlayerSnapshot?.name.trim();
    final profileName = authState.user?.displayName?.trim();
    if (_nameController.text.trim().isEmpty) {
      final initial = (preferredName != null && preferredName.isNotEmpty)
          ? preferredName
          : profileName;
      if (initial != null && initial.isNotEmpty) {
        _nameController.text = initial;
      }
    }

    final status = _buildLobbyStatus(
      playerCount: gameState.players.length,
      awaitingStartConfirmation: onboarding.awaitingStartConfirmation,
      phase: gameState.phase,
    );

    final (statusIcon, statusColor) = switch (status.tone) {
      _LobbyStatusTone.readyToJoin => (Icons.flash_on_rounded, scheme.tertiary),
      _LobbyStatusTone.waitingPlayers => (
        Icons.groups_rounded,
        scheme.secondary,
      ),
      _LobbyStatusTone.setup => (Icons.badge_rounded, scheme.primary),
      _LobbyStatusTone.waitingHost => (
        Icons.hourglass_top_rounded,
        scheme.onSurfaceVariant,
      ),
    };

    return CBPrismScaffold(
      title: 'LOBBY',
      drawer: const CustomDrawer(),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        children: [
          // ── SYSTEM: CONNECTED ──
          CBMessageBubble(
            sender: 'SYSTEM',
            message: "SECURE CONNECTION ESTABLISHED",
            style: CBMessageStyle.system,
          ),

          // ── WELCOME MESSAGE ──
          CBMessageBubble(
            sender: 'CLUB MANAGER',
            message:
                "Welcome to Club Blackout. You're on the list. Find a seat and wait for the music to drop.",
            color: scheme.secondary,
          ),

          // ── PLAYER STATUS ──
          if (gameState.myPlayerSnapshot != null)
            CBMessageBubble(
              sender: 'RESULT',
              message:
                  "IDENTIFIED AS: ${gameState.myPlayerSnapshot!.name.toUpperCase()}",
              style: CBMessageStyle.system,
            ),

          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CBPanel(
              borderColor: scheme.primary.withValues(alpha: 0.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROFILE HANDLE',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CBTextField(
                    controller: _nameController,
                    hintText: 'Enter username',
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CBPrimaryButton(
                      label: _savingName ? 'SAVING...' : 'SAVE USERNAME',
                      onPressed: _savingName ? null : _saveUsername,
                      fullWidth: false,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── ROSTER FEED ──
          CBMessageBubble(
            sender: 'SYSTEM',
            message: "PATRONS ENTERING: ${gameState.players.length}",
            style: CBMessageStyle.system,
          ),

          ...gameState.players.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            final isMe = p.id == gameState.myPlayerId;
            return CBFadeSlide(
              key: ValueKey('lobby_join_${p.id}'),
              delay: Duration(milliseconds: 24 * idx.clamp(0, 10)),
              child: CBMessageBubble(
                sender: 'SECURITY',
                message: "${p.name.toUpperCase()} has entered the lounge.",
                color: isMe ? scheme.primary : scheme.tertiary,
              ),
            );
          }),

          const SizedBox(height: 16),

          CBPanel(
            borderColor: statusColor.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, size: 18, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      'LOBBY STATUS',
                      style: textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    const CBBreathingLoader(size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Text(
                    status.title,
                    key: ValueKey(status.title),
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    status.detail,
                    key: ValueKey(status.detail),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

enum _LobbyStatusTone { waitingPlayers, waitingHost, setup, readyToJoin }

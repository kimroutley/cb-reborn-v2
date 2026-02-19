import 'package:cb_player/auth/auth_provider.dart';
import 'package:cb_comms/cb_comms_player.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final repository =
          ProfileRepository(firestore: FirebaseFirestore.instance);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  ({String title, String detail}) _buildLobbyStatus({
    required int playerCount,
    required bool awaitingStartConfirmation,
    required String phase,
  }) {
    if (awaitingStartConfirmation) {
      return (
        title: 'READY TO JOIN',
        detail: 'Host started the game. Confirm your join now.',
      );
    }

    if (playerCount < _minimumPlayersHintThreshold) {
      return (
        title: 'WAITING FOR MORE PLAYERS',
        detail:
            'Need at least $_minimumPlayersHintThreshold players for a full session.',
      );
    }

    if (phase == 'setup') {
      return (
        title: 'WAITING FOR HOST TO ASSIGN YOU A ROLE',
        detail: 'Role cards are being assigned. Stay ready.',
      );
    }

    return (
      title: 'WAITING FOR HOST TO START',
      detail: 'Review the Game Bible in the side drawer while you wait.',
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

    return CBPrismScaffold(
      title: 'LOBBY',
      drawer: const CustomDrawer(),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.9),
          border: Border(
            top: BorderSide(
              color: scheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CBBreathingLoader(size: 32),
              const SizedBox(height: 20),
              Text(
                status.title,
                textAlign: TextAlign.center,
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                status.detail,
                textAlign: TextAlign.center,
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 8,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        children: [
          // ── SYSTEM: CONNECTED ──
          CBMessageBubble(
            sender: 'SYSTEM',
            message: "SECURE CONNECTION ESTABLISHED",
            isSystemMessage: true,
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
              isSystemMessage: true,
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
            isSystemMessage: true,
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

          // ── SPACING FOR LOADING ──
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

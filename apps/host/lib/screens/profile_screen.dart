import 'package:cb_comms/cb_comms.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/custom_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _publicIdController = TextEditingController();

  late final ProfileRepository _repository =
      ProfileRepository(firestore: FirebaseFirestore.instance);

  bool _loadingProfile = true;
  bool _saving = false;
  String? _usernameError;
  String? _publicIdError;
  String _selectedAvatar = clubAvatarEmojis.first;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _publicIdController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _user;
    if (user == null) {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
      return;
    }

    try {
      final profile = await _repository.loadProfile(user.uid);
      if (!mounted) {
        return;
      }

      final username =
          (profile?['username'] as String?)?.trim() ?? user.displayName?.trim();
      final publicId = (profile?['publicPlayerId'] as String?)?.trim();
      final avatar = (profile?['avatarEmoji'] as String?)?.trim();

      _usernameController.text = username ?? '';
      _publicIdController.text = publicId ?? '';
      _selectedAvatar = clubAvatarEmojis.contains(avatar)
          ? avatar!
          : clubAvatarEmojis.first;
    } catch (_) {
      // Ignore load failure and keep editable defaults.
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = _user;
    if (user == null) {
      _showSnack('Sign in required to edit your profile.');
      return;
    }

    final username = _usernameController.text.trim();
    final publicId = _publicIdController.text.trim();

    if (username.length < 3) {
      setState(() {
        _usernameError = 'Username must be at least 3 characters.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _usernameError = null;
      _publicIdError = null;
    });

    try {
      final usernameAvailable = await _repository.isUsernameAvailable(
        username,
        excludingUid: user.uid,
      );
      if (!usernameAvailable) {
        setState(() {
          _usernameError = 'That username is already in use.';
        });
        return;
      }

      if (publicId.isNotEmpty) {
        final publicIdAvailable = await _repository.isPublicPlayerIdAvailable(
          publicId,
          excludingUid: user.uid,
        );
        if (!publicIdAvailable) {
          setState(() {
            _publicIdError = 'That public player ID is already in use.';
          });
          return;
        }
      }

      await _repository.upsertBasicProfile(
        uid: user.uid,
        username: username,
        email: user.email,
        isHost: true,
        publicPlayerId: publicId.isEmpty ? null : publicId,
        avatarEmoji: _selectedAvatar,
      );

      try {
        await user.updateDisplayName(username);
      } catch (_) {
        // Keep profile write even if display-name update fails.
      }

      _showSnack('Profile saved.');
    } catch (_) {
      _showSnack('Could not save profile right now.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = _user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: const CustomDrawer(),
      body: CBNeonBackground(
        child: SafeArea(
          child: _loadingProfile
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: CBInsets.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CBSectionHeader(
                        title: 'HOST PROFILE',
                        icon: Icons.badge_outlined,
                        color: scheme.primary,
                      ),
                      const SizedBox(height: CBSpace.x4),
                      CBPanel(
                        borderColor: scheme.primary.withValues(alpha: 0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACCOUNT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: CBSpace.x3),
                            _ReadonlyRow(label: 'UID', value: user?.uid ?? 'N/A'),
                            const SizedBox(height: CBSpace.x2),
                            _ReadonlyRow(
                              label: 'EMAIL',
                              value: user?.email ?? 'No email on account',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: CBSpace.x4),
                      CBPanel(
                        borderColor: scheme.secondary.withValues(alpha: 0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PUBLIC PROFILE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.secondary,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: CBSpace.x3),
                            CBTextField(
                              controller: _usernameController,
                              textCapitalization: TextCapitalization.words,
                              errorText: _usernameError,
                              decoration: const InputDecoration(
                                labelText: 'Username *',
                                hintText: 'At least 3 characters',
                              ),
                            ),
                            const SizedBox(height: CBSpace.x3),
                            CBTextField(
                              controller: _publicIdController,
                              errorText: _publicIdError,
                              decoration: const InputDecoration(
                                labelText: 'Public Player ID (optional)',
                                hintText: 'e.g. night_fox',
                              ),
                            ),
                            const SizedBox(height: CBSpace.x4),
                            Text(
                              'AVATAR EMOJI',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.tertiary,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: CBSpace.x2),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: clubAvatarEmojis.map((emoji) {
                                final selected = emoji == _selectedAvatar;
                                return _AvatarChip(
                                  emoji: emoji,
                                  selected: selected,
                                  onTap: () {
                                    setState(() => _selectedAvatar = emoji);
                                  },
                                );
                              }).toList(growable: false),
                            ),
                            const SizedBox(height: CBSpace.x5),
                            CBPrimaryButton(
                              label: _saving ? 'Saving...' : 'Save Profile',
                              icon: Icons.save_outlined,
                              onPressed: _saving || user == null ? null : _saveProfile,
                            ),
                          ],
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

class _ReadonlyRow extends StatelessWidget {
  const _ReadonlyRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _AvatarChip extends StatelessWidget {
  const _AvatarChip({
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.22)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.5),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

import 'package:cb_comms/cb_comms_player.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile_edit_guard.dart';
import '../widgets/profile_action_buttons.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

enum _FeedbackTone { info, success, error }

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const List<String> _preferredStyles = <String>[
    'auto',
    'neon',
    'glass',
    'minimal',
    'retro',
  ];

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _publicIdController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _publicIdFocusNode = FocusNode();

  late final ProfileRepository _repository =
      ProfileRepository(firestore: FirebaseFirestore.instance);

  bool _loadingProfile = true;
  bool _saving = false;
  bool _allowImmediatePop = false;
  String? _usernameError;
  String? _publicIdError;
  String _selectedAvatar = clubAvatarEmojis.first;
  String _selectedPreferredStyle = _preferredStyles.first;
  String _initialUsername = '';
  String _initialPublicId = '';
  String _initialAvatar = clubAvatarEmojis.first;
  String _initialPreferredStyle = _preferredStyles.first;
  DateTime? _createdAt;
  DateTime? _updatedAt;

  User? get _user => FirebaseAuth.instance.currentUser;

  bool get _hasChanges {
    return _usernameController.text.trim() != _initialUsername ||
        ProfileFormValidation.sanitizePublicPlayerId(
                _publicIdController.text) !=
            _initialPublicId ||
        _selectedAvatar != _initialAvatar ||
        _selectedPreferredStyle != _initialPreferredStyle;
  }

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onInputChanged);
    _publicIdController.addListener(_onInputChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    ref.read(playerProfileDirtyProvider.notifier).reset();
    _usernameController.removeListener(_onInputChanged);
    _publicIdController.removeListener(_onInputChanged);
    _usernameController.dispose();
    _publicIdController.dispose();
    _usernameFocusNode.dispose();
    _publicIdFocusNode.dispose();
    super.dispose();
  }

  void _syncDirtyFlag() {
    ref.read(playerProfileDirtyProvider.notifier).setDirty(_hasChanges);
  }

  void _onInputChanged() {
    _normalizePublicIdField();
    if (!mounted) {
      return;
    }
    if (_usernameError != null || _publicIdError != null) {
      setState(() {
        _usernameError = null;
        _publicIdError = null;
      });
      _syncDirtyFlag();
      return;
    }
    setState(() {});
    _syncDirtyFlag();
  }

  void _normalizePublicIdField() {
    final normalized =
        ProfileFormValidation.sanitizePublicPlayerId(_publicIdController.text);
    if (_publicIdController.text == normalized) {
      return;
    }
    _publicIdController.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }

  Future<void> _handleAttemptPop() async {
    if (!_hasChanges) {
      return;
    }
    final discard = await _confirmDiscardChanges();
    if (!discard || !mounted) {
      return;
    }
    ref.read(playerProfileDirtyProvider.notifier).reset();
    setState(() => _allowImmediatePop = true);
    Navigator.of(context).maybePop();
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasChanges) {
      return true;
    }
    final decision = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
            'You have unsaved profile edits. Leave without saving?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
    return decision ?? false;
  }

  void _captureInitialSnapshot() {
    _initialUsername = _usernameController.text.trim();
    _initialPublicId =
        ProfileFormValidation.sanitizePublicPlayerId(_publicIdController.text);
    _initialAvatar = _selectedAvatar;
    _initialPreferredStyle = _selectedPreferredStyle;
    _syncDirtyFlag();
  }

  DateTime? _dateFromFirestore(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Unknown';
    }
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _styleLabel(String value) {
    if (value == 'auto') {
      return 'Auto';
    }
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _loadProfile() async {
    final user = _user;
    if (user == null) {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
      _syncDirtyFlag();
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
      final preferredStyle = (profile?['preferredStyle'] as String?)?.trim();

      _usernameController.text = username ?? '';
      _publicIdController.text = publicId == null
          ? ''
          : ProfileFormValidation.sanitizePublicPlayerId(publicId);
      _selectedAvatar =
          clubAvatarEmojis.contains(avatar) ? avatar! : clubAvatarEmojis.first;
      _selectedPreferredStyle =
          _preferredStyles.contains(preferredStyle?.toLowerCase())
              ? preferredStyle!.toLowerCase()
              : _preferredStyles.first;
      _createdAt = _dateFromFirestore(profile?['createdAt']);
      _updatedAt = _dateFromFirestore(profile?['updatedAt']);
      _captureInitialSnapshot();
    } catch (_) {
      // Ignore load failure and keep editable defaults.
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
      _syncDirtyFlag();
    }
  }

  Future<void> _saveProfile() async {
    final user = _user;
    if (user == null) {
      _showFeedback(
        'Sign in required to edit your profile.',
        tone: _FeedbackTone.error,
      );
      return;
    }

    if (!_hasChanges) {
      _showFeedback('No profile changes to save.');
      return;
    }

    final username = _usernameController.text.trim();
    final usernameValidation = ProfileFormValidation.validateUsername(username);
    final rawPublicId = _publicIdController.text;
    final normalizedPublicId =
        ProfileFormValidation.sanitizePublicPlayerId(rawPublicId);
    final publicIdValidation =
        ProfileFormValidation.validatePublicPlayerId(rawPublicId);

    if (usernameValidation != null || publicIdValidation != null) {
      setState(() {
        _usernameError = usernameValidation;
        _publicIdError = publicIdValidation;
      });
      _syncDirtyFlag();
      return;
    }

    setState(() {
      _saving = true;
      _usernameError = null;
      _publicIdError = null;
    });

    try {
      if (username != _initialUsername) {
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
      }

      if (normalizedPublicId.isNotEmpty &&
          normalizedPublicId != _initialPublicId) {
        final publicIdAvailable = await _repository.isPublicPlayerIdAvailable(
          normalizedPublicId,
          excludingUid: user.uid,
        );
        if (!publicIdAvailable) {
          setState(() {
            _publicIdError = 'That public player ID is already in use.';
          });
          return;
        }
      }

      final preferredStyleToSave =
          _selectedPreferredStyle == 'auto' ? null : _selectedPreferredStyle;

      await _repository.upsertBasicProfile(
        uid: user.uid,
        username: username,
        email: user.email,
        isHost: false,
        publicPlayerId: normalizedPublicId.isEmpty ? null : normalizedPublicId,
        avatarEmoji: _selectedAvatar,
        preferredStyle: preferredStyleToSave,
      );

      try {
        await user.updateDisplayName(username);
      } catch (_) {
        // Keep profile write even if display-name update fails.
      }

      setState(() {
        _updatedAt = DateTime.now();
      });
      _captureInitialSnapshot();
      _showFeedback('Profile saved.', tone: _FeedbackTone.success);
    } catch (_) {
      _showFeedback(
        'Could not save profile right now.',
        tone: _FeedbackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
      _syncDirtyFlag();
    }
  }

  void _discardChanges() {
    _usernameController.text = _initialUsername;
    _publicIdController.text = _initialPublicId;
    setState(() {
      _selectedAvatar = _initialAvatar;
      _selectedPreferredStyle = _initialPreferredStyle;
      _usernameError = null;
      _publicIdError = null;
    });
    _syncDirtyFlag();
  }

  void _showFeedback(String message,
      {_FeedbackTone tone = _FeedbackTone.info}) {
    if (!mounted) {
      return;
    }
    final scheme = Theme.of(context).colorScheme;
    final (Color iconColor, IconData icon) = switch (tone) {
      _FeedbackTone.success => (scheme.primary, Icons.check_circle_outline),
      _FeedbackTone.error => (scheme.error, Icons.error_outline),
      _FeedbackTone.info => (scheme.secondary, Icons.info_outline),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: iconColor.withValues(alpha: 0.65),
            ),
          ),
          content: Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: CBSpace.x2),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = _user;
    final normalizedPublicId =
        ProfileFormValidation.sanitizePublicPlayerId(_publicIdController.text);

    return PopScope(
      canPop: _allowImmediatePop || !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _allowImmediatePop || !_hasChanges) {
          return;
        }
        _handleAttemptPop();
      },
      child: CBPrismScaffold(
        title: 'Profile',
        body: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _saving
                  ? const LinearProgressIndicator(
                      key: ValueKey('save-progress'))
                  : const SizedBox(
                      key: ValueKey('idle-progress'),
                      height: 4,
                    ),
            ),
            Expanded(
              child: _loadingProfile
                  ? const Center(child: CircularProgressIndicator())
                  : AnimatedOpacity(
                      opacity: _saving ? 0.7 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: IgnorePointer(
                        ignoring: _saving,
                        child: SingleChildScrollView(
                          padding: CBInsets.screen,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CBSectionHeader(
                                title: 'PLAYER PROFILE',
                                icon: Icons.badge_outlined,
                                color: scheme.primary,
                              ),
                              const SizedBox(height: CBSpace.x2),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _hasChanges
                                    ? CBGlassTile(
                                        key: const ValueKey('dirty-banner'),
                                        isPrismatic: true,
                                        borderColor: scheme.tertiary
                                            .withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(14),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.auto_awesome_rounded,
                                              color: scheme.tertiary,
                                              size: 18,
                                            ),
                                            const SizedBox(width: CBSpace.x2),
                                            Expanded(
                                              child: Text(
                                                'Unsaved changes in progress.',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: scheme.onSurface,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(
                                        key: ValueKey('clean-banner'),
                                        height: 0,
                                      ),
                              ),
                              const SizedBox(height: CBSpace.x4),
                              CBPanel(
                                borderColor:
                                    scheme.primary.withValues(alpha: 0.35),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ACCOUNT',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: scheme.primary,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: CBSpace.x3),
                                    _ReadonlyRow(
                                      label: 'UID',
                                      value: user?.uid ?? 'N/A',
                                    ),
                                    const SizedBox(height: CBSpace.x2),
                                    _ReadonlyRow(
                                      label: 'EMAIL',
                                      value:
                                          user?.email ?? 'No email on account',
                                    ),
                                    const SizedBox(height: CBSpace.x2),
                                    _ReadonlyRow(
                                      label: 'CREATED',
                                      value: _formatDateTime(_createdAt),
                                    ),
                                    const SizedBox(height: CBSpace.x2),
                                    _ReadonlyRow(
                                      label: 'UPDATED',
                                      value: _formatDateTime(_updatedAt),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: CBSpace.x4),
                              CBPanel(
                                borderColor:
                                    scheme.secondary.withValues(alpha: 0.35),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PUBLIC PROFILE',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: scheme.secondary,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: CBSpace.x3),
                                    CBTextField(
                                      controller: _usernameController,
                                      focusNode: _usernameFocusNode,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      maxLength: ProfileFormValidation
                                          .usernameMaxLength,
                                      errorText: _usernameError,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[A-Za-z0-9 _-]'),
                                        ),
                                      ],
                                      onSubmitted: (_) {
                                        FocusScope.of(context)
                                            .requestFocus(_publicIdFocusNode);
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Username *',
                                        hintText: '3-24 characters',
                                      ),
                                    ),
                                    const SizedBox(height: CBSpace.x1),
                                    Text(
                                      'This is what other players see in lobbies and recaps.',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: CBSpace.x3),
                                    CBTextField(
                                      controller: _publicIdController,
                                      focusNode: _publicIdFocusNode,
                                      textInputAction: TextInputAction.done,
                                      maxLength: ProfileFormValidation
                                          .publicIdMaxLength,
                                      errorText: _publicIdError,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[A-Za-z0-9_-]'),
                                        ),
                                      ],
                                      onSubmitted: (_) {
                                        if (_hasChanges && !_saving) {
                                          _saveProfile();
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Public Player ID (optional)',
                                        hintText: 'night_fox',
                                      ),
                                    ),
                                    if (normalizedPublicId.isNotEmpty) ...[
                                      const SizedBox(height: CBSpace.x1),
                                      Text(
                                        'Share link key: $normalizedPublicId',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: CBSpace.x4),
                                    Text(
                                      'PROFILE STYLE',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: scheme.tertiary,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: CBSpace.x2),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _preferredStyles.map((style) {
                                        final selected =
                                            style == _selectedPreferredStyle;
                                        return _PreferenceChip(
                                          label: _styleLabel(style),
                                          selected: selected,
                                          enabled: !_saving,
                                          onTap: () {
                                            setState(() {
                                              _selectedPreferredStyle = style;
                                            });
                                            _syncDirtyFlag();
                                          },
                                        );
                                      }).toList(growable: false),
                                    ),
                                    const SizedBox(height: CBSpace.x4),
                                    Text(
                                      'AVATAR EMOJI',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
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
                                        final selected =
                                            emoji == _selectedAvatar;
                                        return _AvatarChip(
                                          emoji: emoji,
                                          selected: selected,
                                          enabled: !_saving,
                                          onTap: () {
                                            setState(
                                                () => _selectedAvatar = emoji);
                                            _syncDirtyFlag();
                                          },
                                        );
                                      }).toList(growable: false),
                                    ),
                                    const SizedBox(height: CBSpace.x5),
                                    ProfileActionButtons(
                                      saving: _saving,
                                      canSave: !_saving &&
                                          user != null &&
                                          _hasChanges,
                                      canDiscard: !_saving && _hasChanges,
                                      onSave: _saveProfile,
                                      onDiscard: _discardChanges,
                                      onReload: () async {
                                        setState(() => _loadingProfile = true);
                                        await _loadProfile();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
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
            letterSpacing: 1,
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
    required this.enabled,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.22)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: CBGlassTile(
        isSelected: selected,
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        borderColor: selected
            ? scheme.secondary
            : scheme.outlineVariant.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected ? scheme.secondary : scheme.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

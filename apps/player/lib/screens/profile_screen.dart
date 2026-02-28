import 'dart:async';

import 'package:cb_comms/cb_comms_player.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../player_bridge.dart';
import '../profile_edit_guard.dart';
import '../services/profile_photo_service.dart';
import '../widgets/custom_drawer.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    this.repository,
    this.currentUserResolver,
    this.profileStreamFactory,
    this.authStateChangesResolver,
    this.startInEditMode = false,
  });

  final ProfileRepository? repository;
  final User? Function()? currentUserResolver;
  final Stream<Map<String, dynamic>?> Function(String uid)?
      profileStreamFactory;
  final Stream<User?> Function()? authStateChangesResolver;
  final bool startInEditMode;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _publicIdController = TextEditingController();

  ProfileRepository? _repository;

  bool _loadingProfile = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _usernameError;
  String? _publicIdError;
  String _selectedAvatar = clubAvatarEmojis.first;
  String? _photoUrl;
  String _initialUsername = '';
  String _initialPublicId = '';
  String _initialAvatar = clubAvatarEmojis.first;
  DateTime? _createdAt;
  DateTime? _updatedAt;
  StreamSubscription<Map<String, dynamic>?>? _profileSubscription;
  StreamSubscription<User?>? _authSubscription;
  String? _listeningUid;
  Map<String, dynamic>? _queuedRemoteProfile;
  bool _isApplyingRemoteUpdate = false;

  // Inline edit state
  String? _editingField; // 'username', 'publicId', or null
  int _loadingAwards = 0;
  List<RoleAwardDefinition> _unlockedAwards = const [];
  int _totalUnlocked = 0;

  ProfileRepository get _profileRepository {
    return _repository ??= widget.repository ??
        ProfileRepository(firestore: FirebaseFirestore.instance);
  }

  User? get _user {
    final resolver = widget.currentUserResolver;
    if (resolver != null) return resolver();
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get _hasChanges {
    return _usernameController.text.trim() != _initialUsername ||
        ProfileFormValidation.sanitizePublicPlayerId(
                _publicIdController.text) !=
            _initialPublicId ||
        _selectedAvatar != _initialAvatar;
  }

  @override
  void initState() {
    super.initState();
    if (widget.startInEditMode) {
      _editingField = 'username';
    }
    _usernameController.addListener(_onInputChanged);
    _publicIdController.addListener(_onInputChanged);
    _startAuthListener();
    _ensureProfileListener();
    _loadProfile();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _authSubscription?.cancel();
    _usernameController.removeListener(_onInputChanged);
    _publicIdController.removeListener(_onInputChanged);
    _usernameController.dispose();
    _publicIdController.dispose();
    super.dispose();
  }

  void _syncDirtyFlag() {
    if (!mounted) return;
    final dirty = _hasChanges;
    void write() {
      if (!mounted) return;
      if (ref.read(playerProfileDirtyProvider) == dirty) return;
      ref.read(playerProfileDirtyProvider.notifier).setDirty(dirty);
    }

    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      write();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => write());
    }
  }

  void _onInputChanged() {
    if (!mounted) return;
    setState(() {
      _usernameError = null;
      _publicIdError = null;
    });
    _syncDirtyFlag();
  }

  Stream<Map<String, dynamic>?> _profileStreamForUid(String uid) {
    final override = widget.profileStreamFactory;
    if (override != null) return override(uid);
    return _profileRepository.watchProfile(uid);
  }

  Stream<User?>? _authChangesStream() {
    final override = widget.authStateChangesResolver;
    if (override != null) return override();
    try {
      return FirebaseAuth.instance.authStateChanges();
    } catch (_) {
      return null;
    }
  }

  void _startAuthListener() {
    final stream = _authChangesStream();
    if (stream == null) return;
    _authSubscription?.cancel();
    _authSubscription = stream.listen((_) {
      if (!mounted) return;
      _ensureProfileListener();
      if (!_loadingProfile) setState(() => _loadingProfile = true);
      unawaited(_loadProfile());
    });
  }

  void _ensureProfileListener() {
    final uid = _user?.uid;
    if (uid == null) {
      _listeningUid = null;
      _profileSubscription?.cancel();
      _profileSubscription = null;
      return;
    }
    if (_listeningUid == uid && _profileSubscription != null) return;
    _listeningUid = uid;
    _profileSubscription?.cancel();
    _profileSubscription = _profileStreamForUid(uid).listen(
      (data) {
        if (!mounted || _listeningUid != uid) return;
        if (_saving || _hasChanges || _isApplyingRemoteUpdate) {
          _queuedRemoteProfile = data;
          return;
        }
        _applyProfileData(data, _user!);
      },
      onError: (_) {},
    );
  }

  void _applyProfileData(Map<String, dynamic>? profile, User user) {
    _isApplyingRemoteUpdate = true;
    try {
      final username =
          (profile?['username'] as String?)?.trim() ?? user.displayName?.trim();
      final publicId = (profile?['publicPlayerId'] as String?)?.trim();
      final avatar = (profile?['avatarEmoji'] as String?)?.trim();
      final photoUrl = (profile?['photoUrl'] as String?)?.trim();

      setState(() {
        _usernameController.text = username ?? '';
        _publicIdController.text = publicId == null
            ? ''
            : ProfileFormValidation.sanitizePublicPlayerId(publicId);
        _selectedAvatar = clubAvatarEmojis.contains(avatar)
            ? avatar!
            : clubAvatarEmojis.first;
        _photoUrl = (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null;
        _createdAt = _dateFromFirestore(profile?['createdAt']);
        _updatedAt =
            _dateFromFirestore(profile?['updatedAt']) ?? DateTime.now();
      });
      _captureInitialSnapshot();
    } finally {
      _isApplyingRemoteUpdate = false;
    }
  }

  void _captureInitialSnapshot() {
    _initialUsername = _usernameController.text.trim();
    _initialPublicId =
        ProfileFormValidation.sanitizePublicPlayerId(_publicIdController.text);
    _initialAvatar = _selectedAvatar;
    _syncDirtyFlag();
  }

  DateTime? _dateFromFirestore(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '---';
    final l = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)}';
  }

  Future<void> _loadProfile() async {
    _ensureProfileListener();
    final user = _user;
    if (user == null) {
      if (mounted) setState(() => _loadingProfile = false);
      _syncDirtyFlag();
      return;
    }
    try {
      final profile = await _profileRepository.loadProfile(user.uid);
      if (!mounted) return;
      _applyProfileData(profile, user);
      await _refreshAwards();
    } catch (_) {
      _showFeedback('Could not load profile.', isError: true);
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
      _syncDirtyFlag();
    }
  }

  Future<void> _refreshAwards() async {
    final user = _user;
    if (user == null || !mounted) return;
    setState(() => _loadingAwards++);
    try {
      final service = PersistenceService.instance;
      await service.rebuildRoleAwardProgresses();
      final all = service.roleAwards.loadRoleAwardProgresses();
      final playerKeys = <String>{
        user.uid,
        _usernameController.text.trim(),
        ProfileFormValidation.sanitizePublicPlayerId(_publicIdController.text),
        user.displayName?.trim() ?? '',
      };
      final bridgeId = ref.read(playerBridgeProvider).myPlayerId;
      if (bridgeId != null) playerKeys.add(bridgeId.trim());
      playerKeys.removeWhere((v) => v.isEmpty);

      final byAward = <String, PlayerRoleAwardProgress>{};
      for (final p in all) {
        if (!playerKeys.contains(p.playerKey)) continue;
        final existing = byAward[p.awardId];
        if (existing == null ||
            (p.isUnlocked && !existing.isUnlocked) ||
            p.progressValue > existing.progressValue) {
          byAward[p.awardId] = p;
        }
      }

      final unlocked = <RoleAwardDefinition>[];
      for (final e in byAward.entries) {
        if (!e.value.isUnlocked) continue;
        final def = roleAwardDefinitionById(e.key);
        if (def != null) unlocked.add(def);
      }
      unlocked.sort((a, b) => a.tier.index.compareTo(b.tier.index));

      if (!mounted) return;
      setState(() {
        _unlockedAwards = unlocked.take(6).toList(growable: false);
        _totalUnlocked = unlocked.length;
      });
    } catch (_) {
      if (mounted) setState(() => _unlockedAwards = const []);
    } finally {
      if (mounted) setState(() => _loadingAwards--);
    }
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _editingField = null;
      _usernameError = null;
      _publicIdError = null;
    });

    final user = _user;
    if (user == null) {
      _showFeedback('Not signed in.', isError: true);
      setState(() => _saving = false);
      return;
    }

    final username = _usernameController.text.trim();
    final publicId =
        ProfileFormValidation.sanitizePublicPlayerId(_publicIdController.text);

    final uv = ProfileFormValidation.validateUsername(username);
    if (uv != UsernameValidationState.valid) {
      setState(() {
        _usernameError = uv.errorMessage;
        _saving = false;
      });
      return;
    }

    final pv = ProfileFormValidation.validatePublicPlayerId(publicId,
        initialValue: _initialPublicId);
    if (pv != PublicIdValidationState.valid) {
      setState(() {
        _publicIdError = pv.errorMessage;
        _saving = false;
      });
      return;
    }

    if (publicId != _initialPublicId) {
      final taken = await _profileRepository.isPublicIdTaken(publicId);
      if (!mounted) return;
      if (taken) {
        setState(() {
          _publicIdError = 'ID already taken.';
          _saving = false;
        });
        return;
      }
    }

    try {
      await _profileRepository.updateProfile(user.uid, {
        'username': username,
        'publicPlayerId': publicId,
        'avatarEmoji': _selectedAvatar,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _captureInitialSnapshot();
      _showFeedback('Profile saved!');
    } catch (_) {
      if (!mounted) return;
      _showFeedback('Save failed.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
      if (_queuedRemoteProfile != null && _user != null && !_hasChanges) {
        final q = _queuedRemoteProfile;
        _queuedRemoteProfile = null;
        _applyProfileData(q, _user!);
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final user = _user;
    if (user == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final service = ProfilePhotoService();
      final url = await service.pickAndUpload(uid: user.uid, source: source);
      if (url != null && mounted) {
        setState(() => _photoUrl = url);
        _showFeedback('Photo updated!');
      }
    } catch (e) {
      if (mounted) _showFeedback('Photo upload failed.', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _showPhotoPickerSheet() {
    final scheme = Theme.of(context).colorScheme;
    showThemedBottomSheetBuilder<void>(
      context: context,
      accentColor: scheme.tertiary,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CBBottomSheetHandle(),
          ListTile(
            leading: Icon(Icons.camera_alt_rounded, color: scheme.primary),
            title: const Text('TAKE PHOTO'),
            onTap: () {
              Navigator.pop(ctx);
              _pickPhoto(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library_rounded, color: scheme.secondary),
            title: const Text('CHOOSE FROM GALLERY'),
            onTap: () {
              Navigator.pop(ctx);
              _pickPhoto(ImageSource.gallery);
            },
          ),
          if (_photoUrl != null)
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
              title: const Text('REMOVE PHOTO'),
              onTap: () async {
                Navigator.pop(ctx);
                final user = _user;
                if (user == null) return;
                setState(() => _uploadingPhoto = true);
                try {
                  await ProfilePhotoService().removePhoto(uid: user.uid);
                  if (mounted) setState(() => _photoUrl = null);
                } catch (e) {
                  debugPrint('removePhoto failed: $e');
                }
                if (mounted) setState(() => _uploadingPhoto = false);
              },
            ),
          ListTile(
            leading: Icon(Icons.emoji_emotions_rounded, color: scheme.tertiary),
            title: const Text('CHANGE AVATAR EMOJI'),
            onTap: () {
              Navigator.pop(ctx);
              _showAvatarPicker();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    final scheme = Theme.of(context).colorScheme;
    showThemedBottomSheetBuilder<void>(
      context: context,
      accentColor: scheme.tertiary,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CBBottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: clubAvatarEmojis.map((emoji) {
                return CBProfileAvatarChip(
                  emoji: emoji,
                  selected: _selectedAvatar == emoji,
                  enabled: !_saving,
                  onTap: () {
                    setState(() => _selectedAvatar = emoji);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    showThemedSnackBar(
      context,
      message,
      accentColor: isError
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.tertiary,
    );
  }

  void _startEditing(String field) {
    HapticFeedback.selectionClick();
    setState(() => _editingField = field);
  }

  void _stopEditing() {
    FocusScope.of(context).unfocus();
    setState(() => _editingField = null);
    if (_hasChanges) _saveProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final user = _user;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_hasChanges) return;
        final nav = Navigator.of(context);
        final discard = await showCBDiscardChangesDialog(
          context,
          message: 'Unsaved profile edits. Leave without saving?',
        );
        if (!mounted || !discard) return;
        nav.maybePop();
      },
      child: CBPrismScaffold(
        title: 'CLUB I.D.',
        drawer: const CustomDrawer(),
        body: _loadingProfile
            ? const Center(child: CBBreathingLoader())
            : GestureDetector(
                onTap: _editingField != null ? _stopEditing : null,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                  child: Column(
                    children: [
                      // ─── THE ID CARD ───
                      CBFadeSlide(
                        child: CBMemberIdCard(
                          usernameController: _usernameController,
                          publicIdController: _publicIdController,
                          photoUrl: _photoUrl,
                          avatarEmoji: _selectedAvatar,
                          uid: user?.uid,
                          createdAt: _createdAt,
                          isHost: false,
                          isUploadingPhoto: _uploadingPhoto,
                          editingField: _editingField,
                          usernameError: _usernameError,
                          publicIdError: _publicIdError,
                          onPhotoTap: _showPhotoPickerSheet,
                          onFieldTap: _startEditing,
                          onFieldSubmit: _stopEditing,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── ACCOLADES ───
                      if (_unlockedAwards.isNotEmpty || _loadingAwards > 0)
                        CBFadeSlide(
                          delay: const Duration(milliseconds: 80),
                          child: _buildAccolades(scheme, textTheme),
                        ),
                      if (_unlockedAwards.isNotEmpty || _loadingAwards > 0)
                        const SizedBox(height: 24),

                      // ─── TERMINAL PANEL ───
                      CBFadeSlide(
                        delay: const Duration(milliseconds: 160),
                        child: _buildTerminal(scheme, textTheme, user),
                      ),
                      const SizedBox(height: 24),

                      // ─── ACTIONS ───
                      if (_hasChanges)
                        CBFadeSlide(
                          delay: const Duration(milliseconds: 240),
                          child: CBPrimaryButton(
                            label: _saving ? 'SAVING...' : 'SAVE CHANGES',
                            icon: Icons.save_rounded,
                            onPressed: _saving ? null : _saveProfile,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ─── ACCOLADES ───────────────────────────────────────────

  Widget _buildAccolades(ColorScheme scheme, TextTheme textTheme) {
    return CBGlassTile(
      padding: const EdgeInsets.all(14),
      borderColor: scheme.secondary.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.military_tech_rounded,
                  size: 16, color: scheme.secondary),
              const SizedBox(width: 8),
              Text(
                'ACCOLADES',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  fontSize: 9,
                ),
              ),
              const Spacer(),
              if (_totalUnlocked > 0)
                CBBadge(
                    text: '$_totalUnlocked UNLOCKED', color: scheme.tertiary),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingAwards > 0)
            const LinearProgressIndicator(minHeight: 2)
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _unlockedAwards
                  .map((a) => CBBadge(
                        text: a.title.toUpperCase(),
                        color: scheme.tertiary,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ─── TERMINAL PANEL ──────────────────────────────────────

  bool get _hasEmailPasswordProvider {
    final user = _user;
    if (user == null) return false;
    try {
      return user.providerData.any((p) => p.providerId == 'password');
    } catch (_) {
      return false;
    }
  }

  Future<void> _showChangePassword() async {
    final user = _user;
    if (user == null || user.email == null) return;
    final result = await showCBChangePasswordDialog(
      context,
      onChangePassword: (currentPassword, newPassword) async {
        try {
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          );
          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(newPassword);
          return true;
        } catch (_) {
          return false;
        }
      },
    );
    if (result == true && mounted) {
      _showFeedback('Password changed successfully!');
    }
  }

  Widget _buildTerminal(ColorScheme scheme, TextTheme textTheme, User? user) {
    final email = user?.email ?? '---';

    return CBGlassTile(
      padding: const EdgeInsets.all(16),
      borderColor: scheme.outlineVariant.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal_rounded, size: 14, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'SYSTEM TERMINAL',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          Divider(
            color: scheme.outlineVariant.withValues(alpha: 0.1),
            height: 24,
          ),
          _TerminalRow(label: 'EMAIL', value: email),
          _TerminalRow(label: 'UID', value: user?.uid ?? '---'),
          _TerminalRow(label: 'CREATED', value: _formatDate(_createdAt)),
          _TerminalRow(label: 'UPDATED', value: _formatDate(_updatedAt)),
          if (_totalUnlocked > 0)
            _TerminalRow(label: 'AWARDS', value: '$_totalUnlocked UNLOCKED'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CBGhostButton(
                  label: 'REFRESH',
                  icon: Icons.sync_rounded,
                  onPressed: _refreshAwards,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CBGhostButton(
                  label: 'RELOAD',
                  icon: Icons.cloud_sync_rounded,
                  onPressed: () {
                    setState(() => _loadingProfile = true);
                    _loadProfile();
                  },
                ),
              ),
            ],
          ),
          if (_hasEmailPasswordProvider) ...[
            const SizedBox(height: 10),
            CBGhostButton(
              label: 'CHANGE PASSWORD',
              icon: Icons.key_rounded,
              color: scheme.secondary,
              onPressed: _showChangePassword,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── SMALL HELPER WIDGETS ──────────────────────────────────

class _TerminalRow extends StatelessWidget {
  final String label;
  final String value;

  const _TerminalRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 10,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 10,
                color: scheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

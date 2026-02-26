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






class SharedProfileScreen extends ConsumerStatefulWidget {
  const SharedProfileScreen({
    super.key,
    this.repository,
    this.currentUserResolver,
    this.profileStreamFactory,
    this.authStateChangesResolver,
    this.startInEditMode = false,

    this.drawer,
    this.onDirtyChanged,
    this.bridgePlayerId,
});

  final ProfileRepository? repository;
  final User? Function()? currentUserResolver;
  final Stream<Map<String, dynamic>?> Function(String uid)?
      profileStreamFactory;
  final Stream<User?> Function()? authStateChangesResolver;
  final bool startInEditMode;
  final Widget? drawer;
  final ValueChanged<bool>? onDirtyChanged;
  final String? bridgePlayerId;


  @override
  ConsumerState<SharedProfileScreen> createState() => _ProfileScreenState();
}

enum _FeedbackTone { info, success, error }

enum _ProfileLayoutMode { wallet, edit }

class _WalletAwardSnapshot {
  const _WalletAwardSnapshot({
    required this.unlocked,
    required this.inProgress,
    required this.totalTracked,
    required this.unlockedCount,
  });

  const _WalletAwardSnapshot.empty()
      : unlocked = const <RoleAwardDefinition>[],
        inProgress = const <RoleAwardDefinition>[],
        totalTracked = 0,
        unlockedCount = 0;

  final List<RoleAwardDefinition> unlocked;
  final List<RoleAwardDefinition> inProgress;
  final int totalTracked;
  final int unlockedCount;
}

class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _ProfileScreenState extends ConsumerState<SharedProfileScreen> {
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

  ProfileRepository? _repository;

  bool _loadingProfile = true;
  bool _loadingAwards = false;
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
  StreamSubscription<Map<String, dynamic>?>? _profileSubscription;
  StreamSubscription<User?>? _authSubscription;
  String? _listeningUid;
  Map<String, dynamic>? _queuedRemoteProfile;
  bool _remoteUpdatePending = false;
  bool _isApplyingRemoteUpdate = false;
  _ProfileLayoutMode _layoutMode = _ProfileLayoutMode.wallet;
  _WalletAwardSnapshot _awardSnapshot = const _WalletAwardSnapshot.empty();

  ProfileRepository get _profileRepository {
    return _repository ??= widget.repository ??
        ProfileRepository(firestore: FirebaseFirestore.instance);
  }

  User? get _user {
    final resolver = widget.currentUserResolver;
    if (resolver != null) {
      return resolver();
    }
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
        _selectedAvatar != _initialAvatar ||
        _selectedPreferredStyle != _initialPreferredStyle;
  }

  @override
  void initState() {
    super.initState();
    _layoutMode = widget.startInEditMode
        ? _ProfileLayoutMode.edit
        : _ProfileLayoutMode.wallet;
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
    _usernameFocusNode.dispose();
    _publicIdFocusNode.dispose();
    super.dispose();
  }

  void _syncDirtyFlag() {
    if (!mounted) {
      return;
    }
    final dirty = _hasChanges;

    void writeDirtyFlag() {
      if (!mounted) {
        return;
      }
      widget.onDirtyChanged?.call(dirty);
    }

    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      writeDirtyFlag();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      writeDirtyFlag();
    });
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

  void _dismissProfileFieldFocus() {
    _usernameFocusNode.unfocus();
    _publicIdFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  bool get _isWidgetTestBinding {
    return WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
  }

  Widget _wrapScrollSemanticsForTest(Widget child) {
    if (_isWidgetTestBinding) {
      return ExcludeSemantics(child: child);
    }
    return child;
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

  Stream<Map<String, dynamic>?> _profileStreamForUid(String uid) {
    final override = widget.profileStreamFactory;
    if (override != null) {
      return override(uid);
    }
    return _profileRepository.watchProfile(uid);
  }

  Stream<User?>? _authChangesStream() {
    final override = widget.authStateChangesResolver;
    if (override != null) {
      return override();
    }
    try {
      return FirebaseAuth.instance.authStateChanges();
    } catch (_) {
      return null;
    }
  }

  void _startAuthListener() {
    final stream = _authChangesStream();
    if (stream == null) {
      return;
    }
    _authSubscription?.cancel();
    _authSubscription = stream.listen((_) {
      if (!mounted) {
        return;
      }
      _ensureProfileListener();
      if (!_loadingProfile) {
        setState(() => _loadingProfile = true);
      }
      unawaited(_loadProfile());
    });
  }

  void _ensureProfileListener() {
    final user = _user;
    final uid = user?.uid;

    if (uid == null) {
      _listeningUid = null;
      _profileSubscription?.cancel();
      _profileSubscription = null;
      _queuedRemoteProfile = null;
      _remoteUpdatePending = false;
      return;
    }

    if (_listeningUid == uid && _profileSubscription != null) {
      return;
    }

    _listeningUid = uid;
    _profileSubscription?.cancel();
    _profileSubscription = _profileStreamForUid(uid).listen(
      (profileData) {
        if (!mounted || _listeningUid != uid) {
          return;
        }

        if (_saving || _hasChanges || _isApplyingRemoteUpdate) {
          _queuedRemoteProfile = profileData;
          if (!_remoteUpdatePending) {
            setState(() {
              _remoteUpdatePending = true;
            });
          }
          return;
        }

        _applyProfileData(profileData, user!);
      },
      onError: (_) {
        if (!mounted) {
          return;
        }
        _showFeedback(
          'Live profile sync temporarily unavailable.',
          tone: _FeedbackTone.error,
        );
      },
    );
  }

  void _applyQueuedRemoteProfileIfAny() {
    final user = _user;
    final queued = _queuedRemoteProfile;
    if (user == null || queued == null || _saving || _hasChanges) {
      return;
    }
    _queuedRemoteProfile = null;
    _applyProfileData(queued, user);
  }

  void _applyProfileData(Map<String, dynamic>? profile, User user) {
    _isApplyingRemoteUpdate = true;
    try {
      final username =
          (profile?['username'] as String?)?.trim() ?? user.displayName?.trim();
      final publicId = (profile?['publicPlayerId'] as String?)?.trim();
      final avatar = (profile?['avatarEmoji'] as String?)?.trim();
      final preferredStyle = (profile?['preferredStyle'] as String?)?.trim();

      _dismissProfileFieldFocus();
      setState(() {
        _usernameController.text = username ?? '';
        _publicIdController.text = publicId == null
            ? ''
            : ProfileFormValidation.sanitizePublicPlayerId(publicId);
        _selectedAvatar = clubAvatarEmojis.contains(avatar)
            ? avatar!
            : clubAvatarEmojis.first;
        _selectedPreferredStyle =
            _preferredStyles.contains(preferredStyle?.toLowerCase())
                ? preferredStyle!.toLowerCase()
                : _preferredStyles.first;
        _createdAt = _dateFromFirestore(profile?['createdAt']);
        _updatedAt =
            _dateFromFirestore(profile?['updatedAt']) ?? DateTime.now();
        _remoteUpdatePending = false;
      });
      _captureInitialSnapshot();
    } finally {
      _isApplyingRemoteUpdate = false;
    }
  }

  Future<void> _handleAttemptPop() async {
    if (!_hasChanges) {
      return;
    }
    final discard = await _confirmDiscardChanges();
    if (!discard || !mounted) {
      return;
    }
    _discardChanges();
    setState(() => _allowImmediatePop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).maybePop();
    });
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasChanges) {
      return true;
    }
    return showCBDiscardChangesDialog(
      context,
      message: 'You have unsaved profile edits. Leave without saving?',
    );
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

  Set<String> _resolvePlayerKeys({
    required User user,
    required String username,
    required String publicId,
  }) {
    final keys = <String>{
      user.uid,
      username.trim(),
      publicId.trim(),
      user.displayName?.trim() ?? '',
    };
    final bridgePlayerId = widget.bridgePlayerId;
    if (bridgePlayerId != null) {
      keys.add(bridgePlayerId.trim());
    }
    keys.removeWhere((value) => value.isEmpty);
    return keys;
  }

  Future<void> _refreshWalletAwards() async {
    final user = _user;
    if (user == null || !mounted) {
      return;
    }

    setState(() {
      _loadingAwards = true;
    });

    try {
      final service = PersistenceService.instance;
      await service.roleAwards.rebuildRoleAwardProgresses();
      final allProgress = service.roleAwards.loadRoleAwardProgresses();
      final playerKeys = _resolvePlayerKeys(
        user: user,
        username: _usernameController.text,
        publicId: _publicIdController.text,
      );

      final progressByAward = <String, PlayerRoleAwardProgress>{};
      for (final progress in allProgress) {
        if (!playerKeys.contains(progress.playerKey)) {
          continue;
        }
        final existing = progressByAward[progress.awardId];
        if (existing == null) {
          progressByAward[progress.awardId] = progress;
          continue;
        }
        if (progress.isUnlocked && !existing.isUnlocked) {
          progressByAward[progress.awardId] = progress;
          continue;
        }
        if (progress.progressValue > existing.progressValue) {
          progressByAward[progress.awardId] = progress;
        }
      }

      final unlocked = <RoleAwardDefinition>[];
      final inProgress = <RoleAwardDefinition>[];
      for (final entry in progressByAward.entries) {
        final definition = roleAwardDefinitionById(entry.key);
        if (definition == null) {
          continue;
        }
        if (entry.value.isUnlocked) {
          unlocked.add(definition);
        } else {
          inProgress.add(definition);
        }
      }

      unlocked.sort((a, b) => a.tier.index.compareTo(b.tier.index));
      inProgress.sort((a, b) => a.tier.index.compareTo(b.tier.index));

      if (!mounted) {
        return;
      }
      setState(() {
        _awardSnapshot = _WalletAwardSnapshot(
          unlocked: unlocked.take(6).toList(growable: false),
          inProgress: inProgress.take(4).toList(growable: false),
          totalTracked: progressByAward.length,
          unlockedCount: unlocked.length,
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _awardSnapshot = const _WalletAwardSnapshot.empty();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingAwards = false;
        });
      }
    }
  }

  Widget _buildWalletView(ThemeData theme, ColorScheme scheme) {
    final user = _user;
    final publicId = ProfileFormValidation.sanitizePublicPlayerId(
      _publicIdController.text,
    );

    return _wrapScrollSemanticsForTest(ScrollConfiguration(
      behavior: const _NoStretchScrollBehavior(),
      child: SingleChildScrollView(
        padding: CBInsets.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CBSectionHeader(
              title: 'DIGITAL WALLET',
              icon: Icons.account_balance_wallet_rounded,
              color: scheme.primary,
            ),
            const SizedBox(height: CBSpace.x4),
            CBGlassTile(
              isPrismatic: true,
              borderRadius: BorderRadius.circular(16),
              borderColor: scheme.primary.withValues(alpha: 0.45),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _selectedAvatar,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: CBSpace.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_usernameController.text.trim().isEmpty
                                      ? 'UNSET USERNAME'
                                      : _usernameController.text.trim())
                                  .toUpperCase(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              publicId.isEmpty
                                  ? 'ID: NOT ISSUED'
                                  : 'ID: ${publicId.toUpperCase()}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CBBadge(
                        text:
                            _styleLabel(_selectedPreferredStyle).toUpperCase(),
                        color: scheme.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: CBSpace.x4),
                  Text(
                    'ACCOLADES PRINTED',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: CBSpace.x2),
                  if (_loadingAwards)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 3),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._awardSnapshot.unlocked.map(
                          (award) => CBBadge(
                            text: award.title.toUpperCase(),
                            color: scheme.primary,
                          ),
                        ),
                        ..._awardSnapshot.inProgress.map(
                          (award) => CBBadge(
                            text: '${award.title.toUpperCase()} • INKING',
                            color: scheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: CBSpace.x3),
                  Text(
                    'UNLOCKED ${_awardSnapshot.unlockedCount} / ${_awardSnapshot.totalTracked}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: CBSpace.x4),
                  Row(
                    children: [
                      Expanded(
                        child: CBGhostButton(
                          label: 'EDIT PROFILE',
                          icon: Icons.edit_rounded,
                          onPressed: () {
                            setState(() {
                              _layoutMode = _ProfileLayoutMode.edit;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: CBSpace.x2),
                      Expanded(
                        child: CBGhostButton(
                          label: 'REFRESH WALLET',
                          icon: Icons.refresh_rounded,
                          onPressed: _refreshWalletAwards,
                        ),
                      ),
                    ],
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
                    'ISSUER DETAILS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.secondary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: CBSpace.x4),
                  CBProfileReadonlyRow(label: 'UID', value: user?.uid ?? 'N/A'),
                  const SizedBox(height: CBSpace.x3),
                  CBProfileReadonlyRow(
                    label: 'EMAIL',
                    value: user?.email ?? 'No email on account',
                  ),
                  const SizedBox(height: CBSpace.x3),
                  CBProfileReadonlyRow(
                    label: 'CREATED',
                    value: _formatDateTime(_createdAt),
                  ),
                  const SizedBox(height: CBSpace.x3),
                  CBProfileReadonlyRow(
                    label: 'LAST UPDATE',
                    value: _formatDateTime(_updatedAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Future<void> _loadProfile() async {
    _ensureProfileListener();
    final user = _user;
    if (user == null) {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
      _syncDirtyFlag();
      return;
    }

    try {
      final profile = await _profileRepository.loadProfile(user.uid);
      if (!mounted) {
        return;
      }

      _applyProfileData(profile, user);
      await _refreshWalletAwards();
    } catch (_) {
      _showFeedback(
        'Could not load profile right now. Showing local defaults.',
        tone: _FeedbackTone.error,
      );
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
        final usernameAvailable = await _profileRepository.isUsernameAvailable(
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
        final publicIdAvailable =
            await _profileRepository.isPublicPlayerIdAvailable(
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

      await _profileRepository.upsertBasicProfile(
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
        _layoutMode = _ProfileLayoutMode.wallet;
      });
      _dismissProfileFieldFocus();
      _captureInitialSnapshot();
      _applyQueuedRemoteProfileIfAny();
      await _refreshWalletAwards();
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
      _applyQueuedRemoteProfileIfAny();
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
      _layoutMode = _ProfileLayoutMode.wallet;
    });
    _dismissProfileFieldFocus();
    _syncDirtyFlag();
    _applyQueuedRemoteProfileIfAny();
    unawaited(_refreshWalletAwards());
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
        title: 'PLAYER PROFILE',
        drawer: widget.drawer,
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
                  ? const Center(child: CBBreathingLoader())
                  : IgnorePointer(
                      ignoring: _saving,
                      child: _layoutMode == _ProfileLayoutMode.wallet
                          ? _buildWalletView(theme, scheme)
                          : _wrapScrollSemanticsForTest(
                              ScrollConfiguration(
                                behavior: const _NoStretchScrollBehavior(),
                                child: SingleChildScrollView(
                                  padding: CBInsets.screen,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CBSectionHeader(
                                              title: 'EDIT PROFILE',
                                              icon: Icons.badge_outlined,
                                              color: scheme.primary,
                                            ),
                                          ),
                                          CBGhostButton(
                                            label: 'VIEW WALLET',
                                            icon: Icons
                                                .account_balance_wallet_rounded,
                                            onPressed: () {
                                              _dismissProfileFieldFocus();
                                              setState(() {
                                                _layoutMode =
                                                    _ProfileLayoutMode.wallet;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: CBSpace.x4),
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        child: (_hasChanges ||
                                                _remoteUpdatePending)
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 24),
                                                child: CBGlassTile(
                                                  key: const ValueKey(
                                                      'dirty-banner'),
                                                  isPrismatic: true,
                                                  borderColor: scheme.tertiary
                                                      .withValues(alpha: 0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .auto_awesome_rounded,
                                                        color: scheme.tertiary,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(
                                                          width: CBSpace.x2),
                                                      Expanded(
                                                        child: Text(
                                                          _remoteUpdatePending
                                                              ? 'Cloud profile update detected. Save/discard to sync latest values.'
                                                              : 'Unsaved changes in progress.',
                                                          style: theme.textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                            color: scheme
                                                                .onSurface,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : const SizedBox(
                                                key: ValueKey('clean-banner'),
                                                height: 0,
                                              ),
                                      ),
                                      CBPanel(
                                        borderColor: scheme.secondary
                                            .withValues(alpha: 0.35),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'PUBLIC PROFILE',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: scheme.secondary,
                                                letterSpacing: 1.2,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: CBSpace.x4),
                                            CBTextField(
                                              controller: _usernameController,
                                              focusNode: _usernameFocusNode,
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              textInputAction:
                                                  TextInputAction.next,
                                              maxLength: ProfileFormValidation
                                                  .usernameMaxLength,
                                              errorText: _usernameError,
                                              inputFormatters: <TextInputFormatter>[
                                                FilteringTextInputFormatter
                                                    .allow(
                                                  RegExp(r'[A-Za-z0-9 _-]'),
                                                ),
                                              ],
                                              onSubmitted: (_) {
                                                FocusScope.of(context)
                                                    .requestFocus(
                                                        _publicIdFocusNode);
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'USERNAME',
                                                hintText: '3-24 characters',
                                              ),
                                            ),
                                            const SizedBox(height: CBSpace.x2),
                                            Text(
                                              'This is what other players see in lobbies and recaps.',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: scheme.onSurface
                                                    .withValues(alpha: 0.5),
                                                fontSize: 9,
                                              ),
                                            ),
                                            const SizedBox(height: CBSpace.x4),
                                            CBTextField(
                                              controller: _publicIdController,
                                              focusNode: _publicIdFocusNode,
                                              textInputAction:
                                                  TextInputAction.done,
                                              maxLength: ProfileFormValidation
                                                  .publicIdMaxLength,
                                              errorText: _publicIdError,
                                              inputFormatters: <TextInputFormatter>[
                                                FilteringTextInputFormatter
                                                    .allow(
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
                                                    'PUBLIC PLAYER ID (OPTIONAL)',
                                                hintText: 'night_fox',
                                              ),
                                            ),
                                            if (normalizedPublicId
                                                .isNotEmpty) ...[
                                              const SizedBox(
                                                  height: CBSpace.x2),
                                              Text(
                                                'Share link key: $normalizedPublicId',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: scheme.onSurface
                                                      .withValues(alpha: 0.75),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: CBSpace.x6),
                                            Text(
                                              'VISUAL STYLE',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: scheme.tertiary,
                                                letterSpacing: 1.2,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: CBSpace.x3),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children:
                                                  _preferredStyles.map((style) {
                                                final selected = style ==
                                                    _selectedPreferredStyle;
                                                return CBProfilePreferenceChip(
                                                  label: _styleLabel(style)
                                                      .toUpperCase(),
                                                  selected: selected,
                                                  enabled: !_saving,
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedPreferredStyle =
                                                          style;
                                                    });
                                                    _syncDirtyFlag();
                                                  },
                                                );
                                              }).toList(growable: false),
                                            ),
                                            const SizedBox(height: CBSpace.x6),
                                            Text(
                                              'AVATAR',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: scheme.tertiary,
                                                letterSpacing: 1.2,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: CBSpace.x3),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children:
                                                  clubAvatarEmojis.map((emoji) {
                                                final selected =
                                                    emoji == _selectedAvatar;
                                                return CBProfileAvatarChip(
                                                  emoji: emoji,
                                                  selected: selected,
                                                  enabled: !_saving,
                                                  onTap: () {
                                                    setState(() =>
                                                        _selectedAvatar =
                                                            emoji);
                                                    _syncDirtyFlag();
                                                  },
                                                );
                                              }).toList(growable: false),
                                            ),
                                            const SizedBox(height: CBSpace.x6),
                                            CBProfileActionButtons(
                                              saving: _saving,
                                              canSave: !_saving &&
                                                  user != null &&
                                                  _hasChanges,
                                              canDiscard:
                                                  !_saving && _hasChanges,
                                              onSave: _saveProfile,
                                              onDiscard: _discardChanges,
                                              onReload: () async {
                                                setState(() =>
                                                    _loadingProfile = true);
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
            ),
          ],
        ),
      ),
    );
  }
}

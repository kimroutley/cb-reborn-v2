import 'dart:async';

import 'package:cb_comms/cb_comms_player.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile_edit_guard.dart';
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

  void _onInputChanged() {
    _normalizePublicIdField();
    if (!mounted) return;
    if (_usernameError != null || _publicIdError != null) {
      setState(() {
        _usernameError = null;
        _publicIdError = null;
      });
    } else {
      setState(() {});
    }
    _syncDirtyFlag();
  }

  void _syncDirtyFlag() {
    if (!mounted) return;
    final dirty = _hasChanges;
    if (ref.read(playerProfileDirtyProvider) == dirty) return;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(playerProfileDirtyProvider.notifier).setDirty(dirty);
    });
  }

  void _normalizePublicIdField() {
    final normalized =
        ProfileFormValidation.sanitizePublicPlayerId(_publicIdController.text);
    if (_publicIdController.text == normalized) return;

    _publicIdController.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }

  void _startAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (!mounted) return;
      _ensureProfileListener();
      setState(() => _loadingProfile = true);
      _loadProfile();
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
    _profileSubscription = _profileRepository.watchProfile(uid).listen(
      (profileData) {
        if (!mounted || _listeningUid != uid) return;
        if (_saving || _hasChanges || _isApplyingRemoteUpdate) {
          _queuedRemoteProfile = profileData;
          return;
        }
        _applyProfileData(profileData, _user!);
      },
    );
  }

  void _applyProfileData(Map<String, dynamic>? profile, User user) {
    _isApplyingRemoteUpdate = true;
    try {
      final username = (profile?['username'] as String?)?.trim() ?? user.displayName?.trim();
      final publicId = (profile?['publicPlayerId'] as String?)?.trim();
      final avatar = (profile?['avatarEmoji'] as String?)?.trim();
      final preferredStyle = (profile?['preferredStyle'] as String?)?.trim();

      setState(() {
        _usernameController.text = username ?? '';
        _publicIdController.text = publicId ?? '';
        _selectedAvatar = clubAvatarEmojis.contains(avatar) ? avatar! : clubAvatarEmojis.first;
        _selectedPreferredStyle = _preferredStyles.contains(preferredStyle?.toLowerCase())
                ? preferredStyle!.toLowerCase()
                : _preferredStyles.first;
        _createdAt = _dateFromFirestore(profile?['createdAt']);
        _updatedAt = _dateFromFirestore(profile?['updatedAt']) ?? DateTime.now();
      });
      _captureInitialSnapshot();
    } finally {
      _isApplyingRemoteUpdate = false;
    }
  }

  void _captureInitialSnapshot() {
    _initialUsername = _usernameController.text.trim();
    _initialPublicId = _publicIdController.text.trim();
    _initialAvatar = _selectedAvatar;
    _initialPreferredStyle = _selectedPreferredStyle;
    _syncDirtyFlag();
  }

  void _discardChanges() {
    _usernameController.text = _initialUsername;
    _publicIdController.text = _initialPublicId;
    _selectedAvatar = _initialAvatar;
    _selectedPreferredStyle = _initialPreferredStyle;
    _usernameError = null;
    _publicIdError = null;
    _syncDirtyFlag();
    if (mounted) setState(() {});
    _drainQueuedRemoteProfile();
  }

  void _drainQueuedRemoteProfile() {
    final queued = _queuedRemoteProfile;
    _queuedRemoteProfile = null;
    if (queued != null && _user != null && mounted) {
      _applyProfileData(queued, _user!);
    }
  }

  DateTime? _dateFromFirestore(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'UNKNOWN';
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _loadProfile() async {
    final uid = _user?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }

    try {
      final profile = await _profileRepository.loadProfile(uid);
      if (mounted) {
        _applyProfileData(profile, _user!);
        await _refreshWalletAwards();
      }
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _refreshWalletAwards() async {
    final user = _user;
    if (user == null || !mounted) return;

    setState(() => _loadingAwards = true);
    try {
      final service = PersistenceService.instance;
      await service.roleAwards.rebuildRoleAwardProgresses();
      final allProgress = service.roleAwards.loadRoleAwardProgresses();

      final playerKeys = {
        user.uid,
        _usernameController.text.trim(),
        _publicIdController.text.trim(),
      };

      final unlocked = <RoleAwardDefinition>[];
      final inProgress = <RoleAwardDefinition>[];

      for (final progress in allProgress) {
        if (!playerKeys.contains(progress.playerKey)) continue;
        final def = roleAwardDefinitionById(progress.awardId);
        if (def == null) continue;

        if (progress.isUnlocked) {
          unlocked.add(def);
        } else {
          inProgress.add(def);
        }
      }

      if (mounted) {
        setState(() {
          _awardSnapshot = _WalletAwardSnapshot(
            unlocked: unlocked..sort((a,b) => a.tier.index.compareTo(b.tier.index)),
            inProgress: inProgress..sort((a,b) => a.tier.index.compareTo(b.tier.index)),
            totalTracked: unlocked.length + inProgress.length,
            unlockedCount: unlocked.length,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _loadingAwards = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = _user;
    if (user == null) return;

    final username = _usernameController.text.trim();
    final usernameValidation = ProfileFormValidation.validateUsername(username);
    final rawPublicId = _publicIdController.text;

    if (usernameValidation != null) {
      setState(() => _usernameError = usernameValidation);
      return;
    }

    setState(() => _saving = true);
    try {
      if (username != _initialUsername) {
        final available = await _profileRepository.isUsernameAvailable(username, excludingUid: user.uid);
        if (!available) {
          setState(() => _usernameError = 'USERNAME ALREADY IN USE.');
          return;
        }
      }

      await _profileRepository.upsertBasicProfile(
        uid: user.uid,
        username: username,
        email: user.email,
        isHost: false,
        publicPlayerId: rawPublicId.isEmpty ? null : rawPublicId,
        avatarEmoji: _selectedAvatar,
        preferredStyle: _selectedPreferredStyle == 'auto' ? null : _selectedPreferredStyle,
      );

      await user.updateDisplayName(username);

      setState(() => _layoutMode = _ProfileLayoutMode.wallet);
      _captureInitialSnapshot();
      await _refreshWalletAwards();
      if (mounted) showThemedSnackBar(context, 'PROFILE ARCHIVED.', accentColor: Theme.of(context).colorScheme.primary);
    } catch (_) {
      if (mounted) showThemedSnackBar(context, 'UPLINK ERROR: COULD NOT SAVE.', accentColor: Theme.of(context).colorScheme.error);
    } finally {
      if (mounted) setState(() => _saving = false);
      _queuedRemoteProfile = null; // Stale — save persisted fresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return CBPrismScaffold(
      title: 'OPERATIVE PROFILE',
      drawer: const CustomDrawer(),
      body: PopScope(
        canPop: !_hasChanges || _allowImmediatePop,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop || !_hasChanges) return;
          final confirmed = await showCBDiscardChangesDialog(context, message: 'ABORT PROFILE EDITS?');
          if (confirmed && mounted) {
            setState(() => _allowImmediatePop = true);
            Navigator.of(context).maybePop();
          }
        },
        child: _loadingProfile
          ? const Center(child: CBBreathingLoader())
          : _layoutMode == _ProfileLayoutMode.wallet
            ? _buildWalletView(theme, scheme)
            : _buildEditView(theme, scheme),
      ),
    );
  }

  Widget _buildWalletView(ThemeData theme, ColorScheme scheme) {
    final user = _user;
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: CBSpace.x5, vertical: CBSpace.x6),
      physics: const BouncingScrollPhysics(),
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
            borderColor: scheme.primary.withValues(alpha: 0.45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_selectedAvatar, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: CBSpace.x4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_usernameController.text.trim().isEmpty ? 'UNSET MONIKER' : _usernameController.text.trim()).toUpperCase(),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              shadows: CBColors.textGlow(scheme.primary, intensity: 0.3),
                            ),
                          ),
                          Text(
                            _publicIdController.text.isEmpty ? 'ID: NOT ISSUED' : 'ID: ${_publicIdController.text.toUpperCase()}',
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CBBadge(
                      text: _selectedPreferredStyle.toUpperCase(),
                      color: scheme.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: CBSpace.x6),
                Text(
                  'ACCOLADES PRINTED',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: CBSpace.x3),
                if (_loadingAwards)
                  const LinearProgressIndicator(minHeight: 2)
                else
                  Wrap(
                    spacing: CBSpace.x2,
                    runSpacing: CBSpace.x2,
                    children: [
                      ..._awardSnapshot.unlocked.map((a) => CBBadge(text: a.title.toUpperCase(), color: scheme.primary)),
                      ..._awardSnapshot.inProgress.map((a) => CBBadge(text: '${a.title.toUpperCase()} • INKING', color: scheme.tertiary)),
                      if (_awardSnapshot.totalTracked == 0)
                        Text('NO ACTIVE CONTRACTS.', style: textTheme.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w700)),
                    ],
                  ),
                const SizedBox(height: CBSpace.x6),
                Row(
                  children: [
                    Expanded(
                      child: CBGhostButton(
                        label: 'EDIT PROFILE',
                        icon: Icons.edit_rounded,
                        onPressed: () {
                          HapticService.selection();
                          setState(() => _layoutMode = _ProfileLayoutMode.edit);
                        },
                      ),
                    ),
                    const SizedBox(width: CBSpace.x3),
                    Expanded(
                      child: CBGhostButton(
                        label: 'SYNC DATA',
                        icon: Icons.refresh_rounded,
                        onPressed: () {
                          HapticService.light();
                          _refreshWalletAwards();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: CBSpace.x8),
          CBSectionHeader(title: 'ISSUER DETAILS', icon: Icons.verified_user_rounded, color: scheme.secondary),
          const SizedBox(height: CBSpace.x4),
          CBPanel(
            borderColor: scheme.secondary.withValues(alpha: 0.3),
            child: Column(
              children: [
                _buildReadonlyRow('UID', user?.uid ?? 'N/A', scheme),
                const SizedBox(height: CBSpace.x3),
                _buildReadonlyRow('EMAIL', user?.email ?? 'ANONYMOUS', scheme),
                const SizedBox(height: CBSpace.x3),
                _buildReadonlyRow('ISSUED', _formatDateTime(_createdAt), scheme),
                const SizedBox(height: CBSpace.x3),
                _buildReadonlyRow('UPDATED', _formatDateTime(_updatedAt), scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadonlyRow(String label, String value, ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        Text(value.toUpperCase(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.8), fontWeight: FontWeight.w700, fontFamily: 'RobotoMono')),
      ],
    );
  }

  Widget _buildEditView(ThemeData theme, ColorScheme scheme) {
    final avatarChoices = clubAvatarEmojis.take(20).toList();
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(CBSpace.x6),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CBPanel(
            borderColor: scheme.primary.withValues(alpha: 0.4),
            padding: CBInsets.panel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('MODERATION TERMINAL', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5, shadows: CBColors.textGlow(scheme.primary))),
                const SizedBox(height: CBSpace.x6),
                CBTextField(
                  controller: _usernameController,
                  focusNode: _usernameFocusNode,
                  hintText: 'MONIKER',
                  errorText: _usernameError,
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: CBSpace.x4),
                CBTextField(
                  controller: _publicIdController,
                  focusNode: _publicIdFocusNode,
                  hintText: 'PUBLIC ID (OPTIONAL)',
                  errorText: _publicIdError,
                  prefixIcon: Icons.alternate_email_rounded,
                  monospace: true,
                ),
                const SizedBox(height: CBSpace.x8),
                Text('SELECT AVATAR', style: textTheme.labelSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: CBSpace.x3),
                Wrap(
                  spacing: CBSpace.x2,
                  runSpacing: CBSpace.x2,
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
                  }).toList(),
                ),
                const SizedBox(height: CBSpace.x10),
                CBPrimaryButton(
                  label: _saving ? 'ARCHIVING...' : 'SAVE CHANGES',
                  onPressed: _saving ? null : () {
                    HapticService.heavy();
                    _saveProfile();
                  },
                ),
                const SizedBox(height: CBSpace.x3),
                CBGhostButton(
                  label: 'ABORT CHANGES',
                  color: scheme.error,
                  onPressed: () {
                    HapticService.light();
                    _discardChanges();
                  },
                ),
              ],
            ),
          ),
        ],
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
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CBRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: CBSpace.x3, vertical: CBSpace.x2),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.2) : scheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(CBRadius.pill),
          border: Border.all(color: selected ? scheme.primary : scheme.outline.withValues(alpha: 0.3)),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

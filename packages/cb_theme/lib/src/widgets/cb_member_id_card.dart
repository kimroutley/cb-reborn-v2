import 'package:flutter/material.dart';

import 'cb_breathing_loader.dart';
import 'glass_tile.dart';

/// A shared ID-card widget used in both the Host and Player profile screens.
///
/// All editing state is managed by the parent; this widget is purely
/// presentational.  Pass [editingField] = `'username'` or `'publicId'`
/// to show the inline text-field for that slot.
class CBMemberIdCard extends StatelessWidget {
  const CBMemberIdCard({
    super.key,
    required this.usernameController,
    required this.publicIdController,
    this.photoUrl,
    this.avatarEmoji = '🎭',
    this.uid,
    this.createdAt,
    this.isHost = false,
    this.isUploadingPhoto = false,
    this.editingField,
    this.usernameError,
    this.publicIdError,
    this.onPhotoTap,
    this.onFieldTap,
    this.onFieldSubmit,
  });

  final TextEditingController usernameController;
  final TextEditingController publicIdController;
  final String? photoUrl;
  final String avatarEmoji;
  final String? uid;
  final DateTime? createdAt;
  final bool isHost;
  final bool isUploadingPhoto;

  /// Which field is currently being edited: `'username'`, `'publicId'`, or null.
  final String? editingField;
  final String? usernameError;
  final String? publicIdError;

  final VoidCallback? onPhotoTap;
  final void Function(String field)? onFieldTap;
  final VoidCallback? onFieldSubmit;

  String _formatDate(DateTime? value) {
    if (value == null) return '---';
    final l = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final accentColor = isHost ? scheme.primary : scheme.tertiary;
    final headerLabel =
        isHost ? 'CLUB BLACKOUT HOST' : 'CLUB BLACKOUT MEMBER';
    final validLabel = isHost ? 'HOST' : 'VALID';

    return CBGlassTile(
      isPrismatic: true,
      padding: EdgeInsets.zero,
      borderColor: accentColor.withValues(alpha: 0.5),
      child: Column(
        children: [
          // ── Header strip ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.2),
                  scheme.primary.withValues(alpha: 0.1),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: accentColor.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isHost
                      ? Icons.manage_accounts_rounded
                      : Icons.verified_user_rounded,
                  size: 14,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  headerLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    fontSize: 9,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    validLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: isHost
                          ? scheme.onPrimary
                          : scheme.onTertiary,
                      fontWeight: FontWeight.w900,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Card body ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo / avatar
                GestureDetector(
                  onTap: isUploadingPhoto ? null : onPhotoTap,
                  child: Container(
                    width: 88,
                    height: 110,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.15),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (photoUrl != null)
                            Image.network(
                              photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  avatarEmoji,
                                  style: const TextStyle(fontSize: 40),
                                ),
                              ),
                            )
                          else
                            Center(
                              child: Text(
                                avatarEmoji,
                                style: const TextStyle(fontSize: 44),
                              ),
                            ),
                          if (isUploadingPhoto)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CBBreathingLoader(size: 24),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color:
                                  accentColor.withValues(alpha: 0.85),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 12,
                                color: isHost
                                    ? scheme.onPrimary
                                    : scheme.onTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Editable fields
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardField(
                        label: 'MEMBER NAME',
                        value: usernameController.text.trim().isEmpty
                            ? 'TAP TO SET'
                            : usernameController.text.trim(),
                        field: 'username',
                        controller: usernameController,
                        error: usernameError,
                        isEditing: editingField == 'username',
                        accentColor: accentColor,
                        isPlaceholder:
                            usernameController.text.trim().isEmpty,
                        onTap: () => onFieldTap?.call('username'),
                        onSubmit: onFieldSubmit,
                      ),
                      const SizedBox(height: 14),
                      _CardField(
                        label: 'CLUB I.D.',
                        value: publicIdController.text.trim().isEmpty
                            ? 'TAP TO SET'
                            : '@${publicIdController.text.trim().toUpperCase()}',
                        field: 'publicId',
                        controller: publicIdController,
                        error: publicIdError,
                        isEditing: editingField == 'publicId',
                        accentColor: accentColor,
                        isPlaceholder:
                            publicIdController.text.trim().isEmpty,
                        onTap: () => onFieldTap?.call('publicId'),
                        onSubmit: onFieldSubmit,
                      ),
                      const SizedBox(height: 14),
                      _ReadOnlyField(
                        label: 'MEMBER SINCE',
                        value: _formatDate(createdAt),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Footer barcode strip ───────────────────────────────
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.nfc_rounded,
                    size: 14,
                    color: scheme.onSurfaceVariant
                        .withValues(alpha: 0.3)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    uid ?? '---',
                    style: textTheme.labelSmall?.copyWith(
                      fontFamily: 'RobotoMono',
                      fontSize: 8,
                      color: scheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      letterSpacing: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ...List.generate(
                  16,
                  (i) => Container(
                    width: i.isEven ? 2.0 : 1.0,
                    height: 16,
                    margin: const EdgeInsets.only(right: 1),
                    color: scheme.onSurfaceVariant.withValues(
                        alpha: i.isEven ? 0.25 : 0.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private helper widgets ──────────────────────────────────────────────

class _CardField extends StatelessWidget {
  const _CardField({
    required this.label,
    required this.value,
    required this.field,
    required this.controller,
    required this.isEditing,
    required this.accentColor,
    this.error,
    this.isPlaceholder = false,
    this.onTap,
    this.onSubmit,
  });

  final String label;
  final String value;
  final String field;
  final TextEditingController controller;
  final bool isEditing;
  final Color accentColor;
  final String? error;
  final bool isPlaceholder;
  final VoidCallback? onTap;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: accentColor,
              fontSize: 8,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 32,
            child: TextField(
              controller: controller,
              autofocus: true,
              style: textTheme.titleSmall?.copyWith(
                fontFamily: 'RobotoMono',
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                      color: accentColor.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: accentColor),
                ),
              ),
              onSubmitted: (_) => onSubmit?.call(),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 2),
            Text(
              error!,
              style: textTheme.labelSmall
                  ?.copyWith(color: scheme.error, fontSize: 9),
            ),
          ],
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 8,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontFamily: 'RobotoMono',
                    fontWeight: FontWeight.w800,
                    color: isPlaceholder
                        ? scheme.onSurface.withValues(alpha: 0.3)
                        : scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.edit_rounded,
                size: 10,
                color: scheme.primary.withValues(alpha: 0.4),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 2),
            Text(
              error!,
              style: textTheme.labelSmall
                  ?.copyWith(color: scheme.error, fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 8,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            fontFamily: 'RobotoMono',
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

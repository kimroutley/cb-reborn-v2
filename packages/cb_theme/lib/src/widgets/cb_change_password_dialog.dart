import 'package:flutter/material.dart';

import 'cb_buttons.dart';
import 'cb_text_field.dart';
import 'glass_tile.dart';

/// Shows a themed "change password" dialog.
///
/// Returns `true` if the password was changed successfully, `false` or `null`
/// otherwise.  The caller must supply [onChangePassword] which performs the
/// Firebase reauthentication + update and returns `true` on success.
Future<bool?> showCBChangePasswordDialog(
  BuildContext context, {
  required Future<bool> Function(String currentPassword, String newPassword)
      onChangePassword,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ChangePasswordDialog(onChangePassword: onChangePassword),
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.onChangePassword});

  final Future<bool> Function(String currentPassword, String newPassword)
      onChangePassword;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text;
    final newPw = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    if (newPw.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }
    if (newPw != confirm) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final ok = await widget.onChangePassword(current, newPw);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error = 'Could not change password. Check your current password.';
          _saving = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: CBGlassTile(
        borderColor: scheme.primary.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_reset_rounded,
                      size: 20, color: scheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'CHANGE PASSWORD',
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              CBTextField(
                controller: _currentController,
                hintText: 'CURRENT PASSWORD',
                obscureText: _obscureCurrent,
                enabled: !_saving,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_rounded,
                      size: 20,
                      color: scheme.primary.withValues(alpha: 0.5)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.4),
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              CBTextField(
                controller: _newController,
                hintText: 'NEW PASSWORD',
                obscureText: _obscureNew,
                enabled: !_saving,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_open_rounded,
                      size: 20,
                      color: scheme.primary.withValues(alpha: 0.5)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.4),
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              CBTextField(
                controller: _confirmController,
                hintText: 'CONFIRM NEW PASSWORD',
                obscureText: _obscureConfirm,
                enabled: !_saving,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline_rounded,
                      size: 20,
                      color: scheme.primary.withValues(alpha: 0.5)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.4),
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CBGhostButton(
                      label: 'CANCEL',
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CBPrimaryButton(
                      label: _saving ? 'SAVING...' : 'UPDATE',
                      icon: Icons.check_rounded,
                      onPressed: _saving ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

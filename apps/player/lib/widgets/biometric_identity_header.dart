import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class BiometricIdentityHeader extends StatelessWidget {
  final String displayName;
  final VoidCallback onEditProfile;

  const BiometricIdentityHeader({
    super.key,
    required this.displayName,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 12,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: CBColors.circleGlow(scheme.primary, intensity: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'BIOMETRIC ID',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w900,
                    shadows: CBColors.textGlow(scheme.primary, intensity: 0.3),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: onEditProfile,
              borderRadius: BorderRadius.circular(CBRadius.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: CBSpace.x2, vertical: CBSpace.x1),
                decoration: BoxDecoration(
                  color: scheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(CBRadius.sm),
                  border: Border.all(
                    color: scheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'EDIT',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CBSpace.x2),
        CBGlassTile(
          borderColor: scheme.primary.withValues(alpha: 0.6),
          isPrismatic: true,
          padding: const EdgeInsets.all(CBSpace.x3),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: CBColors.circleGlow(scheme.primary, intensity: 0.4),
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: scheme.primary,
                  size: 28,
                  shadows: CBColors.iconGlow(scheme.primary, intensity: 0.8),
                ),
              ),
              const SizedBox(width: CBSpace.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName.toUpperCase(),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        fontFamily: 'Orbitron', // Assuming Orbitron or keeping RobotoMono if preferred. Let's stick with RobotoMono for theme adherence but make it sleeker.
                        color: scheme.onSurface,
                        shadows: CBColors.textGlow(scheme.primary, intensity: 0.2),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CBColors.success,
                            boxShadow: CBColors.circleGlow(CBColors.success, intensity: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SESSION GRANTED',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 9,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: scheme.primary.withValues(alpha: 0.8),
                  size: 20,
                  shadows: CBColors.iconGlow(scheme.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

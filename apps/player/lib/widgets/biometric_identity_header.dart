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
            Text(
              'BIOMETRIC BINDING',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w900,
                shadows: CBColors.textGlow(scheme.primary, intensity: 0.3),
              ),
            ),
            InkWell(
              onTap: onEditProfile,
              child: Padding(
                padding: const EdgeInsets.all(CBSpace.x1),
                child: Text(
                  'EDIT PROFILE',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CBSpace.x3),
        CBGlassTile(
          borderColor: scheme.primary.withValues(alpha: 0.5),
          isPrismatic: true,
          padding: const EdgeInsets.all(CBSpace.x4),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: CBColors.circleGlow(scheme.primary, intensity: 0.4),
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: scheme.primary,
                  size: 24,
                  shadows: CBColors.iconGlow(scheme.primary),
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
                        letterSpacing: 2.0,
                        fontFamily: 'RobotoMono',
                        color: scheme.onSurface,
                        shadows: CBColors.textGlow(scheme.primary, intensity: 0.2),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SESSION ACCESS GRANTED',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: scheme.primary,
                shadows: CBColors.iconGlow(scheme.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

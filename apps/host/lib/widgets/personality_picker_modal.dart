import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class PersonalityPickerModal extends StatelessWidget {
  final String selectedPersonalityId;
  final ValueChanged<String> onPersonalitySelected;

  const PersonalityPickerModal({
    super.key,
    required this.selectedPersonalityId,
    required this.onPersonalitySelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CBBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(CBSpace.x5, CBSpace.x2, CBSpace.x5, CBSpace.x6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'HOST PERSONALITY PROTOCOL',
                style: textTheme.headlineSmall!.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  shadows: CBColors.textGlow(scheme.primary, intensity: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CBSpace.x3),
              Text(
                'SELECT A SYNTHETIC IDENTITY FOR MISSION NARRATION.',
                style: textTheme.bodySmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CBSpace.x6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: hostPersonalities.length,
                  separatorBuilder: (context, index) => const SizedBox(height: CBSpace.x2),
                  itemBuilder: (context, index) {
                    final p = hostPersonalities[index];
                    final isSelected = p.id == selectedPersonalityId;
                    
                    return CBGlassTile(
                      onTap: () {
                        HapticService.selection();
                        onPersonalitySelected(p.id);
                      },
                      borderColor: isSelected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.2),
                      isSelected: isSelected,
                      padding: const EdgeInsets.all(CBSpace.x4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(CBSpace.x2),
                            decoration: BoxDecoration(
                              color: (isSelected ? scheme.primary : scheme.onSurface).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSelected ? Icons.psychology_rounded : Icons.psychology_outlined,
                              color: isSelected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.4),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: CBSpace.x4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name.toUpperCase(),
                                  style: textTheme.labelLarge?.copyWith(
                                    color: isSelected ? scheme.primary : scheme.onSurface,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.description.toUpperCase(),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurface.withValues(alpha: 0.5),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.verified_user_rounded, color: scheme.primary, size: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

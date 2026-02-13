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

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'SELECT HOST PERSONALITY',
            style: CBTypography.micro.copyWith(letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: hostPersonalities.length,
              itemBuilder: (context, index) {
                final p = hostPersonalities[index];
                final isSelected = p.id == selectedPersonalityId;
                return ListTile(
                  title: Text(
                    p.name,
                    style: isSelected
                        ? CBTypography.bodyBold.copyWith(color: scheme.primary)
                        : CBTypography.body,
                  ),
                  subtitle: Text(p.description, style: CBTypography.caption),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: scheme.primary)
                      : null,
                  onTap: () => onPersonalitySelected(p.id),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

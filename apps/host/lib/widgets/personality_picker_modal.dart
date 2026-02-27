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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SELECT HOST PERSONALITY',
          style: CBTypography.labelSmall.copyWith(
            color: scheme.tertiary,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
                  ? Icon(Icons.check_circle_rounded, color: scheme.tertiary)
                  : null,
              onTap: () => onPersonalitySelected(p.id),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

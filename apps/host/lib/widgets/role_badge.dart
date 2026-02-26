import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  final Role? role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    Color badgeColor = theme.colorScheme.primary;
    if (role!.colorHex.isNotEmpty) {
      final hex = role!.colorHex.replaceAll('#', '');
      badgeColor = Color(int.parse('FF$hex', radix: 16));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            role!.assetPath,
            width: 48,
            height: 48,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.person, size: 48, color: badgeColor),
          ),
          const SizedBox(height: 6),
          CBBadge(text: role!.name, color: badgeColor),
        ],
      ),
    );
  }
}

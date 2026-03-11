import 'package:flutter/material.dart';
import '../../cb_theme.dart';

/// CBAttachmentMenu
/// 
/// A bottom sheet menu mimicking the "+" attachment drawer in modern messaging apps
/// (like Google Messages) customized for the Club Blackout aesthetic.
/// Presents a grid of actions/intel options.
class CBAttachmentMenu extends StatelessWidget {
  final List<CBAttachmentMenuItem> items;
  final ColorScheme scheme;

  const CBAttachmentMenu({
    super.key,
    required this.items,
    required this.scheme,
  });

  static Future<void> show(
    BuildContext context, {
    required List<CBAttachmentMenuItem> items,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CBRadius.xl)),
      ),
      builder: (ctx) => CBAttachmentMenu(items: items, scheme: scheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: CBSpace.x6, vertical: CBSpace.x4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x6),
            Wrap(
              spacing: CBSpace.x4,
              runSpacing: CBSpace.x4,
              alignment: WrapAlignment.center,
              children: items.map((item) => _buildItem(context, item)).toList(),
            ),
            const SizedBox(height: CBSpace.x4),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, CBAttachmentMenuItem item) {
    final color = item.color ?? scheme.primary;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        item.onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(item.icon, color: color, size: 28),
          ),
          const SizedBox(height: CBSpace.x2),
          Text(
            item.label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          if (item.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              item.subtitle!.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class CBAttachmentMenuItem {
  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const CBAttachmentMenuItem({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.color,
  });
}

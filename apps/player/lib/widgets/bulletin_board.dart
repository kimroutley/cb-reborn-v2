import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class CBBulletinBoard extends StatefulWidget {
  final List<BulletinEntry> entries;

  const CBBulletinBoard({super.key, required this.entries});

  @override
  State<CBBulletinBoard> createState() => _CBBulletinBoardState();
}

class _CBBulletinBoardState extends State<CBBulletinBoard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(CBBulletinBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries.length > oldWidget.entries.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (widget.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mark_chat_unread_outlined,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'NO RECENT UPDATES',
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 24),
      itemCount: widget.entries.length,
      itemBuilder: (context, index) {
        final entry = widget.entries[index];
        final role = entry.roleId != null
            ? roleCatalog.firstWhere((r) => r.id == entry.roleId,
                orElse: () => roleCatalog.first)
            : null;

        final color = role != null
            ? CBColors.fromHex(role.colorHex)
            : scheme.primary;

        return CBMessageBubble(
          variant: entry.type == 'system'
              ? CBMessageVariant.system
              : CBMessageVariant.narrative,
          content: entry.content,
          senderName: role?.name ?? entry.title,
          accentColor: color,
          avatar: role != null
              ? CBRoleAvatar(assetPath: role.assetPath, color: color, size: 32)
              : null,
        );
      },
    );
  }
}

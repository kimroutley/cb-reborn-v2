import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';

import 'chat_bubble.dart';

/// Shared bulletin-to-feed logic: computes message group position by sender (roleId).
/// Use with [BulletinFeed] for consistent grouping across Host and Player apps.
CBMessageGroupPosition bulletinGroupPositionAt(
    int index, List<BulletinEntry> entries) {
  if (entries.isEmpty || index < 0 || index >= entries.length) {
    return CBMessageGroupPosition.single;
  }
  final entry = entries[index];
  final prevSame = index > 0 && entries[index - 1].roleId == entry.roleId;
  final nextSame =
      index < entries.length - 1 && entries[index + 1].roleId == entry.roleId;
  if (prevSame && nextSame) return CBMessageGroupPosition.middle;
  if (prevSame && !nextSame) return CBMessageGroupPosition.bottom;
  if (!prevSame && nextSame) return CBMessageGroupPosition.top;
  return CBMessageGroupPosition.single;
}

/// Reusable feed that renders a list of [BulletinEntry] with consistent grouping.
/// Supply [itemBuilder] to render each item (e.g. [CBMessageBubble], [CBFeedSeparator], host-only tiles).
/// Use in [GameScreen], [LobbyScreen], and [HostMainFeed] for unified styling.
class BulletinFeed extends StatelessWidget {
  final List<BulletinEntry> entries;
  final Widget Function(
    BuildContext context,
    int index,
    BulletinEntry entry,
    CBMessageGroupPosition groupPosition,
  ) itemBuilder;
  final EdgeInsetsGeometry? padding;

  const BulletinFeed({
    super.key,
    required this.entries,
    required this.itemBuilder,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final children = <Widget>[
      for (int i = 0; i < entries.length; i++)
        itemBuilder(
            context, i, entries[i], bulletinGroupPositionAt(i, entries)),
    ];
    if (padding != null) {
      return Padding(
        padding: padding!,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

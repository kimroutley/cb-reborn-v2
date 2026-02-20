import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';
import 'cb_panel.dart';
import 'cb_section_header.dart';

/// A widget to display the alliance graph.
class CBAllianceGraph extends StatelessWidget {
  final List<Player> players;

  const CBAllianceGraph({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    // This is a placeholder and will be implemented with the full Alliance Graph UI.
    return CBPanel(
      child: Column(
        children: [
          const CBSectionHeader(title: 'Alliance Graph'),
          ...players.map((p) => Text(p.name)),
        ],
      ),
    );
  }
}

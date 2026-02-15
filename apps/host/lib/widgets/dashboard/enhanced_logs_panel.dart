import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class EnhancedLogsPanel extends StatefulWidget {
  final List<String> logs;

  const EnhancedLogsPanel({super.key, required this.logs});

  @override
  State<EnhancedLogsPanel> createState() => _EnhancedLogsPanelState();
}

class _EnhancedLogsPanelState extends State<EnhancedLogsPanel> {
  String _logFilter = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final filteredLogs = _filterLogs(widget.logs);

    return CBPanel(
      borderColor: CBColors.radiantTurquoise.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CBSectionHeader(
            title: 'Enhanced Session Logs',
            icon: Icons.history,
          ),
          const SizedBox(height: 16),

          // Filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['ALL', 'SYSTEM', 'ACTION', 'HOST'].map((filter) {
              final color = switch (filter) {
                'SYSTEM' => scheme.secondary,
                'ACTION' => scheme.tertiary,
                'HOST' => scheme.error,
                _ => scheme.primary,
              };
              final icon = switch (filter) {
                'SYSTEM' => Icons.memory_rounded,
                'ACTION' => Icons.flash_on_rounded,
                'HOST' => Icons.admin_panel_settings_rounded,
                _ => Icons.all_inclusive_rounded,
              };

              return CBFilterChip(
                label: filter,
                icon: icon,
                color: color,
                selected: _logFilter == filter,
                onSelected: () => setState(() => _logFilter = filter),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Search field
          CBTextField(
            decoration: const InputDecoration(
              hintText: 'Search logs...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 16),

          // Log list
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              reverse: true,
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                final log = filteredLogs[filteredLogs.length - 1 - index];
                final isHost = log.contains('[HOST]');
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '> ',
                        style: textTheme.bodySmall!.copyWith(
                          color: isHost ? scheme.error : scheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          log,
                          style: textTheme.bodySmall!.copyWith(
                            color: isHost
                                ? scheme.error
                                : scheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _filterLogs(List<String> logs) {
    var filtered = logs;

    // Apply category filter
    if (_logFilter != 'ALL') {
      filtered = filtered.where((log) {
        switch (_logFilter) {
          case 'SYSTEM':
            return log.contains('──') ||
                log.contains('NIGHT') ||
                log.contains('DAY');
          case 'ACTION':
            return !log.contains('──') && !log.contains('[HOST]');
          case 'HOST':
            return log.contains('[HOST]');
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
              (log) => log.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }
}

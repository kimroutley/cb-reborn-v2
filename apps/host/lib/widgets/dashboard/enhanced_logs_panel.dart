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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final filteredLogs = _filterLogs(widget.logs);

    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'SESSION AUDIT LOGS',
            icon: Icons.history_edu_rounded,
            color: scheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            '// REAL-TIME STREAM OF ENCRYPTED SESSION DATA.',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.primary.withValues(alpha: 0.6),
              fontSize: 8,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

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
                'ACTION' => Icons.bolt_rounded,
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
          const SizedBox(height: 16),

          // Search field
          CBTextField(
            hintText: 'SEARCH AUDIT STREAM...',
            decoration: InputDecoration(
              prefixIcon:
                  Icon(Icons.search_rounded, color: scheme.primary, size: 18),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 16),

          // Log list
          CBGlassTile(
            padding: EdgeInsets.zero,
            borderColor: scheme.outlineVariant.withValues(alpha: 0.3),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[filteredLogs.length - 1 - index];
                    final isHost = log.contains('[HOST]');
                    final isSystem = log.contains('──') ||
                        log.contains('NIGHT') ||
                        log.contains('DAY');

                    if (isSystem) {
                      return CBFeedSeparator(
                        label: log.replaceAll('──', '').trim(),
                        color: scheme.secondary,
                      );
                    }

                    return CBMessageBubble(
                      sender: isHost ? 'HOST' : 'SYSTEM',
                      message: log.replaceFirst('[HOST] ', '').toUpperCase(),
                      style: isHost ? CBMessageStyle.narrative : CBMessageStyle.system,
                      color: isHost ? scheme.error : scheme.primary,
                      isCompact: true,
                    );
                  },
                ),
              ),
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

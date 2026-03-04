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
      borderColor: scheme.primary.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(CBSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CBSectionHeader(
            title: 'SESSION AUDIT STREAM',
            icon: Icons.history_edu_rounded,
            color: scheme.primary,
          ),
          const SizedBox(height: CBSpace.x4),
          Text(
            'ENCRYPTED DATA LOGS FOR REAL-TIME OPERATIONS MONITORING.',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x5),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
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

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CBFilterChip(
                    label: filter,
                    icon: icon,
                    color: color,
                    selected: _logFilter == filter,
                    onSelected: () {
                      HapticService.selection();
                      setState(() => _logFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: CBSpace.x4),

          // Search field
          CBTextField(
            hintText: 'FILTER AUDIT LOGS...',
            prefixIcon: Icons.search_rounded,
            monospace: true,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: CBSpace.x4),

          // Log list
          CBGlassTile(
            padding: EdgeInsets.zero,
            borderColor: scheme.outlineVariant.withValues(alpha: 0.2),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest.withValues(alpha: 0.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CBRadius.md),
                child: filteredLogs.isEmpty
                    ? Center(
                        child: Text(
                          'NO MATCHING TRANSMISSIONS',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.2),
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(CBSpace.x4),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[filteredLogs.length - 1 - index];
                          final isHost = log.contains('[HOST]');
                          final isSystem = log.contains('──') ||
                              log.contains('NIGHT') ||
                              log.contains('DAY');

                          final logColor = isHost
                              ? scheme.error
                              : isSystem
                                  ? scheme.secondary
                                  : scheme.onSurface.withValues(alpha: 0.7);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '# ',
                                  style: textTheme.labelSmall!.copyWith(
                                    color: logColor.withValues(alpha: 0.3),
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'RobotoMono',
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    log.toUpperCase(),
                                    style: textTheme.labelSmall!.copyWith(
                                      color: logColor,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                      fontFamily: 'RobotoMono',
                                      fontWeight: (isHost || isSystem)
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

    if (_logFilter != 'ALL') {
      filtered = filtered.where((log) {
        switch (_logFilter) {
          case 'SYSTEM':
            return log.contains('──') ||
                log.contains('NIGHT') ||
                log.contains('DAY');
          case 'ACTION':
            return !log.contains('──') && !log.contains('[HOST]') && !log.contains('NIGHT') && !log.contains('DAY');
          case 'HOST':
            return log.contains('[HOST]');
          default:
            return true;
        }
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
              (log) => log.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }
}

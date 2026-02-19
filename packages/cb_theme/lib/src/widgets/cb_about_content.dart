import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../colors.dart';
import '../layout.dart';
import 'cb_panel.dart';
import 'cb_section_header.dart';

class CBAboutContent extends StatelessWidget {
  const CBAboutContent({
    super.key,
    required this.appHeading,
    required this.appSubtitle,
    required this.versionLabel,
    required this.releaseDateLabel,
    required this.creditsLabel,
    required this.copyrightLabel,
    required this.recentBuilds,
    this.onPrivacyTap,
  });

  final String appHeading;
  final String appSubtitle;
  final String versionLabel;
  final String releaseDateLabel;
  final String creditsLabel;
  final String copyrightLabel;
  final List<AppBuildUpdate> recentBuilds;
  final VoidCallback? onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final visibleBuilds = recentBuilds.take(3).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        CBSectionHeader(
          title: appHeading,
          icon: Icons.info_outline,
          color: scheme.primary,
        ),
        const SizedBox(height: 12),
        CBPanel(
          borderColor: scheme.primary.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appSubtitle,
                style: textTheme.headlineSmall?.copyWith(
                  letterSpacing: 2.0,
                  color: scheme.secondary,
                  shadows: CBColors.textGlow(scheme.secondary, intensity: 0.6),
                ),
              ),
              const SizedBox(height: CBSpace.x2),
              Text(
                'A game by Kyrian Co.',
                style: textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: CBSpace.x4),
              _MetaRow(label: 'Version', value: versionLabel),
              const SizedBox(height: CBSpace.x2),
              _MetaRow(label: 'Release Date', value: releaseDateLabel),
              const SizedBox(height: CBSpace.x2),
              _MetaRow(label: 'Credits', value: creditsLabel),
              const SizedBox(height: CBSpace.x2),
              _MetaRow(label: 'Copyright', value: copyrightLabel),
            ],
          ),
        ),
        if (onPrivacyTap != null) ...[
          const SizedBox(height: 18),
          CBSectionHeader(
            title: 'PRIVACY',
            icon: Icons.privacy_tip_outlined,
            color: scheme.tertiary,
          ),
          const SizedBox(height: 12),
          CBPanel(
            borderColor: scheme.tertiary.withValues(alpha: 0.35),
            child: InkWell(
              onTap: onPrivacyTap,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Open privacy policy',
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 28),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        CBSectionHeader(
          title: 'LATEST UPDATES',
          icon: Icons.update_rounded,
          color: scheme.tertiary,
        ),
        const SizedBox(height: 12),
        CBPanel(
          borderColor: scheme.tertiary.withValues(alpha: 0.35),
          child: visibleBuilds.isEmpty
              ? Text(
                  'No recent updates available.',
                  style: textTheme.bodyMedium?.copyWith(color: CBColors.textDim),
                )
              : Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(
                      'View latest updates',
                      style: textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Showing the ${visibleBuilds.length} most recent builds',
                      style: textTheme.bodySmall?.copyWith(
                        color: CBColors.textDim,
                      ),
                    ),
                    children: [
                      const SizedBox(height: CBSpace.x2),
                      for (var i = 0; i < visibleBuilds.length; i++) ...[
                        _BuildUpdateTile(update: visibleBuilds[i]),
                        if (i < visibleBuilds.length - 1)
                          Divider(
                            color: scheme.outlineVariant.withValues(alpha: 0.35),
                            height: CBSpace.x6,
                          ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium,
        children: [
          TextSpan(
            text: '$label: ',
            style: textTheme.bodyMedium?.copyWith(
              color: CBColors.textDim,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildUpdateTile extends StatelessWidget {
  const _BuildUpdateTile({required this.update});

  final AppBuildUpdate update;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final formattedDate = DateFormat.yMMMd().format(update.releaseDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'v${update.version} (Build ${update.buildNumber}) · $formattedDate',
          style: textTheme.titleSmall?.copyWith(
            color: scheme.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: CBSpace.x2),
        ...update.highlights.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: CBSpace.x1),
            child: Text(
              '• $item',
              style: textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../widgets/custom_drawer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<_PlayerAboutData> _loadAboutData() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final releases = await AppReleaseNotes.loadRecentBuildUpdates();
    return _PlayerAboutData(packageInfo: packageInfo, releases: releases);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'ABOUT CLUB',
      drawer: const CustomDrawer(),
      body: FutureBuilder<_PlayerAboutData>(
        future: _loadAboutData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CBBreathingSpinner());
          }

          final packageInfo = snapshot.data?.packageInfo;
          final releases = snapshot.data?.releases ?? const <AppBuildUpdate>[];
          final releaseDate = releases.isNotEmpty
              ? DateFormat.yMMMd().format(releases.first.releaseDate)
              : 'UNKNOWN';

          final versionLabel = packageInfo == null
              ? 'UNKNOWN VERSION'
              : 'V${packageInfo.version} (BUILD ${packageInfo.buildNumber})';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x6, CBSpace.x6, CBSpace.x12),
            physics: const BouncingScrollPhysics(),
            child: CBFadeSlide(
              child: CBAboutContent(
                appHeading: 'CLUB BLACKOUT: REBORN',
                appSubtitle: 'PLAYER TERMINAL',
                versionLabel: versionLabel,
                releaseDateLabel: releaseDate,
                creditsLabel: 'KYRIAN CO. OPERATIVES',
                copyrightLabel:
                    '© ${DateTime.now().year} KYRIAN CO. ALL RIGHTS RESERVED.',
                recentBuilds: releases,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlayerAboutData {
  const _PlayerAboutData({required this.packageInfo, required this.releases});

  final PackageInfo packageInfo;
  final List<AppBuildUpdate> releases;
}

import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<_PlayerAboutData> _loadAboutData() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final releases = await AppReleaseNotes.loadRecentBuildUpdates();
    return _PlayerAboutData(packageInfo: packageInfo, releases: releases);
  }

  @override
  Widget build(BuildContext context) {
    return CBNeonBackground(
      child: SafeArea(
        child: FutureBuilder<_PlayerAboutData>(
          future: _loadAboutData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final packageInfo = snapshot.data?.packageInfo;
            final releases = snapshot.data?.releases ?? const <AppBuildUpdate>[];
            final releaseDate = releases.isNotEmpty
                ? DateFormat.yMMMd().format(releases.first.releaseDate)
                : 'Unknown release date';

            final versionLabel = packageInfo == null
                ? 'Unknown version'
                : '${packageInfo.version} (Build ${packageInfo.buildNumber})';

            return CBAboutContent(
              appHeading: 'CLUB BLACKOUT: REBORN',
              appSubtitle: 'PLAYER COMPANION APP',
              versionLabel: versionLabel,
              releaseDateLabel: releaseDate,
              creditsLabel: 'Kim, Val, Lilo, Stitch and Mushu Kyrian',
              copyrightLabel:
                  '© ${DateTime.now().year} Kyrian Co. All rights reserved.',
              recentBuilds: releases,
            );
          },
        ),
      ),
    );
  }
}

class _PlayerAboutData {
  const _PlayerAboutData({required this.packageInfo, required this.releases});

  final PackageInfo packageInfo;
  final List<AppBuildUpdate> releases;
}
import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../auth/auth_provider.dart';
import '../auth/host_auth_screen.dart';
import '../cloud_host_bridge.dart';
import '../host_settings.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(hostSettingsProvider);
    final notifier = ref.read(hostSettingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'SETTINGS',
      actions: const [SimulationModeBadgeAction()],
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: CBSpace.x6),
        child: Column(
          children: [
            _buildSectionHeader(context, 'AUDIO CONFIG',
                Icons.volume_up_rounded, scheme.secondary),
            _buildAudioSettings(context, settings, notifier, scheme),
            const SizedBox(height: CBSpace.x6),
            _buildSectionHeader(
                context, 'DISPLAY', Icons.monitor_rounded, scheme.primary),
            _buildDisplaySettings(context, settings, notifier, scheme),
            const SizedBox(height: CBSpace.x6),
            _buildSectionHeader(context, 'CLOUD LINK', Icons.cloud_done_rounded,
                scheme.primary),
            _buildCloudAccessSettings(context, scheme),
            const SizedBox(height: CBSpace.x6),
            _buildSectionHeader(context, 'DATA MANAGEMENT',
                Icons.storage_rounded, scheme.error),
            _buildDataSettings(context, scheme),
            const SizedBox(height: CBSpace.x8),
            _buildAboutSection(scheme, _packageInfo),
            const SizedBox(height: CBSpace.x12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CBSpace.x3),
      child: CBSectionHeader(
        title: title,
        icon: icon,
        color: color,
      ),
    );
  }

  Widget _buildCloudAccessSettings(BuildContext context, ColorScheme scheme) {
    final authState = ref.watch(authProvider);
    final linkState = ref.watch(cloudLinkStateProvider);
    final isAuthenticated = authState.user != null;
    final isLoading = authState.status == AuthStatus.loading;
    final isBusy = linkState.phase == CloudLinkPhase.initializing ||
        linkState.phase == CloudLinkPhase.publishing ||
        linkState.phase == CloudLinkPhase.verifying;
    final isVerified = linkState.isVerified;
    final isDegraded = linkState.phase == CloudLinkPhase.degraded;
    final userIdentity = authState.user?.email?.trim().isNotEmpty == true
        ? authState.user!.email!.trim()
        : (authState.user?.displayName?.trim().isNotEmpty == true
            ? authState.user!.displayName!.trim()
            : 'HOST');

    final statusLabel = isVerified
        ? 'LINK VERIFIED'
        : (isBusy
            ? 'LINK ESTABLISHING'
            : (isDegraded
                ? 'LINK DEGRADED'
                : (isAuthenticated ? 'LINK OFFLINE' : 'OFFLINE MODE')));
    final statusColor = isVerified
        ? scheme.tertiary
        : (isDegraded
            ? scheme.error
            : (isBusy ? scheme.primary : scheme.onSurface));

    return CBPanel(
      borderColor: scheme.tertiary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAuthenticated ? Icons.link_rounded : Icons.link_off_rounded,
                color: isAuthenticated
                    ? scheme.tertiary
                    : scheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: CBTypography.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      isAuthenticated
                          ? userIdentity.toUpperCase()
                          : 'SIGN IN FOR CLOUD HOSTING',
                      style: CBTypography.bodySmall.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((linkState.message ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: CBSpace.x2),
            Text(
              linkState.message!,
              style: CBTypography.bodySmall.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
          const SizedBox(height: CBSpace.x5),
          if (!isAuthenticated)
            SizedBox(
              width: double.infinity,
              child: CBPrimaryButton(
                label: 'SIGN IN HOST',
                backgroundColor: scheme.tertiary.withValues(alpha: 0.2),
                foregroundColor: scheme.tertiary,
                onPressed: isLoading
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HostAuthScreen(),
                          ),
                        );

                        if (!context.mounted) return;

                        final refreshedState = ref.read(authProvider);
                        if (refreshedState.user != null) {
                          showThemedSnackBar(
                            context,
                            'HOST SIGN-IN COMPLETE.',
                            accentColor: scheme.tertiary,
                          );
                        } else {
                          showThemedSnackBar(
                            context,
                            'SIGN-IN REQUIRED FOR CLOUD HOSTING.',
                            accentColor: scheme.error,
                          );
                        }
                      },
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: CBPrimaryButton(
                    label: isVerified ? 'RE-VERIFY LINK' : 'ESTABLISH LINK',
                    icon: Icons.cloud_sync_rounded,
                    onPressed: (isLoading || isBusy)
                        ? null
                        : () async {
                            final controller = ref.read(gameProvider.notifier);
                            if (ref.read(gameProvider).syncMode !=
                                SyncMode.cloud) {
                              controller.setSyncMode(SyncMode.cloud);
                            }
                            try {
                              await ref.read(cloudHostBridgeProvider).start();
                              if (!context.mounted) return;
                              showThemedSnackBar(
                                context,
                                'CLOUD LINK VERIFIED.',
                                accentColor: scheme.tertiary,
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              showThemedSnackBar(
                                context,
                                'CLOUD LINK FAILED. RETRY REQUIRED.',
                                accentColor: scheme.error,
                              );
                            }
                          },
                  ),
                ),
                const SizedBox(width: CBSpace.x3),
                Expanded(
                  child: CBGhostButton(
                    label: 'TERMINATE LINK',
                    icon: Icons.cloud_off_rounded,
                    color: scheme.secondary,
                    onPressed: (isLoading || isBusy)
                        ? null
                        : () async {
                            await ref.read(cloudHostBridgeProvider).stop();
                            if (!context.mounted) return;
                            showThemedSnackBar(
                              context,
                              'CLOUD LINK TERMINATED.',
                              accentColor: scheme.secondary,
                            );
                          },
                  ),
                ),
              ],
            ),
          if (isAuthenticated) ...[
            const SizedBox(height: CBSpace.x3),
            SizedBox(
              width: double.infinity,
              child: CBGhostButton(
                label: 'SIGN OUT HOST',
                color: scheme.tertiary,
                onPressed: isLoading
                    ? null
                    : () async {
                        final confirmed = await showCBDiscardChangesDialog(
                          context,
                          title: 'SIGN OUT',
                          message:
                              'Sign out of your host account? Cloud features will go offline.',
                          confirmLabel: 'SIGN OUT',
                        );

                        if (!confirmed || !context.mounted) return;

                        await ref.read(cloudHostBridgeProvider).stop();
                        await ref.read(authProvider.notifier).signOut();
                        if (!context.mounted) return;
                        showThemedSnackBar(
                          context,
                          'HOST SIGNED OUT. CLOUD OFFLINE.',
                          accentColor: scheme.tertiary,
                        );
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioSettings(
    BuildContext context,
    HostSettings settings,
    HostSettingsNotifier notifier,
    ColorScheme scheme,
  ) {
    return CBPanel(
      borderColor: scheme.secondary.withValues(alpha: 0.35),
      child: Column(
        children: [
          CBSettingSliderRow(
            title: 'MUSIC LEVEL',
            value: settings.musicVolume,
            color: scheme.secondary,
            onChanged: (v) => notifier.setMusicVolume(v),
          ),
          const SizedBox(height: CBSpace.x4),
          CBSettingSliderRow(
            title: 'SFX LEVEL',
            value: settings.sfxVolume,
            color: scheme.secondary,
            onChanged: (v) => notifier.setSfxVolume(v),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySettings(
    BuildContext context,
    HostSettings settings,
    HostSettingsNotifier notifier,
    ColorScheme scheme,
  ) {
    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.35),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HIGH CONTRAST MODE',
                    style: CBTypography.labelSmall.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    'INCREASED VISIBILITY',
                    style: CBTypography.labelSmall.copyWith(
                      fontSize: 8,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              CBSwitch(
                value: settings.highContrast,
                onChanged: (v) => notifier.setHighContrast(v),
                color: scheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataSettings(BuildContext context, ColorScheme scheme) {
    return CBPanel(
      borderColor: scheme.error.withValues(alpha: 0.35),
      child: Column(
        children: [
          CBSettingActionRow(
            title: 'PURGE HALL OF FAME',
            subtitle: 'PERMANENTLY DELETE ALL RECORDS',
            icon: Icons.delete_forever_rounded,
            color: scheme.error,
            onTap: () => _confirmClearData(context),
          ),
          Divider(
            color: scheme.onSurface.withValues(alpha: 0.1),
            height: 24,
          ),
          CBSettingActionRow(
            title: 'RESET ACTIVE SESSION',
            subtitle: 'CLEAR STUCK GAME STATES',
            icon: Icons.restore_page_rounded,
            color: scheme.error,
            onTap: () => _confirmClearSession(context, scheme.error),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(ColorScheme scheme, PackageInfo? packageInfo) {
    final versionText = packageInfo != null
        ? 'v${packageInfo.version} (BUILD ${packageInfo.buildNumber})'
        : 'VERSION LOADING...';
    return Center(
      child: Column(
        children: [
          Text(
            'CLUB BLACKOUT: REBORN',
            style: CBTypography.h3.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: CBSpace.x2),
          Text(
            versionText,
            style: CBTypography.labelSmall.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.3),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }


  void _confirmClearData(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showThemedDialog(
      context: context,
      accentColor: scheme.error,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.error, size: 48),
          const SizedBox(height: CBSpace.x4),
          Text(
            'CONFIRM PURGE',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.error,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w900,
                  shadows: CBColors.textGlow(scheme.error, intensity: 0.55),
                ),
          ),
          const SizedBox(height: CBSpace.x3),
          Text(
            'IRREVERSIBLE ACTION. ALL HALL OF FAME RECORDS WILL BE WIPED.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'ABORT',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: CBSpace.x3),
              CBPrimaryButton(
                fullWidth: false,
                label: 'EXECUTE PURGE',
                backgroundColor: scheme.error,
                onPressed: () async {
                  await PersistenceService.instance.clearGameRecords();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmClearSession(BuildContext context, Color color) {
    showThemedDialog(
      context: context,
      accentColor: color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restore_page_rounded, color: color, size: 48),
          const SizedBox(height: CBSpace.x4),
          Text(
            'RESET SESSION',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w900,
                  shadows: CBColors.textGlow(color, intensity: 0.55),
                ),
          ),
          const SizedBox(height: CBSpace.x3),
          Text(
            'CLEARS ACTIVE GAME STATE. USE ONLY IF THE SYSTEM IS UNRESPONSIVE.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                  height: 1.4,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'ABORT',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: CBSpace.x3),
              CBPrimaryButton(
                fullWidth: false,
                label: 'RESET',
                backgroundColor: color,
                onPressed: () async {
                  await PersistenceService.instance.clearActiveGame();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

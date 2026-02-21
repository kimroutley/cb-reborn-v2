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
import '../widgets/personality_picker_modal.dart';
import '../widgets/simulation_mode_badge_action.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _packageInfo;
  bool _isPreviewLoading = false;
  String? _previewText;

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

  Future<void> _generatePreview(HostPersonality personality) async {
    setState(() {
      _isPreviewLoading = true;
      _previewText = null;
    });

    try {
      final gemini = ref.read(geminiNarrationServiceProvider);
      final text = await gemini.generatePersonalityPreview(
        voice: personality.voice,
        variationPrompt: personality.variationPrompt,
      );
      if (mounted) {
        setState(() {
          _previewText = text;
          _isPreviewLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewText = 'Failed to connect to the club...';
          _isPreviewLoading = false;
        });
      }
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            _buildSectionHeader(context, 'AUDIO CONFIG', Icons.volume_up_rounded, scheme.secondary),
            _buildAudioSettings(context, settings, notifier, scheme),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'AI NARRATION', Icons.auto_awesome_rounded, scheme.tertiary),
            _buildNarrationSettings(context, settings, notifier, scheme),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'DISPLAY', Icons.monitor_rounded, scheme.primary),
            _buildDisplaySettings(context, settings, notifier, scheme),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'CLOUD LINK', Icons.cloud_done_rounded, scheme.primary),
            _buildCloudAccessSettings(context, scheme),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'DATA MANAGEMENT', Icons.storage_rounded, scheme.error),
            _buildDataSettings(context, scheme),
            const SizedBox(height: 32),
            _buildAboutSection(scheme, _packageInfo),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
    final isAuthenticated = authState.status == AuthStatus.authenticated;
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
                color: isAuthenticated ? scheme.tertiary : scheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
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
            const SizedBox(height: 8),
            Text(
              linkState.message!,
              style: CBTypography.bodySmall.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
          const SizedBox(height: 20),
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
                        if (refreshedState.status == AuthStatus.authenticated) {
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
                            if (ref.read(gameProvider).syncMode != SyncMode.cloud) {
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
                const SizedBox(width: 10),
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: CBGhostButton(
                label: 'SIGN OUT HOST',
                color: scheme.tertiary,
                onPressed: isLoading
                    ? null
                    : () async {
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
          _buildSlider(
            context,
            'MUSIC LEVEL',
            settings.musicVolume,
            scheme.secondary,
            (v) => notifier.setMusicVolume(v),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            context,
            'SFX LEVEL',
            settings.sfxVolume,
            scheme.secondary,
            (v) => notifier.setSfxVolume(v),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrationSettings(
    BuildContext context,
    HostSettings settings,
    HostSettingsNotifier notifier,
    ColorScheme scheme,
  ) {
    return CBPanel(
      borderColor: scheme.tertiary.withValues(alpha: 0.35),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI NARRATION ENGINE',
                style: CBTypography.labelSmall.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              CBSwitch(
                value: settings.geminiNarrationEnabled,
                onChanged: (v) => notifier.setGeminiNarrationEnabled(v),
                color: scheme.tertiary,
              ),
            ],
          ),
          if (settings.geminiNarrationEnabled) ...[
            const SizedBox(height: 24),
            _buildPersonalitySelector(context, settings, notifier, scheme),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalitySelector(
    BuildContext context,
    HostSettings settings,
    HostSettingsNotifier notifier,
    ColorScheme scheme,
  ) {
    final currentPersonality = hostPersonalities.firstWhere(
      (p) => p.id == settings.hostPersonalityId,
      orElse: () => hostPersonalities.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOST PERSONALITY MODULE',
          style: CBTypography.labelSmall.copyWith(
            color: scheme.tertiary.withValues(alpha: 0.8),
            fontSize: 9,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        CBGlassTile(
          borderColor: scheme.tertiary.withValues(alpha: 0.4),
          isPrismatic: true,
          padding: EdgeInsets.zero,
          onTap: () => _showPersonalityPicker(context, settings, notifier),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentPersonality.name.toUpperCase(),
                        style: CBTypography.labelLarge.copyWith(
                          color: scheme.tertiary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentPersonality.description,
                        style: CBTypography.bodySmall.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.unfold_more_rounded, color: scheme.tertiary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CBGhostButton(
            label: 'TEST VOICE SYNTHESIS',
            color: scheme.tertiary,
            onPressed: () => _showPreviewDialog(context, currentPersonality),
          ),
        ),
      ],
    );
  }

  void _showPreviewDialog(BuildContext context, HostPersonality personality) {
    final scheme = Theme.of(context).colorScheme;
    _generatePreview(personality);

    showThemedDialog(
      context: context,
      accentColor: scheme.tertiary,
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VOICE CHECK: ${personality.name.toUpperCase()}',
                style: CBTypography.labelLarge.copyWith(
                  color: scheme.tertiary,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  shadows: CBColors.textGlow(scheme.tertiary, intensity: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: scheme.tertiary.withValues(alpha: 0.3)),
                ),
                child: _isPreviewLoading
                    ? const Center(
                        child: CBBreathingLoader(size: 32),
                      )
                    : Text(
                        _previewText ?? 'AWAITING INPUT...',
                        style: CBTypography.bodyMedium.copyWith(
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurface.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(height: 32),
              CBPrimaryButton(
                label: 'DISMISS',
                backgroundColor: scheme.tertiary,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPersonalityPicker(
    BuildContext context,
    HostSettings settings,
    HostSettingsNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PersonalityPickerModal(
        selectedPersonalityId: settings.hostPersonalityId,
        onPersonalitySelected: (id) {
          notifier.setHostPersonalityId(id);
          Navigator.pop(context);
        },
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
          _buildActionRow(
            context,
            'PURGE HALL OF FAME',
            'PERMANENTLY DELETE ALL RECORDS',
            Icons.delete_forever_rounded,
            scheme.error,
            () => _confirmClearData(context),
          ),
          Divider(
            color: scheme.onSurface.withValues(alpha: 0.1),
            height: 24,
          ),
          _buildActionRow(
            context,
            'RESET ACTIVE SESSION',
            'CLEAR STUCK GAME STATES',
            Icons.restore_page_rounded,
            scheme.error,
            () => _confirmClearSession(context, scheme.error),
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
          const SizedBox(height: 8),
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

  Widget _buildSlider(
    BuildContext context,
    String label,
    double value,
    Color accentColor,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: CBTypography.labelSmall.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: CBTypography.labelSmall.copyWith(
                color: accentColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        CBSlider(
          value: value,
          onChanged: onChanged,
          color: accentColor,
        ),
      ],
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CBTypography.labelSmall.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: CBTypography.bodySmall.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
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
          const SizedBox(height: 16),
          Text(
            'CONFIRM PURGE',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.error,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w900,
                  shadows: CBColors.textGlow(scheme.error, intensity: 0.55),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'IRREVERSIBLE ACTION. ALL HALL OF FAME RECORDS WILL BE WIPED.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'ABORT',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 16),
          Text(
            'RESET SESSION',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w900,
                  shadows: CBColors.textGlow(color, intensity: 0.55),
                ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'ABORT',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
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

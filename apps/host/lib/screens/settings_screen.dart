import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
      title: 'Settings',
      drawer: const CustomDrawer(),
      actions: const [SimulationModeBadgeAction()],
      body: SingleChildScrollView(
        padding: CBInsets.screen,
        child: Column(
          children: [
            _buildSectionHeader(context, 'Audio'),
            _buildAudioSettings(context, settings, notifier, scheme),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'AI & Narration'),
            _buildNarrationSettings(context, settings, notifier, scheme),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Display'),
            _buildDisplaySettings(context, settings, notifier, scheme),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Game Data'),
            _buildDataSettings(context, scheme),
            const SizedBox(height: 24),
            _buildAboutSection(scheme, _packageInfo),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CBSectionHeader(title: title),
    );
  }

  Widget _buildAudioSettings(
    BuildContext context,
    HostSettings settings,
    HostSettingsNotifier notifier,
    ColorScheme scheme,
  ) {
    return CBGlassTile(
      title: 'Audio',
      accentColor: scheme.secondary,
      isPrismatic: true,
      content: Column(
        children: [
          _buildSlider(
            context,
            'Music Volume',
            settings.musicVolume,
            scheme.primary,
            (v) => notifier.setMusicVolume(v),
          ),
          _buildSlider(
            context,
            'SFX Volume',
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
    return CBGlassTile(
      title: 'AI Narrator',
      accentColor: scheme.tertiary,
      isPrismatic: true,
      content: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Enable Gemini Narration', style: CBTypography.body),
              CBSwitch(
                value: settings.geminiNarrationEnabled,
                onChanged: (v) => notifier.setGeminiNarrationEnabled(v),
                color: scheme.tertiary,
              ),
            ],
          ),
          if (settings.geminiNarrationEnabled) ...[
            const SizedBox(height: 20),
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
          'HOST PERSONALITY',
          style: CBTypography.micro.copyWith(color: scheme.tertiary),
        ),
        const SizedBox(height: 8),
        CBGlassTile(
          title: 'Host Personality',
          accentColor: scheme.tertiary,
          content: InkWell(
            onTap: () => _showPersonalityPicker(context, settings, notifier),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentPersonality.name,
                          style: CBTypography.bodyBold),
                      const SizedBox(height: 4),
                      Text(
                        currentPersonality.description,
                        style: CBTypography.caption,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.unfold_more, color: scheme.tertiary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: CBGhostButton(
            label: 'PREVIEW VOICE',
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
                '${personality.name.toUpperCase()} PREVIEW',
                style: CBTypography.micro.copyWith(
                  color: scheme.tertiary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: scheme.tertiary.withValues(alpha: 0.2)),
                ),
                child: _isPreviewLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : Text(
                        _previewText ?? 'Silence...',
                        style: CBTypography.body.copyWith(
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(height: 24),
              CBPrimaryButton(
                label: 'CLOSE',
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
    return CBGlassTile(
      title: 'Display',
      accentColor: scheme.primary,
      isPrismatic: true,
      content: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('High Contrast Mode', style: CBTypography.body),
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
    return CBGlassTile(
      title: 'Game Data',
      accentColor: scheme.error,
      isPrismatic: true,
      content: Column(
        children: [
          _buildActionRow(
            context,
            'Clear Hall of Fame',
            'Permanently delete all player stats.',
            Icons.delete_forever,
            scheme.error,
            () => _confirmClearData(context),
          ),
          Divider(
            color: scheme.onSurface.withValues(alpha: 0.2),
            height: 16,
          ),
          _buildActionRow(
            context,
            'Reset Active Session',
            'Clear the current game state if stuck.',
            Icons.restore,
            scheme.error,
            () => _confirmClearSession(context, scheme.error),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(ColorScheme scheme, PackageInfo? packageInfo) {
    final versionText = packageInfo != null
        ? 'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})'
        : 'Version Loading...';
    return Center(
      child: Column(
        children: [
          Text(
            'Club Blackout: Reborn',
            style: CBTypography.h2.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            versionText,
            style: CBTypography.caption,
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
            Text(label, style: CBTypography.body),
            Text('${(value * 100).toInt()}%', style: CBTypography.caption),
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CBTypography.bodyBold),
                  Text(subtitle, style: CBTypography.caption),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
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
            'CLEAR DATA',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.error,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows: CBColors.textGlow(scheme.error, intensity: 0.55),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This action cannot be undone. All Hall of Fame records will be lost.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  height: 1.3,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: 'DELETE ALL',
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
          Icon(Icons.restore, color: color, size: 48),
          const SizedBox(height: 16),
          Text(
            'RESET SESSION',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows: CBColors.textGlow(color, intensity: 0.55),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This will clear any active game state. Use this if the app is stuck.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  height: 1.3,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
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

import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../active_bridge.dart';
import '../cloud_player_bridge.dart';
import '../notifications_prompt_provider.dart';
import '../services/push_notification_service.dart';
import '../services/push_subscription_register.dart';

/// Shows "Get notified when it's your turn" and optionally "Install app" when in cloud mode (web).
/// Renders nothing on non-web or when notifications are already granted and app is installed.
class NotificationsPromptBanner extends ConsumerStatefulWidget {
  const NotificationsPromptBanner({super.key});

  @override
  ConsumerState<NotificationsPromptBanner> createState() =>
      _NotificationsPromptBannerState();
}

class _NotificationsPromptBannerState
    extends ConsumerState<NotificationsPromptBanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsPromptProvider.notifier).loadAskedBefore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bridge = ref.watch(activeBridgeProvider);
    final isCloud = bridge.isCloud;
    final isConnected = bridge.state.isConnected;
    if (!isCloud || !isConnected) return const SizedBox.shrink();

    final supported = isNotificationPermissionSupported;
    final installAvailable = isPwaInstallPromptAvailable;
    final promptState = ref.watch(notificationsPromptProvider);

    if (!supported && !installAvailable) return const SizedBox.shrink();
    if (supported && promptState.isGranted && !installAvailable) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      child: CBGlassTile(
        borderColor: scheme.primary.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: scheme.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Stay in the loop',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Get notified when it\'s your turn — even if the app is closed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (supported && !promptState.isGranted)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilledButton.tonal(
                    onPressed: promptState.isRequesting
                        ? null
                        : () async {
                            final result = await ref
                                .read(notificationsPromptProvider.notifier)
                                .requestPermission();
                            if (result == NotificationPermission.granted &&
                                vapidPublicKeyBase64.isNotEmpty) {
                              final sub = await getPushSubscription(
                                  vapidPublicKeyBase64);
                              if (sub != null && mounted) {
                                await ref
                                    .read(cloudPlayerBridgeProvider.notifier)
                                    .registerPushSubscription(sub);
                              }
                            }
                          },
                    child: promptState.isRequesting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimaryContainer,
                            ),
                          )
                        : const Text('Enable'),
                  ),
                ),
              if (installAvailable) ...[
                if (supported && !promptState.isGranted) const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    await showPwaInstallPrompt();
                  },
                  child: const Text('Install app'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

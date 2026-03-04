import '../notifications_prompt_provider.dart';

bool get isNotificationPermissionSupported => false;

bool get isPwaInstallPromptAvailable => false;

bool checkNotificationPermissionGranted() => false;

Future<NotificationPermission> requestNotificationPermission() async =>
    NotificationPermission.denied;

void initPwaInstallListener() {}

Future<void> showPwaInstallPrompt() async {}

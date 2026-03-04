import 'package:flutter/widgets.dart';

/// Temporarily disabled until the notifications/push providers are restored.
/// Keeping this widget prevents import breakages at call sites.
class NotificationsPromptBanner extends StatelessWidget {
  const NotificationsPromptBanner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

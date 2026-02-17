import 'package:cb_models/cb_models.dart';

typedef AsyncOp = Future<void> Function();

Future<void> syncHostBridgesForMode({
  required SyncMode mode,
  required AsyncOp stopLocal,
  required AsyncOp startLocal,
  required AsyncOp stopCloud,
  required AsyncOp startCloud,
}) async {
  if (mode == SyncMode.cloud) {
    await stopLocal();
    await startCloud();
    return;
  }

  await stopCloud();
  await startLocal();
}

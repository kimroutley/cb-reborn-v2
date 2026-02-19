/// Player-safe exports — excludes `host_server.dart` which depends on `dart:io`
/// and is not available on the web platform.
library cb_comms_player;

export 'src/firebase_bridge.dart';
export 'src/game_message.dart';
export 'src/player_client.dart';
export 'src/profile_avatar_catalog.dart';
export 'src/profile_form_validation.dart';
export 'src/profile_repository.dart';

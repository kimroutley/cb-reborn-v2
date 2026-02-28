// Re-export @freezed models now living in cb_models for backward compat
export 'package:cb_models/cb_models.dart'
    show
        GameState,
        SessionState,
        generateJoinCode,
        GameRecord,
        GameRecordPlayerSnapshot,
        GameStats,
        GamesNightRecord;

export 'src/game_provider.dart';
export 'src/session_provider.dart';
export 'src/games_night_provider.dart';
export 'src/player_matcher.dart';
export 'src/recap_generator.dart';
export 'src/scripting/script_builder.dart';
export 'src/scripting/role_logic.dart';
export 'src/scripting/step_key.dart';
export 'src/persistence/persistence_service.dart';
export 'src/strategy_generator.dart';
export 'src/analytics_service.dart';
export 'src/firebase_analytics_provider.dart';
export 'src/gemini_narration_service.dart';
export 'src/room_effects_provider.dart';
export 'src/role_award_progress_service.dart';
export 'src/chat_provider.dart';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'script_action_type.dart';

part 'script_step.freezed.dart';
part 'script_step.g.dart';

@freezed
abstract class ScriptStep with _$ScriptStep {
  const factory ScriptStep({
    required String id,
    required String title,
    required String readAloudText,
    required String instructionText,
    @Default(ScriptActionType.none) ScriptActionType actionType,

    // Context fields used by UI/Logic to know what to display/filter
    String? roleId, // If this step belongs to a specific role (e.g. 'medic')

    @Default([])
    List<String> options, // For binary choice labels or specific options

    // Optional metadata
    @Default(false) bool isOptional,
    int? timerSeconds,
    String? assetPath, // Image to show

    // Optional ambient room directives for synced FX/audio.
    String? effectType,
    String? soundId,

    // Optional AI variation hooks for dynamic narration pipelines.
    String? aiVariationPrompt,
    String? aiVariationVoice,
  }) = _ScriptStep;

  factory ScriptStep.fromJson(Map<String, dynamic> json) =>
      _$ScriptStepFromJson(json);
}

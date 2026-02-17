class StepKey {
  static bool isDayVoteStep(String stepId) => stepId.startsWith('day_vote');

  static String? extractScopedPlayerId({
    required String stepId,
    required String prefix,
  }) {
    if (!stepId.startsWith(prefix)) return null;
    final scoped = stepId.substring(prefix.length);

    final parts = scoped.split('_');
    if (parts.isEmpty) return null;

    final lastPart = parts.last;
    if (int.tryParse(lastPart) != null && parts.length > 1) {
      return parts.sublist(0, parts.length - 1).join('_');
    }

    return scoped;
  }

  static String roleAction({
    required String roleId,
    required String playerId,
    required int dayCount,
  }) {
    return '${roleId}_act_${playerId}_$dayCount';
  }

  static String roleVerbAction({
    required String roleId,
    required String verb,
    required String playerId,
    required int dayCount,
  }) {
    return '${roleId}_${verb}_${playerId}_$dayCount';
  }

  static String setupAction({
    required String setupId,
    required String playerId,
    required int dayCount,
  }) {
    return '${setupId}_${playerId}_$dayCount';
  }
}

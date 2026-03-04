class PlayerVotingStats {
  final int totalVotes;
  final int dealerVotes;
  final int successfulExiles;

  const PlayerVotingStats({
    this.totalVotes = 0,
    this.dealerVotes = 0,
    this.successfulExiles = 0,
  });

  PlayerVotingStats copyWith({
    int? totalVotes,
    int? dealerVotes,
    int? successfulExiles,
  }) {
    return PlayerVotingStats(
      totalVotes: totalVotes ?? this.totalVotes,
      dealerVotes: dealerVotes ?? this.dealerVotes,
      successfulExiles: successfulExiles ?? this.successfulExiles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalVotes': totalVotes,
      'dealerVotes': dealerVotes,
      'successfulExiles': successfulExiles,
    };
  }

  factory PlayerVotingStats.fromJson(Map<String, dynamic> json) {
    return PlayerVotingStats(
      totalVotes: json['totalVotes'] as int? ?? 0,
      dealerVotes: json['dealerVotes'] as int? ?? 0,
      successfulExiles: json['successfulExiles'] as int? ?? 0,
    );
  }
}

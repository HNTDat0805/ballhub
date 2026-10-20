class MatchAudit {
  final String id;
  final String tournamentId;
  final String matchId;
  final String action;
  final int? oldHomeScore;
  final int? oldAwayScore;
  final int? newHomeScore;
  final int? newAwayScore;
  final String updatedBy;
  final DateTime updatedAt;
  final String? reason;

  const MatchAudit({
    required this.id,
    required this.tournamentId,
    required this.matchId,
    required this.action,
    this.oldHomeScore,
    this.oldAwayScore,
    this.newHomeScore,
    this.newAwayScore,
    required this.updatedBy,
    required this.updatedAt,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'matchId': matchId,
      'action': action,
      'oldHomeScore': oldHomeScore,
      'oldAwayScore': oldAwayScore,
      'newHomeScore': newHomeScore,
      'newAwayScore': newAwayScore,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt.toIso8601String(),
      'reason': reason,
    };
  }

  factory MatchAudit.fromMap(Map<dynamic, dynamic> map, String id) {
    return MatchAudit(
      id: id,
      tournamentId: map['tournamentId'] as String? ?? '',
      matchId: map['matchId'] as String? ?? '',
      action: map['action'] as String? ?? 'update',
      oldHomeScore: (map['oldHomeScore'] as num?)?.toInt(),
      oldAwayScore: (map['oldAwayScore'] as num?)?.toInt(),
      newHomeScore: (map['newHomeScore'] as num?)?.toInt(),
      newAwayScore: (map['newAwayScore'] as num?)?.toInt(),
      updatedBy: map['updatedBy'] as String? ?? 'Admin',
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      reason: map['reason'] as String?,
    );
  }
}

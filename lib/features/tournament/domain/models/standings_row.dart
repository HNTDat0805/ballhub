class StandingsRow {
  final String teamId;
  final String teamName;
  final String logoUrl;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final int rank;

  const StandingsRow({
    required this.teamId,
    required this.teamName,
    this.logoUrl = '',
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    required this.rank,
  });

  StandingsRow copyWith({
    String? teamId,
    String? teamName,
    String? logoUrl,
    int? played,
    int? won,
    int? drawn,
    int? lost,
    int? goalsFor,
    int? goalsAgainst,
    int? goalDifference,
    int? points,
    int? rank,
  }) {
    return StandingsRow(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      logoUrl: logoUrl ?? this.logoUrl,
      played: played ?? this.played,
      won: won ?? this.won,
      drawn: drawn ?? this.drawn,
      lost: lost ?? this.lost,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      goalDifference: goalDifference ?? this.goalDifference,
      points: points ?? this.points,
      rank: rank ?? this.rank,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'logoUrl': logoUrl,
      'played': played,
      'won': won,
      'drawn': drawn,
      'lost': lost,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'goalDifference': goalDifference,
      'points': points,
      'rank': rank,
    };
  }

  factory StandingsRow.fromMap(Map<dynamic, dynamic> map, String teamId) {
    return StandingsRow(
      teamId: teamId,
      teamName: map['teamName'] as String? ?? 'Đội bóng',
      logoUrl: map['logoUrl'] as String? ?? '',
      played: (map['played'] as num?)?.toInt() ?? 0,
      won: (map['won'] as num?)?.toInt() ?? 0,
      drawn: (map['drawn'] as num?)?.toInt() ?? 0,
      lost: (map['lost'] as num?)?.toInt() ?? 0,
      goalsFor: (map['goalsFor'] as num?)?.toInt() ?? 0,
      goalsAgainst: (map['goalsAgainst'] as num?)?.toInt() ?? 0,
      goalDifference: (map['goalDifference'] as num?)?.toInt() ?? 0,
      points: (map['points'] as num?)?.toInt() ?? 0,
      rank: (map['rank'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Trạng thái diễn ra của trận đấu bóng đá
enum MatchStatus {
  /// Trận đấu theo lịch sắp xếp, chưa bắt đầu
  scheduled,

  /// Trận đấu đang diễn ra trên sân
  inProgress,

  /// Trận đấu đã kết thúc thời gian thi đấu chính thức
  finished,

  /// Trận đấu tạm hoãn (do thời tiết hoặc sự cố)
  postponed,

  /// Trận đấu đã bị hủy bỏ
  cancelled;

  String get displayName => switch (this) {
        MatchStatus.scheduled => 'Chưa diễn ra',
        MatchStatus.inProgress => 'Đang diễn ra',
        MatchStatus.finished => 'Đã kết thúc',
        MatchStatus.postponed => 'Bị hoãn',
        MatchStatus.cancelled => 'Đã hủy',
      };
}

/// Mô hình một trận đấu trong giải bóng đá
class TournamentMatch {
  final String id;
  final String tournamentId;
  final int round;
  final String roundName;
  final String homeTeamId;
  final String homeTeamName;
  final String awayTeamId;
  final String awayTeamName;
  final DateTime scheduledTime;
  final String venue;
  final MatchStatus status;
  final int? homeScore;
  final int? awayScore;
  final bool isConfirmed;
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final String? notes;

  const TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.roundName,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.scheduledTime,
    required this.venue,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.isConfirmed = false,
    this.confirmedBy,
    this.confirmedAt,
    this.notes,
  });

  /// Kiểm tra xem tỷ số đã được nhập hợp lệ (không null và không âm) hay chưa
  bool get hasValidScore =>
      homeScore != null &&
      awayScore != null &&
      homeScore! >= 0 &&
      awayScore! >= 0;

  /// Kết quả chính thức: trận đấu đã kết thúc, tỷ số hợp lệ và đã được Ban tổ chức phê duyệt
  bool get isOfficialResult => status == MatchStatus.finished && isConfirmed && hasValidScore;

  /// Chuỗi hiển thị tỷ số ngắn gọn ('3 - 1' hoặc 'vs' nếu chưa có tỷ số)
  String get scoreDisplay {
    if (homeScore != null && awayScore != null) {
      return '$homeScore - $awayScore';
    }
    return 'vs';
  }

  TournamentMatch copyWith({
    String? id,
    String? tournamentId,
    int? round,
    String? roundName,
    String? homeTeamId,
    String? homeTeamName,
    String? awayTeamId,
    String? awayTeamName,
    DateTime? scheduledTime,
    String? venue,
    MatchStatus? status,
    int? homeScore,
    int? awayScore,
    bool? isConfirmed,
    String? confirmedBy,
    DateTime? confirmedAt,
    String? notes,
  }) {
    return TournamentMatch(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      round: round ?? this.round,
      roundName: roundName ?? this.roundName,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'round': round,
      'roundName': roundName,
      'homeTeamId': homeTeamId,
      'homeTeamName': homeTeamName,
      'awayTeamId': awayTeamId,
      'awayTeamName': awayTeamName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'venue': venue,
      'status': status.name,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'isConfirmed': isConfirmed,
      'confirmedBy': confirmedBy,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory TournamentMatch.fromMap(Map<dynamic, dynamic> map, String id) {
    return TournamentMatch(
      id: id,
      tournamentId: map['tournamentId'] as String? ?? '',
      round: (map['round'] as num?)?.toInt() ?? 1,
      roundName: map['roundName'] as String? ?? 'Vòng 1',
      homeTeamId: map['homeTeamId'] as String? ?? '',
      homeTeamName: map['homeTeamName'] as String? ?? 'Đội nhà',
      awayTeamId: map['awayTeamId'] as String? ?? '',
      awayTeamName: map['awayTeamName'] as String? ?? 'Đội khách',
      scheduledTime: DateTime.tryParse(map['scheduledTime'] as String? ?? '') ?? DateTime.now(),
      venue: map['venue'] as String? ?? 'Sân chính',
      status: MatchStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => MatchStatus.scheduled,
      ),
      homeScore: (map['homeScore'] as num?)?.toInt(),
      awayScore: (map['awayScore'] as num?)?.toInt(),
      isConfirmed: map['isConfirmed'] as bool? ?? false,
      confirmedBy: map['confirmedBy'] as String?,
      confirmedAt: map['confirmedAt'] != null ? DateTime.tryParse(map['confirmedAt'] as String) : null,
      notes: map['notes'] as String?,
    );
  }
}

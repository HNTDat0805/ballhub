enum RegistrationStatus {
  pending,
  approved,
  rejected,
  cancelled;

  String get displayName => switch (this) {
        RegistrationStatus.pending => 'Chờ duyệt',
        RegistrationStatus.approved => 'Đã duyệt',
        RegistrationStatus.rejected => 'Từ chối',
        RegistrationStatus.cancelled => 'Đã hủy',
      };
}

class TournamentTeam {
  final String id;
  final String tournamentId;
  final String teamId;
  final String teamName;
  final String logoUrl;
  final String captainId;
  final String captainName;
  final String captainPhone;
  final String captainEmail;
  final int membersCount;
  final RegistrationStatus status;
  final DateTime registeredAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNote;

  const TournamentTeam({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
    this.logoUrl = '',
    required this.captainId,
    required this.captainName,
    required this.captainPhone,
    required this.captainEmail,
    this.membersCount = 11,
    required this.status,
    required this.registeredAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNote,
  });

  bool get isApproved => status == RegistrationStatus.approved;
  bool get isPending => status == RegistrationStatus.pending;

  TournamentTeam copyWith({
    String? id,
    String? tournamentId,
    String? teamId,
    String? teamName,
    String? logoUrl,
    String? captainId,
    String? captainName,
    String? captainPhone,
    String? captainEmail,
    int? membersCount,
    RegistrationStatus? status,
    DateTime? registeredAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNote,
  }) {
    return TournamentTeam(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      logoUrl: logoUrl ?? this.logoUrl,
      captainId: captainId ?? this.captainId,
      captainName: captainName ?? this.captainName,
      captainPhone: captainPhone ?? this.captainPhone,
      captainEmail: captainEmail ?? this.captainEmail,
      membersCount: membersCount ?? this.membersCount,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'teamId': teamId,
      'teamName': teamName,
      'logoUrl': logoUrl,
      'captainId': captainId,
      'captainName': captainName,
      'captainPhone': captainPhone,
      'captainEmail': captainEmail,
      'membersCount': membersCount,
      'status': status.name,
      'registeredAt': registeredAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewNote': reviewNote,
    };
  }

  factory TournamentTeam.fromMap(Map<dynamic, dynamic> map, String id) {
    return TournamentTeam(
      id: id,
      tournamentId: map['tournamentId'] as String? ?? '',
      teamId: map['teamId'] as String? ?? '',
      teamName: map['teamName'] as String? ?? 'Đội bóng',
      logoUrl: map['logoUrl'] as String? ?? '',
      captainId: map['captainId'] as String? ?? '',
      captainName: map['captainName'] as String? ?? '',
      captainPhone: map['captainPhone'] as String? ?? '',
      captainEmail: map['captainEmail'] as String? ?? '',
      membersCount: (map['membersCount'] as num?)?.toInt() ?? 11,
      status: RegistrationStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => RegistrationStatus.pending,
      ),
      registeredAt: DateTime.tryParse(map['registeredAt'] as String? ?? '') ?? DateTime.now(),
      reviewedAt: map['reviewedAt'] != null ? DateTime.tryParse(map['reviewedAt'] as String) : null,
      reviewedBy: map['reviewedBy'] as String?,
      reviewNote: map['reviewNote'] as String?,
    );
  }
}

enum TournamentFormat {
  roundRobinSingle,
  roundRobinDouble,
  knockout;

  String get displayName => switch (this) {
        TournamentFormat.roundRobinSingle => 'Vòng tròn 1 lượt',
        TournamentFormat.roundRobinDouble => 'Vòng tròn 2 lượt (Lượt đi - về)',
        TournamentFormat.knockout => 'Loại trực tiếp (Knockout)',
      };
}

enum TournamentStatus {
  preparing,
  registrationOpen,
  inProgress,
  completed,
  cancelled;

  String get displayName => switch (this) {
        TournamentStatus.preparing => 'Chuẩn bị',
        TournamentStatus.registrationOpen => 'Mở đăng ký',
        TournamentStatus.inProgress => 'Đang diễn ra',
        TournamentStatus.completed => 'Đã kết thúc',
        TournamentStatus.cancelled => 'Đã hủy',
      };
}

class Tournament {
  final String id;
  final String name;
  final String description;
  final String bannerUrl;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationDeadline;
  final int maxTeams;
  final TournamentFormat format;
  final TournamentStatus status;
  final String organizerId;
  final String organizerName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tournament({
    required this.id,
    required this.name,
    required this.description,
    this.bannerUrl = '',
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.registrationDeadline,
    required this.maxTeams,
    required this.format,
    required this.status,
    required this.organizerId,
    required this.organizerName,
    required this.createdAt,
    required this.updatedAt,
  });

  bool canRegister({required DateTime now, required int currentApprovedTeamsCount}) {
    if (status != TournamentStatus.registrationOpen) return false;
    if (now.isAfter(registrationDeadline)) return false;
    if (currentApprovedTeamsCount >= maxTeams) return false;
    return true;
  }

  bool canGenerateSchedule({required int approvedTeamsCount}) {
    if (status != TournamentStatus.registrationOpen && status != TournamentStatus.preparing) {
      return false;
    }
    return approvedTeamsCount >= 2;
  }

  Tournament copyWith({
    String? id,
    String? name,
    String? description,
    String? bannerUrl,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    int? maxTeams,
    TournamentFormat? format,
    TournamentStatus? status,
    String? organizerId,
    String? organizerName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      maxTeams: maxTeams ?? this.maxTeams,
      format: format ?? this.format,
      status: status ?? this.status,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'bannerUrl': bannerUrl,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'registrationDeadline': registrationDeadline.toIso8601String(),
      'maxTeams': maxTeams,
      'format': format.name,
      'status': status.name,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Tournament.fromMap(Map<dynamic, dynamic> map, String id) {
    return Tournament(
      id: id,
      name: map['name'] as String? ?? 'Chưa đặt tên',
      description: map['description'] as String? ?? '',
      bannerUrl: map['bannerUrl'] as String? ?? '',
      location: map['location'] as String? ?? '',
      startDate: DateTime.tryParse(map['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] as String? ?? '') ?? DateTime.now().add(const Duration(days: 7)),
      registrationDeadline: DateTime.tryParse(map['registrationDeadline'] as String? ?? '') ?? DateTime.now(),
      maxTeams: (map['maxTeams'] as num?)?.toInt() ?? 8,
      format: TournamentFormat.values.firstWhere(
        (f) => f.name == map['format'],
        orElse: () => TournamentFormat.roundRobinSingle,
      ),
      status: TournamentStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TournamentStatus.preparing,
      ),
      organizerId: map['organizerId'] as String? ?? '',
      organizerName: map['organizerName'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _toDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// Đại diện cho một đội bóng phong trào trong hệ thống Ballhub.
///
/// Quản lý thông tin cơ bản của đội (tên, khu vực, đội trưởng, số thành viên)
/// và tọa độ địa lý (Google Places) phục vụ tính năng tìm đối / cáp kèo giao hữu.
class Team {
  /// Mã định danh duy nhất của đội bóng
  final String teamId;

  /// Tên đội bóng (ví dụ: FC Sao Vàng)
  final String teamName;

  /// Khu vực hoạt động / sân nhà (ví dụ: Quận Bình Thạnh, TP.HCM)
  final String area;

  /// Mô tả giới thiệu phong cách thi đấu, trình độ
  final String? description;

  /// Mã người dùng của đội trưởng
  final String captainId;

  /// Họ tên đội trưởng
  final String captainName;

  /// Số lượng thành viên hiện tại trong đội
  final int memberCount;

  /// Thời điểm đội bóng được thành lập trên hệ thống
  final DateTime? createdAt;

  /// Google Place ID của địa bàn hoạt động (nếu có)
  final String? placeId;

  /// Tọa độ vĩ độ (Latitude)
  final double? latitude;

  /// Tọa độ kinh độ (Longitude)
  final double? longitude;

  /// Tỉnh / Thành phố
  final String? province;

  /// Quận / Huyện
  final String? district;

  /// Phường / Xã
  final String? ward;

  Team({
    required this.teamId,
    required this.teamName,
    required this.area,
    this.description,
    required this.captainId,
    required this.captainName,
    required this.memberCount,
    this.createdAt,
    this.placeId,
    this.latitude,
    this.longitude,
    this.province,
    this.district,
    this.ward,
  });

  factory Team.fromMap(Map<String, dynamic> m) => Team(
    teamId: (m['teamId'] ?? m['id'] ?? '').toString(),
    teamName: (m['teamName'] ?? m['name'] ?? '').toString(),
    area: (m['area'] ?? m['location'] ?? '').toString(),
    description: m['description']?.toString(),
    captainId: (m['captainId'] ?? m['userId'] ?? '').toString(),
    captainName: (m['captainName'] ?? m['userName'] ?? '').toString(),
    memberCount: (m['memberCount'] as num?)?.toInt() ?? 1,
    createdAt: _toDate(m['createdAt']),
    placeId: m['placeId'] as String?,
    latitude: (m['latitude'] as num?)?.toDouble(),
    longitude: (m['longitude'] as num?)?.toDouble(),
    province: m['province'] as String?,
    district: m['district'] as String?,
    ward: m['ward'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'teamId': teamId,
    'teamName': teamName,
    'area': area,
    if (description != null) 'description': description,
    'captainId': captainId,
    'captainName': captainName,
    'memberCount': memberCount,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (placeId != null && placeId!.isNotEmpty) 'placeId': placeId,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (province != null && province!.isNotEmpty) 'province': province,
    if (district != null && district!.isNotEmpty) 'district': district,
    if (ward != null && ward!.isNotEmpty) 'ward': ward,
  };
}

class TeamMember {
  final String userId;
  final String role; // Captain / Member
  final String fullName;
  final String? avatarBase64;
  final String? position;

  TeamMember({
    required this.userId,
    required this.role,
    required this.fullName,
    this.avatarBase64,
    this.position,
  });

  factory TeamMember.fromMap(Map<String, dynamic> m) => TeamMember(
    userId: m['userId'] ?? '',
    role: m['role'] ?? 'Member',
    fullName: m['fullName'] ?? '(Không rõ)',
    avatarBase64: m['avatarBase64'],
    position: m['position'],
  );
}

class JoinRequest {
  final String requestId;
  final String teamId;
  final String userId;
  final String? message;
  final String fullName;
  final String? avatarBase64;
  final String? position;

  JoinRequest({
    required this.requestId,
    required this.teamId,
    required this.userId,
    this.message,
    required this.fullName,
    this.avatarBase64,
    this.position,
  });

  factory JoinRequest.fromMap(Map<String, dynamic> m) => JoinRequest(
    requestId: m['requestId'] ?? '',
    teamId: m['teamId'] ?? '',
    userId: m['userId'] ?? '',
    message: m['message'],
    fullName: m['fullName'] ?? '(Không rõ)',
    avatarBase64: m['avatarBase64'],
    position: m['position'],
  );
}

class MatchmakingCandidate {
  final Team team;
  final int matchScore;
  final String reason;

  MatchmakingCandidate({
    required this.team,
    required this.matchScore,
    required this.reason,
  });

  factory MatchmakingCandidate.fromMap(Map<String, dynamic> m) =>
      MatchmakingCandidate(
        team: Team.fromMap(Map<String, dynamic>.from(m['team'] as Map)),
        matchScore: (m['matchScore'] as num?)?.toInt() ?? 50,
        reason: m['reason']?.toString() ?? '',
      );
}

class FriendlyInvitation {
  final String id;
  final String fromTeamId;
  final String fromTeamName;
  final String toTeamId;
  final String toTeamName;
  final String message;
  final String? venue;
  final String? proposedDate;
  final String status;
  final DateTime? createdAt;

  FriendlyInvitation({
    required this.id,
    required this.fromTeamId,
    required this.fromTeamName,
    required this.toTeamId,
    required this.toTeamName,
    required this.message,
    this.venue,
    this.proposedDate,
    required this.status,
    this.createdAt,
  });

  factory FriendlyInvitation.fromMap(Map<String, dynamic> m) =>
      FriendlyInvitation(
        id: m['id'] ?? '',
        fromTeamId: m['fromTeamId'] ?? '',
        fromTeamName: m['fromTeamName'] ?? '',
        toTeamId: m['toTeamId'] ?? '',
        toTeamName: m['toTeamName'] ?? '',
        message: m['message'] ?? '',
        venue: m['venue'],
        proposedDate: m['proposedDate'],
        status: m['status'] ?? 'Pending',
        createdAt: _toDate(m['createdAt']),
      );
}

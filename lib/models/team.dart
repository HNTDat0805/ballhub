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

  /// Khởi tạo một đối tượng đội bóng [Team]
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

  /// Chuyển đổi dữ liệu JSON/Map nhận từ REST API hoặc Firestore thành thực thể [Team]
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

  /// Chuyển đổi thực thể [Team] thành Map JSON để gửi lên Backend REST API
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

/// Đại diện cho một thành viên trong đội bóng (Đội trưởng hoặc Cầu thủ thành viên)
class TeamMember {
  /// Mã định danh người dùng
  final String userId;

  /// Vai trò trong đội: 'Captain' (Đội trưởng) hoặc 'Member' (Thành viên)
  final String role;

  /// Họ và tên thành viên
  final String fullName;

  /// Ảnh đại diện định dạng base64 (nếu có)
  final String? avatarBase64;

  /// Vị trí thi đấu sở trường (Tiền đạo, Tiền vệ, Hậu vệ, Thủ môn)
  final String? position;

  /// Khởi tạo một thực thể [TeamMember]
  TeamMember({
    required this.userId,
    required this.role,
    required this.fullName,
    this.avatarBase64,
    this.position,
  });

  /// Chuyển đổi dữ liệu Map từ API thành thực thể [TeamMember]
  factory TeamMember.fromMap(Map<String, dynamic> m) => TeamMember(
    userId: m['userId'] ?? '',
    role: m['role'] ?? 'Member',
    fullName: m['fullName'] ?? '(Không rõ)',
    avatarBase64: m['avatarBase64'],
    position: m['position'],
  );
}

/// Đại diện cho một yêu cầu xin gia nhập đội bóng từ người chơi gửi tới Đội trưởng
class JoinRequest {
  /// Mã định danh yêu cầu
  final String requestId;

  /// Mã đội bóng muốn gia nhập
  final String teamId;

  /// Mã người gửi yêu cầu
  final String userId;

  /// Lời nhắn kèm theo của người xin gia nhập
  final String? message;

  /// Họ tên người xin gia nhập
  final String fullName;

  /// Ảnh đại diện
  final String? avatarBase64;

  /// Vị trí thi đấu sở trường
  final String? position;

  /// Khởi tạo [JoinRequest]
  JoinRequest({
    required this.requestId,
    required this.teamId,
    required this.userId,
    this.message,
    required this.fullName,
    this.avatarBase64,
    this.position,
  });

  /// Chuyển đổi Map từ Backend thành [JoinRequest]
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

/// Ứng viên đối thủ phù hợp được gợi ý từ thuật toán Matchmaking
class MatchmakingCandidate {
  /// Thực thể đội bóng đối thủ
  final Team team;

  /// Điểm số phù hợp (Match Score 0-100) tính theo khoảng cách địa lý và trình độ
  final int matchScore;

  /// Lý do gợi ý đối thủ (ví dụ: "Cùng khu vực TP. Hồ Chí Minh")
  final String reason;

  /// Khởi tạo đối thủ gợi ý [MatchmakingCandidate]
  MatchmakingCandidate({
    required this.team,
    required this.matchScore,
    required this.reason,
  });

  /// Chuyển đổi từ dữ liệu gợi ý API thành [MatchmakingCandidate]
  factory MatchmakingCandidate.fromMap(Map<String, dynamic> m) =>
      MatchmakingCandidate(
        team: Team.fromMap(Map<String, dynamic>.from(m['team'] as Map)),
        matchScore: (m['matchScore'] as num?)?.toInt() ?? 50,
        reason: m['reason']?.toString() ?? '',
      );
}

/// Đại diện cho một lời mời thi đấu giao hữu (Cáp kèo) giữa 2 đội bóng
class FriendlyInvitation {
  /// Mã định danh lời mời
  final String id;

  /// Mã đội bóng gửi lời mời
  final String fromTeamId;

  /// Tên đội bóng gửi lời mời
  final String fromTeamName;

  /// Mã đội bóng nhận lời mời
  final String toTeamId;

  /// Tên đội bóng nhận lời mời
  final String toTeamName;

  /// Nội dung tin nhắn thách đấu
  final String message;

  /// Địa điểm/Sân bóng dự kiến thi đấu
  final String? venue;

  /// Thời gian thi đấu đề xuất
  final String? proposedDate;

  /// Trạng thái lời mời: 'Pending' (Chờ), 'Accepted' (Đã nhận), 'Declined' (Từ chối)
  final String status;

  /// Thời điểm tạo lời mời
  final DateTime? createdAt;

  /// Khởi tạo một lời mời thi đấu giao hữu [FriendlyInvitation]
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

  /// Chuyển đổi Map từ Backend thành thực thể [FriendlyInvitation]
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

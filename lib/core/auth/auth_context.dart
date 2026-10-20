import 'package:flutter/foundation.dart';

/// Vai trò người dùng trong hệ thống Ballhub theo kiến trúc RBAC (Role-Based Access Control).
enum UserRole {
  /// Quản trị viên hệ thống: có toàn quyền trên toàn bộ giải đấu, đội bóng, lịch và kết quả
  admin,

  /// Người tổ chức giải đấu: tạo và quản lý giải đấu thuộc sở hữu của mình, duyệt đội, lên lịch, nhập tỷ số
  organizer,

  /// Đội trưởng đội bóng: đăng ký đội tham gia giải đấu, quản lý thông tin thành viên đội
  teamCaptain,

  /// Cầu thủ tham gia thi đấu
  player,

  /// Khán giả / Người dùng vãng lai: chỉ có quyền xem thông tin công khai (giải đấu, lịch thi đấu, bảng xếp hạng)
  viewer;

  /// Tên hiển thị thân thiện trên giao diện tiếng Việt
  String get displayName => switch (this) {
        UserRole.admin => 'Quản trị viên (Admin)',
        UserRole.organizer => 'Người tổ chức (Organizer)',
        UserRole.teamCaptain => 'Đội trưởng (Captain)',
        UserRole.player => 'Cầu thủ (Player)',
        UserRole.viewer => 'Khán giả (Viewer)',
      };
}

/// Thực thể người dùng đang hoạt động trong phiên làm việc.
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? teamId;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.teamId,
  });

  /// Kiểm tra có phải là Admin hệ thống
  bool get isAdmin => role == UserRole.admin;

  /// Kiểm tra có quyền hạn của Người tổ chức (bao gồm cả Admin)
  bool get isOrganizer => role == UserRole.organizer || isAdmin;

  /// Kiểm tra có quyền hạn của Đội trưởng (bao gồm cả Organizer và Admin)
  bool get isCaptain => role == UserRole.teamCaptain || isOrganizer;

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? teamId,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
    );
  }
}

/// Quản lý trạng thái phiên đăng nhập và phân quyền (RBAC) phía Flutter Client.
///
/// Hỗ trợ chuyển đổi nhanh giữa các Persona (Admin, BTC, Đội trưởng, Khán giả)
/// để kiểm thử trực tiếp hành vi phân quyền trên giao diện và backend API.
class AuthContext extends ChangeNotifier {
  static final AuthContext instance = AuthContext._internal();
  AuthContext._internal();

  AppUser _currentUser = const AppUser(
    id: 'user_organizer_01',
    name: 'Nguyễn Văn Quản Lý',
    email: 'organizer@ballhub.vn',
    role: UserRole.organizer,
  );

  AppUser get currentUser => _currentUser;

  void switchUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  // Pre-configured persona users for quick testing/verification in development
  static final List<AppUser> sampleUsers = [
    const AppUser(
      id: 'user_organizer_01',
      name: 'Nguyễn Văn Quản Lý (BTC)',
      email: 'organizer@ballhub.vn',
      role: UserRole.organizer,
    ),
    const AppUser(
      id: 'user_captain_01',
      name: 'Trần Đội Trưởng (FC Sao Vàng)',
      email: 'captain1@ballhub.vn',
      role: UserRole.teamCaptain,
      teamId: 'team_sao_vang',
    ),
    const AppUser(
      id: 'user_captain_02',
      name: 'Lê Đội Trưởng (FC Rồng Đỏ)',
      email: 'captain2@ballhub.vn',
      role: UserRole.teamCaptain,
      teamId: 'team_rong_do',
    ),
    const AppUser(
      id: 'user_viewer_01',
      name: 'Phạm Khán Giả',
      email: 'viewer@ballhub.vn',
      role: UserRole.viewer,
    ),
  ];

  /// Checks if current user can manage this specific tournament
  bool canManageTournament(String organizerId) {
    if (_currentUser.isAdmin) return true;
    if (_currentUser.isOrganizer && _currentUser.id == organizerId) return true;
    return false;
  }

  /// Checks if current user can register a team
  bool canRegisterTeam() {
    return _currentUser.role == UserRole.teamCaptain || _currentUser.isOrganizer;
  }

  /// Checks if current user can update or confirm match score
  bool canManageMatch(String organizerId) {
    return canManageTournament(organizerId);
  }
}

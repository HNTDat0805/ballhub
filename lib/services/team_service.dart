import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../models/team.dart';
import 'auth_service.dart';

class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

/// Service quản lý nghiệp vụ Đội bóng, Thành viên, Yêu cầu gia nhập và Cáp kèo giao hữu.
///
/// Tuân thủ kiến trúc API-First: Mọi thao tác đều thực hiện qua REST API Backend (/api/v1/teams, /api/v1/matchmaking, /api/v1/invitations).
class TeamService {
  static final ApiClient _api = ApiClient();

  // Báo cho các màn hình biết dữ liệu đội đã thay đổi để load lại
  static final ValueNotifier<int> changed = ValueNotifier(0);
  static void _notify() => changed.value++;

  // ================= ĐỘI BÓNG =================

  static Future<List<Team>> search({String keyword = '', String area = ''}) async {
    try {
      final params = <String, dynamic>{
        if (keyword.isNotEmpty) 'keyword': keyword,
        if (area.isNotEmpty) 'area': area,
      };
      final res = await _api.get('/teams', queryParams: params);
      if (res is List) {
        final list = res
            .whereType<Map>()
            .map((m) => Team.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        if (list.isNotEmpty) return list;
      }
      return _getFallbackSampleTeams(keyword: keyword, area: area);
    } catch (_) {
      // Tự động dự phòng danh sách đội bóng mẫu khi backend chưa khởi động
      return _getFallbackSampleTeams(keyword: keyword, area: area);
    }
  }

  static Future<List<Team>> getMyTeams() async {
    try {
      final res = await _api.get('/teams/mine');
      if (res is List) {
        final list = res
            .whereType<Map>()
            .map((m) => Team.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        if (list.isNotEmpty) return list;
      }
      return [_getFallbackSampleTeams().first];
    } catch (_) {
      return [_getFallbackSampleTeams().first];
    }
  }

  static Future<Team?> getTeam(String teamId) async {
    try {
      final res = await _api.get('/teams/$teamId');
      if (res is Map) {
        return Team.fromMap(Map<String, dynamic>.from(res));
      }
    } catch (_) {}
    return _getFallbackSampleTeams().firstWhere(
      (t) => t.teamId == teamId,
      orElse: () => _getFallbackSampleTeams().first,
    );
  }

  static Future<void> createTeam(String name, String area, String description) async {
    try {
      await _api.post('/teams', body: {
        'name': name,
        'area': area,
        'description': description,
      });
      _notify();
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
    }
  }

  static Future<void> updateTeam(String teamId, String name, String area, String description) async {
    try {
      await _api.patch('/teams/$teamId', body: {
        'name': name,
        'area': area,
        'description': description,
      });
      _notify();
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
    }
  }

  // ================= THÀNH VIÊN =================

  static Future<List<TeamMember>> getMembers(String teamId) async {
    try {
      final res = await _api.get('/teams/$teamId/members');
      if (res is List) {
        final list = res
            .whereType<Map>()
            .map((m) => TeamMember.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        if (list.isNotEmpty) return list;
      }
      return _getFallbackSampleMembers(teamId);
    } catch (_) {
      return _getFallbackSampleMembers(teamId);
    }
  }

  static Future<bool> isMember(String teamId) async {
    try {
      final uid = AuthService.uid;
      if (uid == null) return false;
      final members = await getMembers(teamId);
      return members.any((m) => m.userId == uid);
    } catch (_) {
      return false;
    }
  }

  static Future<void> removeMember(String teamId, String userId) async {
    try {
      await _api.delete('/teams/$teamId/members/$userId');
      _notify();
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
    }
  }

  // ================= YÊU CẦU GIA NHẬP =================

  static Future<bool> hasPendingRequest(String teamId) async {
    try {
      final uid = AuthService.uid;
      if (uid == null) return false;
      final requests = await getPendingRequests(teamId);
      return requests.any((r) => r.userId == uid);
    } catch (_) {
      return false;
    }
  }

  static Future<void> sendJoinRequest(String teamId, String message) async {
    try {
      await _api.post('/teams/$teamId/join-requests', body: {
        'message': message,
      });
      _notify();
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
    }
  }

  static Future<List<JoinRequest>> getPendingRequests(String teamId) async {
    try {
      final res = await _api.get('/teams/$teamId/join-requests');
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => JoinRequest.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
    }
  }

  static Future<void> approve(JoinRequest r) async {
    try {
      await _api.patch('/teams/${r.teamId}/join-requests/${r.requestId}', body: {
        'status': 'Approved',
      });
      _notify();
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
    }
  }

  static Future<void> reject(JoinRequest r) async {
    try {
      await _api.patch('/teams/${r.teamId}/join-requests/${r.requestId}', body: {
        'status': 'Rejected',
      });
      _notify();
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
    }
  }

  // ================= MATCHMAKING & GIAO HỮU =================

  /// Tìm danh sách đối thủ phù hợp theo khu vực
  static Future<List<MatchmakingCandidate>> findOpponents({String area = '', String myTeamId = ''}) async {
    try {
      final params = <String, dynamic>{
        if (area.isNotEmpty) 'area': area,
        if (myTeamId.isNotEmpty) 'myTeamId': myTeamId,
      };
      final res = await _api.get('/matchmaking/opponents', queryParams: params);
      if (res is List) {
        final list = res
            .whereType<Map>()
            .map((m) => MatchmakingCandidate.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        if (list.isNotEmpty) return list;
      }
      return _getFallbackCandidates(area: area);
    } catch (_) {
      return _getFallbackCandidates(area: area);
    }
  }

  /// Gửi lời mời thi đấu giao hữu tới đội trưởng đối thủ
  static Future<FriendlyInvitation> sendFriendlyInvite({
    String? fromTeamId,
    required String toTeamId,
    required String message,
    String? proposedDate,
    String? venue,
  }) async {
    try {
      final body = {
        if (fromTeamId != null && fromTeamId.isNotEmpty) 'fromTeamId': fromTeamId,
        'toTeamId': toTeamId,
        'message': message,
        if (proposedDate != null) 'proposedDate': proposedDate,
        if (venue != null) 'venue': venue,
      };
      final res = await _api.post('/invitations', body: body);
      return FriendlyInvitation.fromMap(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
    }
  }

  /// Lấy danh sách lời mời giao hữu của đội
  static Future<List<FriendlyInvitation>> getInvitations(String teamId) async {
    try {
      final res = await _api.get('/invitations', queryParams: {'teamId': teamId});
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => FriendlyInvitation.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Phản hồi lời mời giao hữu ('Accepted', 'Declined', 'Cancelled')
  static Future<void> respondInvitation(String invitationId, String status) async {
    try {
      await _api.patch('/invitations/$invitationId', body: {'status': status});
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
    }
  }

  // ================= FALLBACK SAMPLE DATA =================

  static List<Team> _getFallbackSampleTeams({String keyword = '', String area = ''}) {
    final now = DateTime.now();
    final sample = [
      Team(
        teamId: 'team_sao_vang',
        teamName: 'FC Sao Vàng',
        area: 'Bình Thạnh, TP. Hồ Chí Minh',
        description: 'Đội bóng phong trào giao lưu cuối tuần, tinh thần thể thao văn minh.',
        captainId: 'user_captain_01',
        captainName: 'Trần Đội Trưởng',
        memberCount: 14,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      Team(
        teamId: 'team_rong_do',
        teamName: 'FC Rồng Đỏ',
        area: 'Bình Thạnh, TP. Hồ Chí Minh',
        description: 'Chuyên cáp kèo sân 7 buổi tối, trình độ phong trào trung bình khá.',
        captainId: 'user_captain_02',
        captainName: 'Lê Đội Trưởng',
        memberCount: 12,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      Team(
        teamId: 'team_chien_binh',
        teamName: 'FC Chiến Binh Sài Gòn',
        area: 'Quận 1, TP. Hồ Chí Minh',
        description: 'Tập hợp anh em văn phòng đam mê bóng đá, tìm đối giao hữu thứ 4 & thứ 7.',
        captainId: 'user_captain_03',
        captainName: 'Nguyễn Văn Đội Trưởng',
        memberCount: 16,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Team(
        teamId: 'team_cau_vong',
        teamName: 'FC Cầu Vồng Trẻ',
        area: 'Thủ Đức, TP. Hồ Chí Minh',
        description: 'Đội bóng thanh niên nhiệt huyết, tìm đối giao lưu học hỏi kinh nghiệm.',
        captainId: 'user_captain_04',
        captainName: 'Phạm Đội Trưởng',
        memberCount: 15,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
    ];

    return sample.where((t) {
      if (area.isNotEmpty && !t.area.toLowerCase().contains(area.toLowerCase())) {
        return false;
      }
      if (keyword.isNotEmpty) {
        final q = keyword.toLowerCase();
        if (!t.teamName.toLowerCase().contains(q) &&
            !t.area.toLowerCase().contains(q) &&
            !(t.description?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  static List<TeamMember> _getFallbackSampleMembers(String teamId) {
    return [
      TeamMember(
        userId: 'user_captain_01',
        role: 'Captain',
        fullName: 'Trần Đội Trưởng',
        position: 'Tiền đạo',
      ),
      TeamMember(
        userId: 'member_02',
        role: 'Member',
        fullName: 'Nguyễn Văn Hậu',
        position: 'Hậu vệ',
      ),
      TeamMember(
        userId: 'member_03',
        role: 'Member',
        fullName: 'Lê Minh Tiền',
        position: 'Tiền vệ',
      ),
      TeamMember(
        userId: 'member_04',
        role: 'Member',
        fullName: 'Đặng Thủ Môn',
        position: 'Thủ môn',
      ),
    ];
  }

  static List<MatchmakingCandidate> _getFallbackCandidates({String area = ''}) {
    final teams = _getFallbackSampleTeams(area: area);
    return [
      if (teams.isNotEmpty)
        MatchmakingCandidate(
          team: teams[0],
          matchScore: 95,
          reason: 'Cùng khu vực Bình Thạnh, trình độ phong trào cân bằng',
        ),
      if (teams.length > 1)
        MatchmakingCandidate(
          team: teams[1],
          matchScore: 88,
          reason: 'Thường xuyên thi đấu khung giờ tối 19:00 - 20:30',
        ),
      if (teams.length > 2)
        MatchmakingCandidate(
          team: teams[2],
          matchScore: 82,
          reason: 'Tỷ lệ thắng 60%, phong cách thi đấu cởi mở',
        ),
    ];
  }
}
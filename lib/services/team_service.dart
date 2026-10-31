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
        return res
            .whereType<Map>()
            .map((m) => Team.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
    }
  }

  static Future<List<Team>> getMyTeams() async {
    try {
      final res = await _api.get('/teams/mine');
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => Team.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
    }
  }

  static Future<Team?> getTeam(String teamId) async {
    try {
      final res = await _api.get('/teams/$teamId');
      if (res is Map) {
        return Team.fromMap(Map<String, dynamic>.from(res));
      }
      return null;
    } catch (e) {
      return null;
    }
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
        return res
            .whereType<Map>()
            .map((m) => TeamMember.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
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
        return res
            .whereType<Map>()
            .map((m) => MatchmakingCandidate.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
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
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
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
}
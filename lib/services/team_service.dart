import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/auth/auth_context.dart' hide AppUser;
import '../models/team.dart';
import '../data/seeds/team_seed_data.dart';
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
  static ApiClient _api = ApiClient();
  @visibleForTesting
  static set api(ApiClient client) => _api = client;
  @visibleForTesting
  static ApiClient get api => _api;

  @visibleForTesting
  static void resetStateForTesting() {
    _leftTeamIds.clear();
    _deletedTeamIds.clear();
    _deletedTeamNames.clear();
    _userCreatedTeams.clear();
    _myTeamsCache.clear();
    _localInvitations.clear();
    _cachedTeams.clear();
    _cachedMembers.clear();
  }

  // Báo cho các màn hình biết dữ liệu đội đã thay đổi để load lại
  static final ValueNotifier<int> changed = ValueNotifier(0);
  static void _notify() => changed.value++;

  static final Set<String> _leftTeamIds = {};
  static final Set<String> _deletedTeamIds = {};
  static final Set<String> _deletedTeamNames = {};
  static final List<Team> _userCreatedTeams = [];
  static final List<Team> _myTeamsCache = [];
  static final List<FriendlyInvitation> _localInvitations = [];
  static final Map<String, Team> _cachedTeams = {};
  static final Map<String, List<TeamMember>> _cachedMembers = {};

  /// Danh sách các đội bóng của người dùng hiện tại (lưu trong bộ nhớ cục bộ để phản hồi UI 0ms)
  static List<Team> get localTeams {
    final list = <Team>[];
    final seen = <String>{};

    for (final t in [..._userCreatedTeams, ..._myTeamsCache]) {
      if (_leftTeamIds.contains(t.teamId)) continue;
      if (_deletedTeamIds.contains(t.teamId)) continue;
      if (_deletedTeamNames.contains(t.teamName.toLowerCase())) continue;
      if (seen.add(t.teamId)) {
        list.add(t);
      }
    }
    return List.unmodifiable(list);
  }

  /// Kiểm tra xem một đội bóng đã bị xóa / giải tán hay chưa
  static bool isTeamDeleted(String teamId, [String? teamName]) {
    if (_deletedTeamIds.contains(teamId)) return true;
    if (teamName != null &&
        _deletedTeamNames.contains(teamName.toLowerCase())) {
      return true;
    }
    return false;
  }

  /// Kiểm tra xem người dùng hiện tại đã rời khỏi đội bóng này chưa
  static bool hasLeftTeam(String teamId) {
    return _leftTeamIds.contains(teamId);
  }

  /// Dọn dẹp trạng thái cục bộ khi người dùng đăng xuất
  static void clearLocalState() {
    _leftTeamIds.clear();
    _deletedTeamIds.clear();
    _deletedTeamNames.clear();
    _userCreatedTeams.clear();
    _myTeamsCache.clear();
    _localInvitations.clear();
    _cachedTeams.clear();
    _cachedMembers.clear();
    _notify();
  }

  /// Tra cứu nhanh thông tin đội bóng từ bộ nhớ cache hoặc seed data (đồng bộ 0ms)
  static Team? findTeamCached(String teamId) {
    if (_deletedTeamIds.contains(teamId)) return null;

    final created = _userCreatedTeams
        .where((t) => t.teamId == teamId)
        .firstOrNull;
    if (created != null) {
      if (_deletedTeamNames.contains(created.teamName.toLowerCase())) {
        return null;
      }
      return created;
    }

    final cached = _cachedTeams[teamId];
    if (cached != null) {
      if (_deletedTeamNames.contains(cached.teamName.toLowerCase())) {
        return null;
      }
      return cached;
    }

    final fallback = TeamSeedData.getSampleTeams().where((t) {
      if (_deletedTeamIds.contains(t.teamId)) return false;
      if (_deletedTeamNames.contains(t.teamName.toLowerCase())) return false;
      return t.teamId == teamId;
    }).firstOrNull;

    return fallback;
  }

  /// Tra cứu nhanh danh sách thành viên từ cache hoặc seed data (đồng bộ 0ms)
  static List<TeamMember>? findMembersCached(String teamId) {
    if (_deletedTeamIds.contains(teamId)) return null;

    final cached = _cachedMembers[teamId];
    if (cached != null) {
      if (_leftTeamIds.contains(teamId)) {
        final uid = AuthService.uid;
        return cached.where((m) => m.userId != uid).toList();
      }
      return cached;
    }

    final created = _userCreatedTeams
        .where((t) => t.teamId == teamId)
        .firstOrNull;
    if (created != null) {
      return [
        TeamMember(
          userId: AuthService.uid ?? 'current_user',
          role: 'Captain',
          fullName: AuthService.currentUser?.displayName ?? 'Tôi (Đội trưởng)',
          position: 'Đội trưởng',
        ),
      ];
    }

    final fallback = TeamSeedData.getSampleMembers(teamId);
    if (_leftTeamIds.contains(teamId)) {
      final uid = AuthService.uid;
      return fallback.where((m) => m.userId != uid).toList();
    }
    return fallback;
  }

  // ================= ĐỘI BÓNG =================

  static Future<List<Team>> search({
    String keyword = '',
    String area = '',
  }) async {
    List<Team> list = [];
    try {
      final params = <String, dynamic>{
        if (keyword.isNotEmpty) 'keyword': keyword,
        if (area.isNotEmpty) 'area': area,
      };
      final res = await _api.get('/teams', queryParams: params);
      if (res is List) {
        list = res
            .whereType<Map>()
            .map((m) => Team.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
      if (list.isEmpty) {
        list = TeamSeedData.getSampleTeams(keyword: keyword, area: area);
      }
    } catch (_) {
      // Tự động dự phòng danh sách đội bóng mẫu khi backend chưa khởi động
      list = TeamSeedData.getSampleTeams(keyword: keyword, area: area);
    }

    final matchingCreated = _userCreatedTeams.where((t) {
      if (area.isNotEmpty &&
          !t.area.toLowerCase().contains(area.toLowerCase())) {
        return false;
      }
      if (keyword.isNotEmpty &&
          !t.teamName.toLowerCase().contains(keyword.toLowerCase()) &&
          !t.area.toLowerCase().contains(keyword.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    final combined =
        [
          ...matchingCreated,
          ...list.where(
            (t) => !matchingCreated.any(
              (u) =>
                  u.teamId == t.teamId ||
                  u.teamName.toLowerCase() == t.teamName.toLowerCase(),
            ),
          ),
        ].where((t) {
          if (_deletedTeamIds.contains(t.teamId)) {
            return false;
          }
          if (_deletedTeamNames.contains(t.teamName.toLowerCase())) {
            return false;
          }
          return true;
        }).toList();

    for (final t in combined) {
      _cachedTeams[t.teamId] = t;
    }

    return combined;
  }

  static Future<List<Team>> getMyTeams() async {
    List<Team> result = [];
    try {
      final res = await _api.get(
        '/teams/mine',
        timeout: const Duration(seconds: 3),
      );
      if (res is List) {
        result = res
            .whereType<Map>()
            .map((m) => Team.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}

    final all =
        [
          ..._userCreatedTeams,
          ...result.where(
            (t) => !_userCreatedTeams.any(
              (u) =>
                  u.teamId == t.teamId ||
                  u.teamName.toLowerCase() == t.teamName.toLowerCase(),
            ),
          ),
        ].where((t) {
          if (_leftTeamIds.contains(t.teamId)) {
            return false;
          }
          if (_deletedTeamIds.contains(t.teamId)) {
            return false;
          }
          if (_deletedTeamNames.contains(t.teamName.toLowerCase())) {
            return false;
          }
          return true;
        }).toList();

    _myTeamsCache.clear();
    _myTeamsCache.addAll(all);

    for (final t in all) {
      _cachedTeams[t.teamId] = t;
    }

    return all;
  }

  static Future<Team?> getTeam(String teamId) async {
    if (_deletedTeamIds.contains(teamId)) {
      return null;
    }
    final created = _userCreatedTeams
        .where((t) => t.teamId == teamId)
        .firstOrNull;
    if (created != null) {
      if (_deletedTeamNames.contains(created.teamName.toLowerCase())) {
        return null;
      }
      return created;
    }

    try {
      final res = await _api.get(
        '/teams/$teamId',
        timeout: const Duration(seconds: 3),
      );
      if (res is Map) {
        final t = Team.fromMap(Map<String, dynamic>.from(res));
        if (_deletedTeamIds.contains(t.teamId) ||
            _deletedTeamNames.contains(t.teamName.toLowerCase())) {
          return null;
        }
        _cachedTeams[t.teamId] = t;
        return t;
      }
    } catch (_) {}

    final cached = _cachedTeams[teamId];
    if (cached != null) {
      if (_deletedTeamNames.contains(cached.teamName.toLowerCase())) {
        return null;
      }
      return cached;
    }

    final fallback = TeamSeedData.getSampleTeams().where((t) {
      if (_deletedTeamIds.contains(t.teamId)) return false;
      if (_deletedTeamNames.contains(t.teamName.toLowerCase())) return false;
      return t.teamId == teamId;
    }).firstOrNull;

    if (fallback != null) {
      _cachedTeams[fallback.teamId] = fallback;
    }

    return fallback;
  }

  static Future<void> createTeam(
    String name,
    String area,
    String description, {
    String? placeId,
    double? latitude,
    double? longitude,
    String? province,
    String? district,
    String? ward,
  }) async {
    final uid = AuthService.uid ?? 'current_user';
    final localId = 'team_${DateTime.now().millisecondsSinceEpoch}';
    final newTeam = Team(
      teamId: localId,
      teamName: name,
      area: area,
      description: description,
      captainId: uid,
      captainName: AuthService.currentUser?.displayName ?? 'Tôi (Đội trưởng)',
      memberCount: 1,
      createdAt: DateTime.now(),
      placeId: placeId,
      latitude: latitude,
      longitude: longitude,
      province: province,
      district: district,
      ward: ward,
    );
    if (name.isNotEmpty) {
      _deletedTeamNames.remove(name.toLowerCase());
    }
    _userCreatedTeams.insert(0, newTeam);
    _myTeamsCache.insert(0, newTeam);
    try {
      final res = await _api.post(
        '/teams',
        body: {
          'name': name,
          'area': area,
          'description': description,
          if (placeId != null && placeId.isNotEmpty) 'placeId': placeId,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (province != null && province.isNotEmpty) 'province': province,
          if (district != null && district.isNotEmpty) 'district': district,
          if (ward != null && ward.isNotEmpty) 'ward': ward,
        },
      );
      if (res is Map) {
        final serverTeam = Team.fromMap(Map<String, dynamic>.from(res));
        final idx = _userCreatedTeams.indexWhere(
          (t) =>
              t.teamId == localId ||
              t.teamName.toLowerCase() == name.toLowerCase(),
        );
        if (idx != -1) {
          _userCreatedTeams[idx] = serverTeam;
        } else {
          _userCreatedTeams.insert(0, serverTeam);
        }
        final myIdx = _myTeamsCache.indexWhere(
          (t) =>
              t.teamId == localId ||
              t.teamName.toLowerCase() == name.toLowerCase(),
        );
        if (myIdx != -1) {
          _myTeamsCache[myIdx] = serverTeam;
        } else {
          _myTeamsCache.insert(0, serverTeam);
        }
      }
    } catch (e) {
      if (e is ApiException) {
        if (e.code == 'NETWORK_ERROR' ||
            e.code == 'TIMEOUT' ||
            e.statusCode == 503) {
          debugPrint(
            'TeamService.createTeam server offline, keeping local team: $e',
          );
        } else {
          _userCreatedTeams.remove(newTeam);
          _myTeamsCache.remove(newTeam);
          throw AppException(e.message);
        }
      } else {
        throw AppException(e.toString());
      }
    } finally {
      _notify();
    }
  }

  static Future<void> updateTeam(
    String teamId,
    String name,
    String area,
    String description, {
    String? placeId,
    double? latitude,
    double? longitude,
    String? province,
    String? district,
    String? ward,
  }) async {
    final idx = _userCreatedTeams.indexWhere((t) => t.teamId == teamId);
    if (idx != -1) {
      final old = _userCreatedTeams[idx];
      _userCreatedTeams[idx] = Team(
        teamId: old.teamId,
        teamName: name,
        area: area,
        description: description,
        captainId: old.captainId,
        captainName: old.captainName,
        memberCount: old.memberCount,
        createdAt: old.createdAt,
        placeId: placeId ?? old.placeId,
        latitude: latitude ?? old.latitude,
        longitude: longitude ?? old.longitude,
        province: province ?? old.province,
        district: district ?? old.district,
        ward: ward ?? old.ward,
      );
    }

    final cached = _cachedTeams[teamId];
    if (cached != null) {
      _cachedTeams[teamId] = Team(
        teamId: cached.teamId,
        teamName: name,
        area: area,
        description: description,
        captainId: cached.captainId,
        captainName: cached.captainName,
        memberCount: cached.memberCount,
        createdAt: cached.createdAt,
        placeId: placeId ?? cached.placeId,
        latitude: latitude ?? cached.latitude,
        longitude: longitude ?? cached.longitude,
        province: province ?? cached.province,
        district: district ?? cached.district,
        ward: ward ?? cached.ward,
      );
    }

    try {
      await _api.patch(
        '/teams/$teamId',
        body: {
          'name': name,
          'area': area,
          'description': description,
          if (placeId != null && placeId.isNotEmpty) 'placeId': placeId,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (province != null && province.isNotEmpty) 'province': province,
          if (district != null && district.isNotEmpty) 'district': district,
          if (ward != null && ward.isNotEmpty) 'ward': ward,
        },
      );
    } catch (e) {
      if (e is ApiException) {
        if (e.code == 'NETWORK_ERROR' ||
            e.code == 'TIMEOUT' ||
            e.statusCode == 503) {
          debugPrint(
            'TeamService.updateTeam server offline, keeping local update: $e',
          );
        } else {
          throw AppException(e.message);
        }
      } else {
        throw AppException(e.toString());
      }
    } finally {
      _notify();
    }
  }

  /// Giải tán đội bóng (Chỉ dành cho Đội trưởng)
  static Future<void> deleteTeam(String teamId, {String? teamName}) async {
    final originalIndex = _userCreatedTeams.indexWhere(
      (t) =>
          t.teamId == teamId ||
          (teamName != null &&
              t.teamName.toLowerCase() == teamName.toLowerCase()),
    );
    final originalTeam = originalIndex != -1
        ? _userCreatedTeams[originalIndex]
        : null;
    final resolvedName = teamName ?? originalTeam?.teamName;

    _deletedTeamIds.add(teamId);
    _cachedTeams.remove(teamId);
    _cachedMembers.remove(teamId);
    if (originalTeam != null && originalTeam.teamId != teamId) {
      _deletedTeamIds.add(originalTeam.teamId);
      _cachedTeams.remove(originalTeam.teamId);
      _cachedMembers.remove(originalTeam.teamId);
    }
    if (resolvedName != null && resolvedName.isNotEmpty) {
      _deletedTeamNames.add(resolvedName.toLowerCase());
    }

    if (originalIndex != -1) {
      _userCreatedTeams.removeAt(originalIndex);
    }

    _myTeamsCache.removeWhere(
      (t) =>
          t.teamId == teamId ||
          (originalTeam != null && t.teamId == originalTeam.teamId) ||
          (resolvedName != null &&
              t.teamName.toLowerCase() == resolvedName.toLowerCase()),
    );

    // Dọn dẹp teamId của người dùng nếu họ đang giữ id của đội này
    final cur = AuthContext.instance.currentUser;
    if (cur.teamId == teamId ||
        (originalTeam != null && cur.teamId == originalTeam.teamId)) {
      AuthContext.instance.switchUser(cur.copyWith(teamId: null));
    }

    // BÁO CHO TOÀN BỘ MÀN HÌNH CẬP NHẬT GIAO DIỆN NGAY LẬP TỨC (0MS)
    _notify();

    try {
      await _api.delete('/teams/$teamId');
    } catch (e) {
      if (e is ApiException) {
        if (e.code == 'NETWORK_ERROR' ||
            e.code == 'TIMEOUT' ||
            e.statusCode == 503) {
          debugPrint(
            'TeamService.deleteTeam server offline, keeping local deletion: $e',
          );
        } else if (e.statusCode == 404 ||
            e.message.contains('Không tìm thấy')) {
          debugPrint(
            'TeamService.deleteTeam 404 on server, keeping local deletion: $e',
          );
        } else {
          _deletedTeamIds.remove(teamId);
          if (originalTeam != null && originalTeam.teamId != teamId) {
            _deletedTeamIds.remove(originalTeam.teamId);
          }
          if (resolvedName != null && resolvedName.isNotEmpty) {
            _deletedTeamNames.remove(resolvedName.toLowerCase());
          }
          if (originalTeam != null) {
            _userCreatedTeams.insert(originalIndex, originalTeam);
            _myTeamsCache.insert(0, originalTeam);
          }
          throw AppException(e.message);
        }
      } else {
        debugPrint(
          'TeamService.deleteTeam unexpected error, keeping local deletion: $e',
        );
      }
    } finally {
      _notify();
    }
  }

  /// Rời đội bóng (Dành cho thành viên)
  static Future<void> leaveTeam(String teamId) async {
    _leftTeamIds.add(teamId);
    _cachedTeams.remove(teamId);
    _cachedMembers.remove(teamId);
    _userCreatedTeams.removeWhere((t) => t.teamId == teamId);
    _myTeamsCache.removeWhere((t) => t.teamId == teamId);

    final cur = AuthContext.instance.currentUser;
    if (cur.teamId == teamId) {
      AuthContext.instance.switchUser(cur.copyWith(teamId: null));
    }

    // BÁO CHO TOÀN BỘ MÀN HÌNH CẬP NHẬT GIAO DIỆN NGAY LẬP TỨC (0MS)
    _notify();

    final uid = AuthService.uid;
    try {
      if (uid != null) {
        await _api.delete('/teams/$teamId/members/$uid');
      }
    } catch (e) {
      if (e is ApiException) {
        if (e.code == 'NETWORK_ERROR' ||
            e.code == 'TIMEOUT' ||
            e.statusCode == 503) {
          debugPrint(
            'TeamService.leaveTeam server offline, keeping local leave: $e',
          );
        } else if (e.statusCode == 404 ||
            e.message.contains('Không tìm thấy')) {
          debugPrint(
            'TeamService.leaveTeam 404 on server, keeping local leave: $e',
          );
        } else {
          _leftTeamIds.remove(teamId);
          throw AppException(e.message);
        }
      } else {
        debugPrint(
          'TeamService.leaveTeam unexpected error, keeping local leave: $e',
        );
      }
    } finally {
      _notify();
    }
  }

  // ================= THÀNH VIÊN =================

  static Future<List<TeamMember>> getMembers(String teamId) async {
    try {
      final res = await _api.get(
        '/teams/$teamId/members',
        timeout: const Duration(seconds: 3),
      );
      if (res is List) {
        final list = res
            .whereType<Map>()
            .map((m) => TeamMember.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        if (list.isNotEmpty) {
          _cachedMembers[teamId] = list;
          return list;
        }
      }
    } catch (_) {}

    final cached = _cachedMembers[teamId];
    if (cached != null) {
      if (_leftTeamIds.contains(teamId)) {
        final uid = AuthService.uid;
        return cached.where((m) => m.userId != uid).toList();
      }
      return cached;
    }

    final created = _userCreatedTeams
        .where((t) => t.teamId == teamId)
        .firstOrNull;
    if (created != null) {
      final defaultMembers = [
        TeamMember(
          userId: AuthService.uid ?? 'current_user',
          role: 'Captain',
          fullName: AuthService.currentUser?.displayName ?? 'Tôi (Đội trưởng)',
          position: 'Đội trưởng',
        ),
      ];
      _cachedMembers[teamId] = defaultMembers;
      return defaultMembers;
    }

    final fallback = TeamSeedData.getSampleMembers(teamId);
    _cachedMembers[teamId] = fallback;
    if (_leftTeamIds.contains(teamId)) {
      final uid = AuthService.uid;
      return fallback.where((m) => m.userId != uid).toList();
    }
    return fallback;
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
    } catch (e) {
      if (e is ApiException) {
        if (e.code == 'NETWORK_ERROR' ||
            e.code == 'TIMEOUT' ||
            e.statusCode == 503) {
          debugPrint('TeamService.removeMember server offline: $e');
        } else {
          throw AppException(e.message);
        }
      } else {
        throw AppException(e.toString());
      }
    } finally {
      _notify();
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
      await _api.post(
        '/teams/$teamId/join-requests',
        body: {'message': message},
      );
    } catch (e) {
      if (e is ApiException) {
        if (e.code == 'NETWORK_ERROR' ||
            e.code == 'TIMEOUT' ||
            e.statusCode == 503) {
          debugPrint('TeamService.sendJoinRequest server offline: $e');
        } else {
          throw AppException(e.message);
        }
      } else {
        throw AppException(e.toString());
      }
    } finally {
      _notify();
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
      await _api.patch(
        '/teams/${r.teamId}/join-requests/${r.requestId}',
        body: {'status': 'Approved'},
      );
      _notify();
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
    }
  }

  static Future<void> reject(JoinRequest r) async {
    try {
      await _api.patch(
        '/teams/${r.teamId}/join-requests/${r.requestId}',
        body: {'status': 'Rejected'},
      );
      _notify();
    } catch (e) {
      if (e is ApiException) throw AppException(e.message);
      throw AppException(e.toString());
    }
  }

  // ================= MATCHMAKING & GIAO HỮU =================

  /// Tìm danh sách đối thủ phù hợp theo khu vực
  static Future<List<MatchmakingCandidate>> findOpponents({
    String area = '',
    String myTeamId = '',
  }) async {
    try {
      final params = <String, dynamic>{
        if (area.isNotEmpty) 'area': area,
        if (myTeamId.isNotEmpty) 'myTeamId': myTeamId,
      };
      final res = await _api.get('/matchmaking/opponents', queryParams: params);
      if (res is List) {
        final list = res
            .whereType<Map>()
            .map(
              (m) => MatchmakingCandidate.fromMap(Map<String, dynamic>.from(m)),
            )
            .toList();
        if (list.isNotEmpty) return list;
      }
      return TeamSeedData.getSampleCandidates(area: area);
    } catch (_) {
      return TeamSeedData.getSampleCandidates(area: area);
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
    String resolvedFromTeamId = fromTeamId ?? '';
    String resolvedFromTeamName = 'Đội của tôi';

    if (resolvedFromTeamId.isEmpty) {
      final myTeams = await getMyTeams();
      if (myTeams.isNotEmpty) {
        resolvedFromTeamId = myTeams.first.teamId;
        resolvedFromTeamName = myTeams.first.teamName;
      } else {
        resolvedFromTeamId = 'team_user_default';
        resolvedFromTeamName =
            AuthService.currentUser?.displayName ?? 'Tôi (Đội trưởng)';
      }
    } else {
      final t = await getTeam(resolvedFromTeamId);
      if (t != null) resolvedFromTeamName = t.teamName;
    }

    final targetTeam = await getTeam(toTeamId);
    final targetTeamName = targetTeam?.teamName ?? 'Đội đối thủ';

    try {
      final body = {
        if (resolvedFromTeamId.isNotEmpty) 'fromTeamId': resolvedFromTeamId,
        'toTeamId': toTeamId,
        'message': message,
        if (proposedDate != null) 'proposedDate': proposedDate,
        if (venue != null) 'venue': venue,
      };
      final res = await _api.post('/invitations', body: body);
      final inv = FriendlyInvitation.fromMap(
        Map<String, dynamic>.from(res as Map),
      );
      _localInvitations.insert(0, inv);
      _notify();
      return inv;
    } catch (e) {
      if (e is ApiException) {
        if (e.code == 'NETWORK_ERROR' ||
            e.code == 'TIMEOUT' ||
            e.statusCode == 503) {
          debugPrint(
            'TeamService.sendFriendlyInvite server offline, keeping local invitation: $e',
          );
          final localInv = FriendlyInvitation(
            id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
            fromTeamId: resolvedFromTeamId,
            fromTeamName: resolvedFromTeamName,
            toTeamId: toTeamId,
            toTeamName: targetTeamName,
            status: 'Pending',
            message: message,
            proposedDate: proposedDate,
            venue: venue ?? targetTeam?.area,
            createdAt: DateTime.now(),
          );
          _localInvitations.insert(0, localInv);
          _notify();
          return localInv;
        }
        throw AppException(e.message);
      }
      throw AppException(e.toString());
    }
  }

  /// Lấy danh sách lời mời giao hữu của đội
  static Future<List<FriendlyInvitation>> getInvitations(String teamId) async {
    List<FriendlyInvitation> serverInvs = [];
    try {
      final res = await _api.get(
        '/invitations',
        queryParams: {'teamId': teamId},
        timeout: const Duration(seconds: 3),
      );
      if (res is List) {
        serverInvs = res
            .whereType<Map>()
            .map(
              (m) => FriendlyInvitation.fromMap(Map<String, dynamic>.from(m)),
            )
            .toList();
      }
    } catch (_) {}

    final matchingLocal = _localInvitations.where(
      (inv) => inv.toTeamId == teamId || inv.fromTeamId == teamId,
    );

    final all = [
      ...matchingLocal,
      ...serverInvs.where((s) => !_localInvitations.any((l) => l.id == s.id)),
    ];
    return all;
  }

  /// Phản hồi lời mời giao hữu ('Accepted', 'Declined', 'Cancelled')
  static Future<void> respondInvitation(
    String invitationId,
    String status,
  ) async {
    final idx = _localInvitations.indexWhere((i) => i.id == invitationId);
    if (idx != -1) {
      final old = _localInvitations[idx];
      _localInvitations[idx] = FriendlyInvitation(
        id: old.id,
        fromTeamId: old.fromTeamId,
        fromTeamName: old.fromTeamName,
        toTeamId: old.toTeamId,
        toTeamName: old.toTeamName,
        status: status,
        message: old.message,
        proposedDate: old.proposedDate,
        venue: old.venue,
        createdAt: old.createdAt,
      );
    }

    try {
      await _api.patch('/invitations/$invitationId', body: {'status': status});
    } catch (e) {
      if (e is ApiException) {
        if (e.code == 'NETWORK_ERROR' ||
            e.code == 'TIMEOUT' ||
            e.statusCode == 503) {
          debugPrint(
            'TeamService.respondInvitation server offline, kept local status: $e',
          );
          _notify();
          return;
        }
        throw AppException(e.message);
      }
      throw AppException(e.toString());
    } finally {
      _notify();
    }
  }

  /// Kiểm tra xem đã gửi lời mời giao hữu đến đội này và đang chờ phản hồi hay chưa
  static bool hasPendingInvitation(String targetTeamId) {
    return _localInvitations.any(
      (inv) =>
          inv.toTeamId == targetTeamId &&
          (inv.status.toLowerCase() == 'pending' ||
              inv.status.toLowerCase() == 'chờ phản hồi'),
    );
  }

  /// Lấy lời mời thi đấu giao hữu mới nhất liên quan đến đội này
  static FriendlyInvitation? getInvitationForTeam(
    String targetTeamId, {
    Iterable<String>? myTeamIds,
    bool pendingOnly = true,
  }) {
    final ids = myTeamIds?.toSet() ?? <String>{};
    final match = _localInvitations.where((inv) {
      if (inv.toTeamId == targetTeamId) {
        if (ids.isEmpty ||
            ids.contains(inv.fromTeamId) ||
            inv.fromTeamId == 'team_user_default' ||
            inv.fromTeamId.isEmpty) {
          if (pendingOnly) {
            final s = inv.status.toLowerCase();
            return s == 'pending' || s == 'chờ phản hồi';
          }
          return true;
        }
      }
      return false;
    });
    return match.isNotEmpty ? match.first : null;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/team.dart';
import 'auth_service.dart';

class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

class TeamService {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get teams => _db.collection('teams');
  static CollectionReference<Map<String, dynamic>> get teamMembers => _db.collection('teamMembers');
  static CollectionReference<Map<String, dynamic>> get joinRequests => _db.collection('joinRequests');

  // Báo cho các màn hình biết dữ liệu đội đã thay đổi để load lại
  static final ValueNotifier<int> changed = ValueNotifier(0);
  static void _notify() => changed.value++;

  // Id dạng teamId_userId để dễ kiểm tra trùng
  static String _linkId(String teamId, String userId) => '${teamId}_$userId';

  static Future<Map<String, AppUser>> _fetchUsers(List<String> ids) async {
    final docs = await Future.wait(ids.map((id) => AuthService.users.doc(id).get()));
    return {
      for (final d in docs)
        if (d.exists) d.id: AppUser.fromMap(d.data()!),
    };
  }

  // ================= ĐỘI BÓNG =================

  static Future<List<Team>> search({String keyword = '', String area = ''}) async {
    final snap = await teams.orderBy('createdAt', descending: true).get();
    final kw = keyword.trim().toLowerCase();
    final ar = area.trim().toLowerCase();
    return snap.docs
        .map((d) => Team.fromMap(d.data()))
        .where((t) =>
            (kw.isEmpty || t.teamName.toLowerCase().contains(kw)) &&
            (ar.isEmpty || t.area.toLowerCase().contains(ar)))
        .toList();
  }

  static Future<List<Team>> getMyTeams() async {
    final snap = await teamMembers.where('userId', isEqualTo: AuthService.uid).get();
    final ids = snap.docs.map((d) => d['teamId'] as String).toList();
    final docs = await Future.wait(ids.map((id) => teams.doc(id).get()));
    return docs.where((d) => d.exists).map((d) => Team.fromMap(d.data()!)).toList();
  }

  static Future<Team?> getTeam(String teamId) async {
    final doc = await teams.doc(teamId).get();
    return doc.exists ? Team.fromMap(doc.data()!) : null;
  }

  static Future<bool> _nameTaken(String name, {String? exceptId}) async {
    final snap = await teams.where('teamNameLower', isEqualTo: name.toLowerCase()).get();
    return snap.docs.any((d) => d.id != exceptId);
  }

  static Future<void> createTeam(String name, String area, String description) async {
    final uid = AuthService.uid!;
    if (await _nameTaken(name)) throw AppException('Tên đội đã tồn tại');

    final meDoc = await AuthService.users.doc(uid).get();
    final myName = meDoc.data()?['fullName'] ?? '';

    final ref = teams.doc();
    final batch = _db.batch();
    batch.set(ref, {
      'teamId': ref.id,
      'teamName': name,
      'teamNameLower': name.toLowerCase(),
      'area': area,
      'description': description,
      'captainId': uid,
      'captainName': myName,
      'memberCount': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Người tạo tự động là đội trưởng
    batch.set(teamMembers.doc(_linkId(ref.id, uid)), {
      'teamId': ref.id,
      'userId': uid,
      'role': 'Captain',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    _notify();
  }

  static Future<void> updateTeam(String teamId, String name, String area, String description) async {
    if (await _nameTaken(name, exceptId: teamId)) throw AppException('Tên đội đã tồn tại');
    await teams.doc(teamId).update({
      'teamName': name,
      'teamNameLower': name.toLowerCase(),
      'area': area,
      'description': description,
    });
    _notify();
  }

  // ================= THÀNH VIÊN =================

  static Future<List<TeamMember>> getMembers(String teamId) async {
    final snap = await teamMembers.where('teamId', isEqualTo: teamId).get();
    final users = await _fetchUsers(snap.docs.map((d) => d['userId'] as String).toList());
    final list = snap.docs.map((d) {
      final u = users[d['userId']];
      return TeamMember(
        userId: d['userId'],
        role: d['role'] ?? 'Member',
        fullName: u?.fullName ?? '(Không rõ)',
        avatarBase64: u?.avatarBase64,
        position: u?.position,
      );
    }).toList();
    list.sort((a, b) => a.role == 'Captain' ? -1 : (b.role == 'Captain' ? 1 : 0));
    return list;
  }

  static Future<bool> isMember(String teamId) async {
    final doc = await teamMembers.doc(_linkId(teamId, AuthService.uid!)).get();
    return doc.exists;
  }

  // Đội trưởng xóa thành viên, hoặc tự rời đội
  static Future<void> removeMember(String teamId, String userId) async {
    final batch = _db.batch();
    batch.delete(teamMembers.doc(_linkId(teamId, userId)));
    batch.update(teams.doc(teamId), {'memberCount': FieldValue.increment(-1)});
    await batch.commit();
    _notify();
  }

  // ================= YÊU CẦU GIA NHẬP =================

  static Future<bool> hasPendingRequest(String teamId) async {
    final doc = await joinRequests.doc(_linkId(teamId, AuthService.uid!)).get();
    return doc.exists && doc.data()?['status'] == 'Pending';
  }

  static Future<void> sendJoinRequest(String teamId, String message) async {
    final uid = AuthService.uid!;
    if (await isMember(teamId)) throw AppException('Bạn đã là thành viên của đội');
    final id = _linkId(teamId, uid);
    await joinRequests.doc(id).set({
      'requestId': id,
      'teamId': teamId,
      'userId': uid,
      'message': message,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    _notify();
  }

  static Future<List<JoinRequest>> getPendingRequests(String teamId) async {
    final snap = await joinRequests
        .where('teamId', isEqualTo: teamId)
        .where('status', isEqualTo: 'Pending')
        .get();
    final users = await _fetchUsers(snap.docs.map((d) => d['userId'] as String).toList());
    return snap.docs.map((d) {
      final u = users[d['userId']];
      return JoinRequest(
        requestId: d.id,
        teamId: d['teamId'],
        userId: d['userId'],
        message: d['message'],
        fullName: u?.fullName ?? '(Không rõ)',
        avatarBase64: u?.avatarBase64,
        position: u?.position,
      );
    }).toList();
  }

  static Future<void> approve(JoinRequest r) async {
    final batch = _db.batch();
    batch.update(joinRequests.doc(r.requestId), {'status': 'Approved'});
    batch.set(teamMembers.doc(_linkId(r.teamId, r.userId)), {
      'teamId': r.teamId,
      'userId': r.userId,
      'role': 'Member',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.update(teams.doc(r.teamId), {'memberCount': FieldValue.increment(1)});
    await batch.commit();
    _notify();
  }

  static Future<void> reject(JoinRequest r) async {
    await joinRequests.doc(r.requestId).update({'status': 'Rejected'});
    _notify();
  }
}
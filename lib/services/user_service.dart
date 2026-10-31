import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/auth/auth_context.dart' hide AppUser;
import '../models/app_user.dart';
import 'auth_service.dart';

class UserService {
  static final ApiClient _api = ApiClient();
  static AppUser? currentUser;
  static final ValueNotifier<AppUser?> currentUserNotifier = ValueNotifier<AppUser?>(null);

  /// Lấy thông tin hồ sơ của người dùng hiện tại
  static Future<AppUser?> getProfile() async {
    // 1. Gọi backend REST API
    try {
      final res = await _api.get('/users/me');
      if (res is Map<String, dynamic>) {
        final user = AppUser.fromMap(res);
        currentUser = user;
        currentUserNotifier.value = user;
        return user;
      }
    } catch (_) {}

    // 2. Fallback Firestore
    final uid = AuthService.uid;
    if (uid != null) {
      try {
        final doc = await AuthService.users.doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final user = AppUser.fromMap(doc.data()!);
          currentUser = user;
          currentUserNotifier.value = user;
          return user;
        }
      } catch (_) {}
    }

    return currentUser;
  }

  /// Cập nhật hồ sơ người dùng đồng bộ: Backend API, Firebase Auth, Cloud Firestore & State
  static Future<AppUser> updateProfile({
    required String fullName,
    String? phone,
    String? position,
    String? area,
  }) async {
    final uid = AuthService.uid ?? 'user_current';
    final email = AuthService.currentUser?.email ?? '';

    AppUser updated = AppUser(
      userId: uid,
      fullName: fullName,
      email: email,
      phone: phone,
      position: position,
      area: area,
      avatarBase64: currentUser?.avatarBase64,
    );

    // 1. Cập nhật Firebase Auth displayName để đồng bộ session
    try {
      await AuthService.currentUser?.updateDisplayName(fullName);
    } catch (_) {}

    // 2. Gửi request PATCH lên Backend REST API
    try {
      final res = await _api.patch('/users/me', body: {
        'fullName': fullName,
        'phone': phone,
        'position': position,
        'area': area,
      });
      if (res is Map<String, dynamic>) {
        updated = AppUser.fromMap(res);
      }
    } catch (_) {}

    // 3. Ghi vào Cloud Firestore (merge: true để tạo nếu doc chưa có)
    if (AuthService.uid != null) {
      try {
        await AuthService.users.doc(AuthService.uid).set({
          'userId': uid,
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'position': position,
          'area': area,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    // 4. Đồng bộ AuthContext persona nếu đang chạy chế độ context
    try {
      final cur = AuthContext.instance.currentUser;
      AuthContext.instance.switchUser(cur.copyWith(name: fullName));
    } catch (_) {}

    // 5. Cập nhật cache và phát tín hiệu cho UI
    currentUser = updated;
    currentUserNotifier.value = updated;
    return updated;
  }

  static Future<void> updateAvatar(Uint8List bytes) async {
    if (bytes.length > 700 * 1024) {
      throw Exception('Ảnh quá lớn, vui lòng chọn ảnh khác (dưới 700KB)');
    }
    final base64Str = base64Encode(bytes);
    try {
      await _api.post('/users/me/avatar', body: {
        'avatarBase64': base64Str,
      });
    } catch (_) {}

    final uid = AuthService.uid;
    if (uid != null) {
      try {
        await AuthService.users.doc(uid).set({
          'avatarBase64': base64Str,
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    if (currentUser != null) {
      currentUser = currentUser!.copyWith(avatarBase64: base64Str);
      currentUserNotifier.value = currentUser;
    }
  }
}
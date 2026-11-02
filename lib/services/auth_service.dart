import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

/// Service xác thực người dùng và quản lý phiên đăng nhập (Firebase Authentication & Firestore)
class AuthService {
  /// Instance Firebase Auth dùng để quản lý session đăng nhập
  static final _auth = FirebaseAuth.instance;

  /// Instance Cloud Firestore dùng để truy xuất collection người dùng
  static final _db = FirebaseFirestore.instance;

  /// Reference tới collection 'users' trong Firestore
  static CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');

  /// UID giả lập phục vụ viết Unit Test
  @visibleForTesting
  static String? mockUid;

  /// Lấy mã định danh (UID) của người dùng hiện tại đang đăng nhập
  static String? get uid {
    if (mockUid != null) {
      return mockUid; // 1. Ưu tiên mockUid nếu đang chạy kiểm thử
    }
    try {
      return _auth
          .currentUser
          ?.uid; // 2. Lấy UID thực tế từ Firebase Auth session
    } catch (_) {
      return null; // 3. Trả về null nếu Firebase Auth chưa được khởi tạo
    }
  }

  /// Lấy đối tượng Firebase User của người dùng đang đăng nhập
  static User? get currentUser {
    try {
      return _auth.currentUser; // 1. Truy xuất đối tượng User từ Firebase Auth
    } catch (_) {
      return null; // 2. Trả về null nếu có lỗi khởi tạo
    }
  }

  /// Lắng nghe luồng thay đổi trạng thái đăng nhập theo thời gian thực (đăng nhập/đăng xuất)
  static Stream<User?> authChanges() => _auth.authStateChanges();

  /// Đăng ký tài khoản mới bằng Email và Mật khẩu, đồng thời khởi tạo profile trong Firestore
  static Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    // 1. Gọi Firebase Auth để tạo tài khoản mới với email và password
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final id = cred.user!.uid;

    // 2. Cập nhật tên hiển thị (displayName) lên Firebase Auth
    try {
      await cred.user?.updateDisplayName(fullName);
    } catch (_) {}

    // 3. Ghi thông tin profile vào Firestore nếu có, giới hạn timeout 2 giây để tránh treo UI
    try {
      await users
          .doc(id)
          .set({
            'userId': id,
            'fullName': fullName,
            'email': email,
            'phone': phone,
            'avatarUrl': null,
            'position': null,
            'area': null,
            'role': 'User',
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // Tiếp tục hoàn tất đăng ký dù Firestore chưa bật hoặc API-First chặn direct write
    }
  }

  /// Đăng nhập vào hệ thống bằng Email và Mật khẩu
  static Future<void> login(String email, String password) async {
    // Gọi Firebase Auth để xác thực thông tin đăng nhập
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Đăng xuất khỏi hệ thống và xóa session hiện tại
  static Future<void> logout() async {
    // Gọi Firebase Auth để kết thúc phiên làm việc
    await _auth.signOut();
  }

  /// Lắng nghe thông tin hồ sơ của người dùng hiện tại từ Firestore theo thời gian thực
  static Stream<AppUser?> currentUserStream() {
    // 1. Kiểm tra UID của người dùng hiện tại
    final id = uid;
    if (id == null) return Stream.value(null);

    // 2. Lắng nghe snapshot document từ Firestore và map sang model AppUser
    try {
      return users
          .doc(id)
          .snapshots()
          .map((doc) => doc.exists ? AppUser.fromMap(doc.data()!) : null)
          .handleError((_) => null);
    } catch (_) {
      return Stream.value(null);
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get users => _db.collection('users');

  @visibleForTesting
  static String? mockUid;

  static String? get uid {
    if (mockUid != null) return mockUid;
    try {
      return _auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  // Lắng nghe trạng thái đăng nhập
  static Stream<User?> authChanges() => _auth.authStateChanges();

  // Đăng ký: tạo tài khoản + lưu thông tin vào collection users
  static Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final id = cred.user!.uid;

    // Cập nhật tên hiển thị lên Firebase Auth
    try {
      await cred.user?.updateDisplayName(fullName);
    } catch (_) {}

    // Ghi thông tin profile vào Firestore nếu có, giới hạn timeout 2 giây để tránh treo ứng dụng khi Firestore chưa được kích hoạt
    try {
      await users.doc(id).set({
        'userId': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'avatarUrl': null,
        'position': null,
        'area': null,
        'role': 'User',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 2));
    } catch (_) {
      // Tiếp tục hoàn tất đăng ký dù Firestore chưa bật hoặc API-First chặn direct write
    }
  }

  static Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Lấy thông tin user hiện tại, tự cập nhật khi dữ liệu thay đổi
  static Stream<AppUser?> currentUserStream() {
    final id = uid;
    if (id == null) return Stream.value(null);
    return users
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromMap(doc.data()!) : null)
        .handleError((_) => null);
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get users => _db.collection('users');

  static String? get uid => _auth.currentUser?.uid;

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
    });
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
    return users.doc(id).snapshots().map((doc) => doc.exists ? AppUser.fromMap(doc.data()!) : null);
  }
}
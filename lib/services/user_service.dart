import 'dart:convert';
import 'dart:typed_data';
import '../core/api/api_client.dart';
import 'auth_service.dart';

class UserService {
  static final ApiClient _api = ApiClient();

  static Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? position,
    String? area,
  }) async {
    try {
      await _api.patch('/users/me', body: {
        'fullName': fullName,
        'phone': phone,
        'position': position,
        'area': area,
      });
    } catch (_) {
      // Fallback cho Firestore nếu backend chưa online
      final uid = AuthService.uid;
      if (uid != null) {
        await AuthService.users.doc(uid).update({
          'fullName': fullName,
          'phone': phone,
          'position': position,
          'area': area,
        });
      }
    }
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
    } catch (_) {
      final uid = AuthService.uid;
      if (uid != null) {
        await AuthService.users.doc(uid).update({
          'avatarBase64': base64Str,
        });
      }
    }
  }
}
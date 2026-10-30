import 'dart:convert';
import 'dart:typed_data';
import 'auth_service.dart';

class UserService {
  static Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? position,
    String? area,
  }) async {
    await AuthService.users.doc(AuthService.uid!).update({
      'fullName': fullName,
      'phone': phone,
      'position': position,
      'area': area,
    });
  }

  static Future<void> updateAvatar(Uint8List bytes) async {
    if (bytes.length > 700 * 1024) {
      throw Exception('Ảnh quá lớn, vui lòng chọn ảnh khác');
    }
    await AuthService.users.doc(AuthService.uid!).update({
      'avatarBase64': base64Encode(bytes),
    });
  }
}
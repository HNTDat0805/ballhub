import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ballhub/core/api/api_client.dart';
import 'package:ballhub/core/auth/auth_context.dart' as auth_ctx;
import 'package:ballhub/models/app_user.dart';
import 'package:ballhub/services/user_service.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

http.Response jsonResponse(dynamic data, [int statusCode = 200]) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(data)),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  setUp(() {
    UserService.currentUser = null;
    UserService.currentUserNotifier.value = null;
  });

  group('UserService & User Profile REST API Tests (22 test cases)', () {
    final sampleUserMap = {
      'userId': 'usr_test_1',
      'fullName': 'Nguyễn Văn Cầu Thủ',
      'email': 'cauthu@example.com',
      'phone': '0909123456',
      'position': 'Tiền đạo cắm (ST)',
      'area': 'Bình Thạnh, TP. Hồ Chí Minh',
      'avatarBase64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      'role': 'Player',
    };

    // 1. getProfile success
    test('1. getProfile returns AppUser when REST API /users/me succeeds', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/users/me');
        return jsonResponse({'success': true, 'data': sampleUserMap});
      });
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final user = await UserService.getProfile();
      expect(user, isNotNull);
      expect(user!.userId, 'usr_test_1');
      expect(user.fullName, 'Nguyễn Văn Cầu Thủ');
    });

    // 2. getProfile triggers notifier
    test('2. getProfile sets currentUser and triggers currentUserNotifier', () async {
      final mock = MockHttpClient((req) async {
        return jsonResponse({'success': true, 'data': sampleUserMap});
      });
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      AppUser? notifiedUser;
      UserService.currentUserNotifier.addListener(() {
        notifiedUser = UserService.currentUserNotifier.value;
      });

      await UserService.getProfile();
      expect(UserService.currentUser, isNotNull);
      expect(notifiedUser?.userId, 'usr_test_1');
    });

    // 3. getProfile network error
    test('3. getProfile handles network error gracefully', () async {
      final mock = MockHttpClient((req) async => jsonResponse('Network down', 503));
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final user = await UserService.getProfile();
      expect(user, isNull);
    });

    // 4. updateProfile sends fullName
    test('4. updateProfile sends PATCH /users/me with fullName and updates state', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'PATCH');
        expect(req.url.path, '/api/v1/users/me');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({
          'success': true,
          'data': {...sampleUserMap, 'fullName': 'Nguyễn Văn Mới'}
        });
      });
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final updated = await UserService.updateProfile(fullName: 'Nguyễn Văn Mới');
      expect(body['fullName'], 'Nguyễn Văn Mới');
      expect(updated.fullName, 'Nguyễn Văn Mới');
      expect(UserService.currentUser?.fullName, 'Nguyễn Văn Mới');
    });

    // 5. updateProfile sends phone
    test('5. updateProfile sends phone parameter to PATCH /users/me', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleUserMap});
      });
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      await UserService.updateProfile(fullName: 'Tên', phone: '0988776655');
      expect(body['phone'], '0988776655');
    });

    // 6. updateProfile sends position
    test('6. updateProfile sends position parameter to PATCH /users/me', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleUserMap});
      });
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      await UserService.updateProfile(fullName: 'Tên', position: 'Thủ môn (GK)');
      expect(body['position'], 'Thủ môn (GK)');
    });

    // 7. updateProfile sends area
    test('7. updateProfile sends area parameter to PATCH /users/me', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleUserMap});
      });
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      await UserService.updateProfile(fullName: 'Tên', area: 'Quận 7');
      expect(body['area'], 'Quận 7');
    });

    // 8. updateProfile sends all fields
    test('8. updateProfile sends all profile fields simultaneously', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleUserMap});
      });
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      await UserService.updateProfile(
        fullName: 'Đặng Văn Lâm',
        phone: '0911223344',
        position: 'Thủ môn',
        area: 'TP. Hồ Chí Minh',
      );
      expect(body['fullName'], 'Đặng Văn Lâm');
      expect(body['phone'], '0911223344');
      expect(body['position'], 'Thủ môn');
      expect(body['area'], 'TP. Hồ Chí Minh');
    });

    // 9. updateProfile triggers notifier
    test('9. updateProfile triggers currentUserNotifier listener', () async {
      final mock = MockHttpClient((req) async => jsonResponse({'success': true, 'data': sampleUserMap}));
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      bool notified = false;
      UserService.currentUserNotifier.addListener(() {
        notified = true;
      });

      await UserService.updateProfile(fullName: 'Test Notifier');
      expect(notified, true);
    });

    // 10. updateProfile updates AuthContext persona
    test('10. updateProfile synchronizes AuthContext persona user name', () async {
      final mock = MockHttpClient((req) async => jsonResponse({'success': true, 'data': sampleUserMap}));
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      await UserService.updateProfile(fullName: 'Đỗ Hùng Dũng');
      expect(auth_ctx.AuthContext.instance.currentUser.name, 'Đỗ Hùng Dũng');
    });

    // 11. updateAvatar sends Base64
    test('11. updateAvatar encodes image bytes to Base64 and posts to /users/me/avatar', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/v1/users/me/avatar');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': {'avatarBase64': body['avatarBase64']}});
      });
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      await UserService.updateAvatar(dummyBytes);
      expect(body['avatarBase64'], base64Encode(dummyBytes));
    });

    // 12. updateAvatar rejects > 700KB
    test('12. updateAvatar rejects images exceeding 700KB with Exception', () async {
      final mock = MockHttpClient((req) async => jsonResponse({'success': true}));
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final oversizedBytes = Uint8List(701 * 1024);
      expect(
        () => UserService.updateAvatar(oversizedBytes),
        throwsA(isA<Exception>()),
      );
    });

    // 13. updateAvatar accepts <= 700KB
    test('13. updateAvatar accepts image of exactly 500KB', () async {
      final mock = MockHttpClient((req) async => jsonResponse({'success': true}));
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final validBytes = Uint8List(500 * 1024);
      await UserService.updateAvatar(validBytes);
      expect(true, true);
    });

    // 14. updateAvatar updates currentUser.avatarBase64
    test('14. updateAvatar updates currentUser.avatarBase64 in memory', () async {
      final mock = MockHttpClient((req) async => jsonResponse({'success': true}));
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      UserService.currentUser = AppUser(
        userId: 'u_mem',
        fullName: 'Tên A',
        email: 'a@a.com',
      );

      final imageBytes = Uint8List.fromList([10, 20, 30]);
      await UserService.updateAvatar(imageBytes);
      expect(UserService.currentUser?.avatarBase64, base64Encode(imageBytes));
    });

    // 15. updateAvatar notifies listener
    test('15. updateAvatar notifies currentUserNotifier on success', () async {
      final mock = MockHttpClient((req) async => jsonResponse({'success': true}));
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      UserService.currentUser = AppUser(userId: 'u1', fullName: 'A', email: 'a@a.com');
      bool notified = false;
      UserService.currentUserNotifier.addListener(() {
        notified = true;
      });

      await UserService.updateAvatar(Uint8List.fromList([1, 2]));
      expect(notified, true);
    });

    // 16. AppUser fromMap and toMap roundtrip
    test('16. AppUser fromMap and toMap roundtrip preserves all fields', () {
      final user = AppUser.fromMap(sampleUserMap);
      expect(user.userId, 'usr_test_1');
      expect(user.fullName, 'Nguyễn Văn Cầu Thủ');
      expect(user.phone, '0909123456');
      expect(user.position, 'Tiền đạo cắm (ST)');
      expect(user.area, 'Bình Thạnh, TP. Hồ Chí Minh');

      final map = user.toMap();
      expect(map['userId'], 'usr_test_1');
      expect(map['fullName'], 'Nguyễn Văn Cầu Thủ');
      expect(map['position'], 'Tiền đạo cắm (ST)');
    });

    // 17. AppUser copyWith
    test('17. AppUser copyWith updates only specified fields', () {
      final user = AppUser.fromMap(sampleUserMap);
      final updated = user.copyWith(fullName: 'Tên Mới Cóng', phone: '0123456789');

      expect(updated.fullName, 'Tên Mới Cóng');
      expect(updated.phone, '0123456789');
      expect(updated.userId, user.userId);
      expect(updated.email, user.email);
      expect(updated.position, user.position);
    });

    // 18. AppUser copyWith preserves when null
    test('18. AppUser copyWith maintains fields when no new values provided', () {
      final user = AppUser.fromMap(sampleUserMap);
      final cloned = user.copyWith();

      expect(cloned.userId, user.userId);
      expect(cloned.fullName, user.fullName);
      expect(cloned.area, user.area);
    });

    // 19. AppUser defaults empty strings for required fields if missing
    test('19. AppUser defaults empty strings for required fields if missing', () {
      final user = AppUser.fromMap({
        'userId': 'usr_def',
      });
      expect(user.fullName, '');
      expect(user.email, '');
    });

    // 20. AppUser empty phone & position
    test('20. AppUser handles missing optional fields cleanly', () {
      final user = AppUser.fromMap({
        'userId': 'usr_minimal',
        'email': 'min@example.com',
      });
      expect(user.phone, isNull);
      expect(user.position, isNull);
      expect(user.area, isNull);
      expect(user.avatarBase64, isNull);
    });

    // 21. updateProfile offline fallback
    test('21. updateProfile falls back to local user object when offline', () async {
      final mock = MockHttpClient((req) async => jsonResponse('Service Unavailable', 503));
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final user = await UserService.updateProfile(
        fullName: 'Hồ Tấn Tài Offline',
        position: 'Hậu vệ',
      );
      expect(user.fullName, 'Hồ Tấn Tài Offline');
      expect(user.position, 'Hậu vệ');
    });

    // 22. updateAvatar offline handles silently
    test('22. updateAvatar does not throw when backend is offline', () async {
      final mock = MockHttpClient((req) async => jsonResponse('Service Unavailable', 503));
      UserService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      await UserService.updateAvatar(Uint8List.fromList([9, 8, 7]));
      expect(true, true);
    });
  });
}

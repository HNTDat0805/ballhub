import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ballhub/core/api/api_client.dart';
import 'package:ballhub/core/auth/auth_context.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        ...response.headers,
      },
    );
  }
}

void main() {
  group('ApiClient Tests', () {
    test('attaches correct auth and user headers', () async {
      AuthContext.instance.switchUser(const AppUser(
        id: 'test_user_01',
        name: 'Nguyen Tester',
        email: 'tester@ballhub.vn',
        role: UserRole.organizer,
      ));

      late http.BaseRequest capturedRequest;
      final mockClient = MockHttpClient((req) async {
        capturedRequest = req;
        return http.Response(jsonEncode({'success': true, 'data': {'status': 'ok'}}), 200);
      });

      final client = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final res = await client.get('/health');

      expect(res, {'status': 'ok'});
      expect(capturedRequest.headers['x-user-id'], 'test_user_01');
      expect(capturedRequest.headers['x-user-role'], 'organizer');
      expect(capturedRequest.headers['Authorization'], 'Bearer mock-token-test_user_01-organizer');
    });

    test('parses data from envelope response', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response(jsonEncode({
          'success': true,
          'data': [
            {'id': 't1', 'name': 'Tournament 1'}
          ]
        }), 200);
      });

      final client = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final res = await client.get('/tournaments');

      expect(res, isA<List>());
      expect((res as List).length, 1);
      expect(res[0]['name'], 'Tournament 1');
    });

    test('throws ApiException on 400 with message from backend', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response.bytes(utf8.encode(jsonEncode({
          'success': false,
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'Số đội tối đa phải từ 2 trở lên.',
          }
        })), 400);
      });

      final client = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);

      expect(
        () => client.post('/tournaments', body: {'maxTeams': 1}),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Số đội tối đa phải từ 2 trở lên.',
        )),
      );
    });

    test('throws ApiException on 403 Forbidden', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response.bytes(utf8.encode(jsonEncode({
          'success': false,
          'error': {
            'code': 'PERMISSION_DENIED',
            'message': 'Bạn không có quyền thực hiện thao tác này.',
          }
        })), 403);
      });

      final client = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);

      expect(
        () => client.delete('/tournaments/t1'),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          403,
        )),
      );
    });
  });
}

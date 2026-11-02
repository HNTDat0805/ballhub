import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ballhub/core/api/api_client.dart';
import 'package:ballhub/features/booking/data/api_booking_repository.dart';
import 'package:ballhub/models/app_user.dart';
import 'package:ballhub/screens/teams/team_list_screen.dart';
import 'package:ballhub/screens/profile/profile_screen.dart';
import 'package:ballhub/services/team_service.dart';
import 'package:ballhub/services/user_service.dart';
import 'package:ballhub/services/auth_service.dart';

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
  setUp(() {
    TeamService.resetStateForTesting();
    AuthService.mockUid = 'user_test';
    final apiClient = ApiClient(
      baseUrl: 'http://localhost:5001/api/v1',
      client: MockHttpClient((req) async {
        if (req.method == 'DELETE' && req.url.path.contains('/teams/')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'deleted': true},
            }),
            200,
          );
        }
        if (req.url.path.contains('/teams/mine')) {
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        }
        if (req.url.path.contains('/teams')) {
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        }
        if (req.url.path.contains('/users/me')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'userId': 'user_test', 'fullName': 'Người dùng thử'},
            }),
            200,
          );
        }
        if (req.url.path.contains('/bookings/me')) {
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      }),
    );
    TeamService.api = apiClient;
    UserService.api = apiClient;
  });

  tearDown(() {
    TeamService.resetStateForTesting();
    AuthService.mockUid = null;
  });

  group('Team Disband Instant Update Tests', () {
    test('deleteTeam marks isTeamDeleted and updates localTeams synchronously at 0ms', () async {
      await TeamService.createTeam('FC Buikienhao Test', 'Quận 1', 'Mô tả đội');

      expect(
        TeamService.localTeams.any((t) => t.teamName == 'FC Buikienhao Test'),
        isTrue,
      );

      final team = TeamService.localTeams.firstWhere(
        (t) => t.teamName == 'FC Buikienhao Test',
      );

      // Thực hiện giải tán
      await TeamService.deleteTeam(team.teamId, teamName: team.teamName);

      // Phải lập tức được đánh dấu xóa và loại bỏ khỏi localTeams
      expect(TeamService.isTeamDeleted(team.teamId, team.teamName), isTrue);
      expect(
        TeamService.localTeams.any((t) => t.teamId == team.teamId),
        isFalse,
      );
    });

    testWidgets(
      'TeamListScreen immediately removes disbanded team without delay',
      (tester) async {
        await TeamService.createTeam(
          'FC Buikienhao Disband',
          'Quận 1',
          'Đội sắp giải tán',
        );

        await tester.pumpWidget(const MaterialApp(home: TeamListScreen()));

        // Đội xuất hiện trong danh sách
        expect(find.text('FC Buikienhao Disband'), findsOneWidget);

        final team = TeamService.localTeams.firstWhere(
          (t) => t.teamName == 'FC Buikienhao Disband',
        );

        // Giải tán đội bóng
        await TeamService.deleteTeam(team.teamId, teamName: team.teamName);

        // Bơm 1 frame (0ms) - UI phải lập tức mất đội cũ
        await tester.pump();
        expect(find.text('FC Buikienhao Disband'), findsNothing);
      },
    );

    testWidgets(
      'ProfileScreen immediately updates to empty state when my team is disbanded',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await TeamService.createTeam(
          'FC Buikienhao Profile',
          'Quận 1',
          'Đội của tôi',
        );

        final testUser = AppUser(
          userId: 'user_test',
          fullName: 'Người dùng thử',
          email: 'test@example.com',
        );

        final bookingRepo = ApiBookingRepository(client: TeamService.api);

        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(user: testUser, bookingRepository: bookingRepo),
          ),
        );

        // Ban đầu hiện đội bóng của tôi
        expect(find.text('FC Buikienhao Profile'), findsOneWidget);

        final team = TeamService.localTeams.firstWhere(
          (t) => t.teamName == 'FC Buikienhao Profile',
        );

        // Giải tán đội
        await TeamService.deleteTeam(team.teamId, teamName: team.teamName);

        // Bơm 1 frame (0ms) - giao diện phải lập tức cập nhật không còn hiện đội cũ
        await tester.pump();
        expect(find.text('FC Buikienhao Profile'), findsNothing);
        expect(find.text('Bạn chưa tham gia đội bóng nào.'), findsOneWidget);
      },
    );
  });
}

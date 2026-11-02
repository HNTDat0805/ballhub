import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ballhub/core/api/api_client.dart';
import 'package:ballhub/models/team.dart';
import 'package:ballhub/screens/teams/team_detail_screen.dart';
import 'package:ballhub/services/team_service.dart';

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
    TeamService.api = ApiClient(
      baseUrl: 'http://localhost:5001/api/v1',
      client: MockHttpClient((req) async {
        if (req.url.path.contains('/members')) {
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        }
        if (req.url.path.contains('/mine')) {
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        }
        if (req.url.path.contains('/invitations')) {
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'team_1',
              'name': 'FC Sài Gòn Hoa',
              'area': 'Quận 1',
              'description': 'Đội bóng giao hữu',
            },
          }),
          200,
        );
      }),
    );
  });

  tearDown(() {
    TeamService.resetStateForTesting();
  });

  group('TeamDetailScreen Instant Loading Tests', () {
    testWidgets(
      'renders instantly when initialTeam is provided without waiting for network',
      (tester) async {
        final sampleTeam = Team(
          teamId: 'team_fast_01',
          teamName: 'FC Tốc Độ Cao',
          area: 'Bình Thạnh',
          description: 'Đội bóng đá phủi',
          captainId: 'cap_01',
          captainName: 'Nguyễn Văn A',
          memberCount: 15,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TeamDetailScreen(
              teamId: sampleTeam.teamId,
              initialTeam: sampleTeam,
            ),
          ),
        );

        // Ngay sau frame đầu tiên, thông tin đội bóng phải xuất hiện ngay lập tức mà không bị kẹt ở màn hình loading
        expect(find.text('FC Tốc Độ Cao'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Chờ hoàn tất tác vụ background
        await tester.pumpAndSettle();
        expect(find.text('FC Tốc Độ Cao'), findsOneWidget);
      },
    );

    testWidgets(
      'renders instantly from cached seed team when teamId exists in seeds',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TeamDetailScreen(
              teamId:
                  'team_sao_vang', // team_sao_vang tồn tại trong TeamSeedData
            ),
          ),
        );

        // Màn hình hiển thị ngay thông tin từ cache seed mà không bắt người dùng chờ
        expect(find.byType(TeamDetailScreen), findsOneWidget);
        expect(find.text('FC Sao Vàng'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.pumpAndSettle();
      },
    );

    test(
      'findTeamCached and findMembersCached return data synchronously at 0ms',
      () {
        final team = TeamService.findTeamCached('team_sao_vang');
        expect(team, isNotNull);
        expect(team!.teamId, 'team_sao_vang');

        final members = TeamService.findMembersCached('team_sao_vang');
        expect(members, isNotNull);
        expect(members!.isNotEmpty, isTrue);
      },
    );
  });
}

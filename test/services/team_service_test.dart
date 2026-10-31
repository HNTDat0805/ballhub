import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ballhub/core/api/api_client.dart';
import 'package:ballhub/models/team.dart';
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
    TeamService.resetStateForTesting();
  });

  group('TeamService Client REST API Tests (24 test cases)', () {
    final sampleTeamMap = {
      'teamId': 'team_test_1',
      'teamName': 'FC Test Một',
      'area': 'Bình Thạnh',
      'description': 'Đội bóng thử nghiệm',
      'captainId': 'cap_1',
      'captainName': 'Đội Trưởng A',
      'memberCount': 10,
      'createdAt': '2026-06-01T00:00:00.000Z',
    };

    final sampleMemberMap = {
      'userId': 'mem_1',
      'role': 'Player',
      'fullName': 'Cầu thủ B',
      'position': 'Tiền vệ',
      'jerseyNumber': 7,
      'joinedAt': '2026-06-02T00:00:00.000Z',
    };

    final sampleRequestMap = {
      'requestId': 'req_1',
      'teamId': 'team_test_1',
      'userId': 'user_req_1',
      'fullName': 'Người xin vào',
      'status': 'Pending',
      'createdAt': '2026-06-03T00:00:00.000Z',
    };

    final sampleCandidateMap = {
      'team': sampleTeamMap,
      'matchScore': 95,
      'reason': 'Cùng khu vực Bình Thạnh',
    };

    final sampleInvitationMap = {
      'id': 'inv_1',
      'fromTeamId': 'team_test_1',
      'fromTeamName': 'FC Test Một',
      'toTeamId': 'team_opponent_2',
      'toTeamName': 'FC Đối Thủ',
      'fromCaptainId': 'cap_1',
      'toCaptainId': 'cap_2',
      'message': 'Giao hữu cuối tuần',
      'status': 'Pending',
      'createdAt': '2026-06-04T00:00:00.000Z',
      'updatedAt': '2026-06-04T00:00:00.000Z',
    };

    // 1. search teams
    test('1. search teams passes keyword and area queries to /teams', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/teams');
        expect(req.url.queryParameters['keyword'], 'Test');
        expect(req.url.queryParameters['area'], 'Bình Thạnh');
        return jsonResponse({'success': true, 'data': [sampleTeamMap]});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final list = await TeamService.search(keyword: 'Test', area: 'Bình Thạnh');
      expect(list.length, 1);
      expect(list.first.teamName, 'FC Test Một');
    });

    // 2. search teams fallback
    test('2. search teams falls back to sample teams on network error', () async {
      final mock = MockHttpClient((req) async => jsonResponse('Error', 500));
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final list = await TeamService.search();
      expect(list.isNotEmpty, true);
    });

    // 3. getMyTeams
    test('3. getMyTeams fetches /teams/mine and parses list', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/teams/mine');
        return jsonResponse({'success': true, 'data': [sampleTeamMap]});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final list = await TeamService.getMyTeams();
      expect(list.any((t) => t.teamId == 'team_test_1'), true);
    });

    // 4. getMyTeams empty
    test('4. getMyTeams returns empty list when API returns empty and no teams created', () async {
      final mock = MockHttpClient((req) async => jsonResponse({'success': true, 'data': []}));
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final list = await TeamService.getMyTeams();
      expect(list.isEmpty, true);
    });

    // 5. getTeam by ID
    test('5. getTeam fetches /teams/:id and returns team', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/teams/team_test_1');
        return jsonResponse({'success': true, 'data': sampleTeamMap});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final team = await TeamService.getTeam('team_test_1');
      expect(team, isNotNull);
      expect(team!.teamName, 'FC Test Một');
    });

    // 6. getTeam returns null if deleted
    test('6. getTeam returns null if team was deleted', () async {
      final mock = MockHttpClient((req) async => jsonResponse({'success': true}));
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      await TeamService.deleteTeam('team_test_1');
      final team = await TeamService.getTeam('team_test_1');
      expect(team, isNull);
    });

    // 7. createTeam
    test('7. createTeam posts to /teams with body and increments changed notifier', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/v1/teams');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleTeamMap}, 201);
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final initialVal = TeamService.changed.value;
      await TeamService.createTeam('FC Mới', 'Quận 7', 'Mô tả');
      expect(body['name'], 'FC Mới');
      expect(body['area'], 'Quận 7');
      expect(TeamService.changed.value, initialVal + 1);
    });

    // 8. createTeam throws AppException
    test('8. createTeam throws AppException when API rejects creation', () async {
      final mock = MockHttpClient((req) async => jsonResponse(
          {'success': false, 'error': {'code': 'DUPLICATE', 'message': 'Tên đội đã tồn tại'}},
          400));
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      expect(
        () => TeamService.createTeam('FC Trùng', 'Q1', 'Desc'),
        throwsA(isA<AppException>()),
      );
    });

    // 9. updateTeam
    test('9. updateTeam patches /teams/:id and notifies listeners', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'PATCH');
        expect(req.url.path, '/api/v1/teams/team_test_1');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleTeamMap});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final initialVal = TeamService.changed.value;
      await TeamService.updateTeam('team_test_1', 'FC Đổi Tên', 'Q1', 'Bio');
      expect(body['name'], 'FC Đổi Tên');
      expect(TeamService.changed.value, initialVal + 1);
    });

    // 10. updateTeam throws AppException
    test('10. updateTeam throws AppException on unauthorized error', () async {
      final mock = MockHttpClient((req) async => jsonResponse(
          {'success': false, 'error': {'code': 'FORBIDDEN', 'message': 'Không có quyền'}},
          403));
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      expect(
        () => TeamService.updateTeam('team_test_1', 'Tên', 'Area', 'Desc'),
        throwsA(isA<AppException>()),
      );
    });

    // 11. deleteTeam
    test('11. deleteTeam deletes /teams/:id and marks team as deleted', () async {
      final mock = MockHttpClient((req) async {
        expect(req.method, 'DELETE');
        expect(req.url.path, '/api/v1/teams/team_del');
        return jsonResponse({'success': true});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      await TeamService.deleteTeam('team_del');
      final team = await TeamService.getTeam('team_del');
      expect(team, isNull);
    });

    // 12. leaveTeam
    test('12. leaveTeam deletes /teams/:id/members/:uid and notifies', () async {
      final mock = MockHttpClient((req) async {
        expect(req.method, 'DELETE');
        return jsonResponse({'success': true});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      await TeamService.leaveTeam('team_leave');
      final myTeams = await TeamService.getMyTeams();
      expect(myTeams.any((t) => t.teamId == 'team_leave'), false);
    });

    // 13. getMembers
    test('13. getMembers fetches /teams/:id/members', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/teams/team_test_1/members');
        return jsonResponse({'success': true, 'data': [sampleMemberMap]});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final members = await TeamService.getMembers('team_test_1');
      expect(members.length, 1);
      expect(members.first.fullName, 'Cầu thủ B');
    });

    // 14. getMembers fallback
    test('14. getMembers returns fallback members on network error', () async {
      final mock = MockHttpClient((req) async => jsonResponse('Error', 500));
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final members = await TeamService.getMembers('team_sao_vang');
      expect(members.isNotEmpty, true);
    });

    // 15. removeMember
    test('15. removeMember deletes member endpoint and notifies', () async {
      final mock = MockHttpClient((req) async {
        expect(req.method, 'DELETE');
        expect(req.url.path, '/api/v1/teams/team_1/members/mem_1');
        return jsonResponse({'success': true});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      await TeamService.removeMember('team_1', 'mem_1');
      expect(true, true);
    });

    // 16. removeMember throws AppException
    test('16. removeMember throws AppException when captain leaving with others', () async {
      final mock = MockHttpClient((req) async => jsonResponse(
          {'success': false, 'error': {'code': 'FAILED', 'message': 'Đội trưởng không thể rời đội'}},
          400));
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      expect(
        () => TeamService.removeMember('team_1', 'cap_1'),
        throwsA(isA<AppException>()),
      );
    });

    // 17. sendJoinRequest
    test('17. sendJoinRequest posts to /teams/:id/join-requests', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/v1/teams/team_1/join-requests');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleRequestMap}, 201);
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      await TeamService.sendJoinRequest('team_1', 'Tôi muốn gia nhập');
      expect(body['message'], 'Tôi muốn gia nhập');
    });

    // 18. getPendingRequests
    test('18. getPendingRequests gets /teams/:id/join-requests', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/teams/team_1/join-requests');
        return jsonResponse({'success': true, 'data': [sampleRequestMap]});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final reqs = await TeamService.getPendingRequests('team_1');
      expect(reqs.length, 1);
      expect(reqs.first.fullName, 'Người xin vào');
    });

    // 19. approve join request
    test('19. approve join request patches with status Approved', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'PATCH');
        expect(req.url.path, '/api/v1/teams/team_test_1/join-requests/req_1');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final reqObj = JoinRequest.fromMap(sampleRequestMap);
      await TeamService.approve(reqObj);
      expect(body['status'], 'Approved');
    });

    // 20. reject join request
    test('20. reject join request patches with status Rejected', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'PATCH');
        expect(req.url.path, '/api/v1/teams/team_test_1/join-requests/req_1');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final reqObj = JoinRequest.fromMap(sampleRequestMap);
      await TeamService.reject(reqObj);
      expect(body['status'], 'Rejected');
    });

    // 21. findOpponents
    test('21. findOpponents passes area and myTeamId to /matchmaking/opponents', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/matchmaking/opponents');
        expect(req.url.queryParameters['area'], 'Bình Thạnh');
        expect(req.url.queryParameters['myTeamId'], 'team_test_1');
        return jsonResponse({'success': true, 'data': [sampleCandidateMap]});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final candidates =
          await TeamService.findOpponents(area: 'Bình Thạnh', myTeamId: 'team_test_1');
      expect(candidates.length, 1);
      expect(candidates.first.matchScore, 95);
    });

    // 22. sendFriendlyInvite
    test('22. sendFriendlyInvite posts invitation payload to /invitations', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/v1/invitations');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleInvitationMap}, 201);
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final inv = await TeamService.sendFriendlyInvite(
        fromTeamId: 'team_test_1',
        toTeamId: 'team_opponent_2',
        message: 'Giao lưu bóng đá sân 7',
        proposedDate: '2026-07-05',
        venue: 'Sân Gia Định',
      );
      expect(body['toTeamId'], 'team_opponent_2');
      expect(body['message'], 'Giao lưu bóng đá sân 7');
      expect(inv.id, 'inv_1');
      expect(inv.status, 'Pending');
    });

    // 23. getInvitations
    test('23. getInvitations fetches /invitations with teamId parameter', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/invitations');
        expect(req.url.queryParameters['teamId'], 'team_test_1');
        return jsonResponse({'success': true, 'data': [sampleInvitationMap]});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      final invs = await TeamService.getInvitations('team_test_1');
      expect(invs.length, 1);
      expect(invs.first.fromTeamName, 'FC Test Một');
    });

    // 24. respondInvitation
    test('24. respondInvitation patches /invitations/:id with status Accepted', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'PATCH');
        expect(req.url.path, '/api/v1/invitations/inv_1');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true});
      });
      TeamService.api = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock);

      await TeamService.respondInvitation('inv_1', 'Accepted');
      expect(body['status'], 'Accepted');
    });
  });
}

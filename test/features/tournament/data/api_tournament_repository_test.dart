import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ballhub/core/api/api_client.dart';
import 'package:ballhub/features/tournament/data/api_tournament_repository.dart';
import 'package:ballhub/features/tournament/domain/models/match.dart';
import 'package:ballhub/features/tournament/domain/models/tournament.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('ApiTournamentRepository Tests', () {
    test('refreshTournaments maps API array into Tournament domain list', () async {
      final mockClient = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/tournaments');
        return http.Response(jsonEncode({
          'success': true,
          'data': [
            {
              'id': 'tour_1',
              'name': 'Hanoi Cup 2026',
              'description': 'Giai dau Hanoi',
              'location': 'Hanoi',
              'startDate': '2026-06-01T08:00:00.000Z',
              'endDate': '2026-06-10T18:00:00.000Z',
              'registrationDeadline': '2026-05-30T23:59:59.000Z',
              'maxTeams': 8,
              'format': 'roundRobinSingle',
              'status': 'registrationOpen',
              'organizerId': 'user_org',
              'organizerName': 'BTC',
              'createdAt': '2026-05-01T00:00:00.000Z',
              'updatedAt': '2026-05-01T00:00:00.000Z',
            }
          ]
        }), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final list = await repo.refreshTournaments();
      expect(list.length, 1);
      expect(list.first.id, 'tour_1');
      expect(list.first.name, 'Hanoi Cup 2026');
      expect(list.first.format, TournamentFormat.roundRobinSingle);
      expect(list.first.status, TournamentStatus.registrationOpen);
    });

    test('createTournament posts payload to /tournaments', () async {
      late Map<String, dynamic> sentBody;
      final mockClient = MockHttpClient((req) async {
        if (req.method == 'POST') {
          final bodyStr = (req as http.Request).body;
          sentBody = jsonDecode(bodyStr);
          return http.Response(jsonEncode({'success': true, 'data': {'id': 'tour_new'}}), 201);
        }
        // subsequent refresh
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final tournament = Tournament(
        id: 'temp_id',
        name: 'Saigon Cup',
        description: 'Mo ta',
        location: 'HCM',
        startDate: DateTime.parse('2026-07-01'),
        endDate: DateTime.parse('2026-07-10'),
        registrationDeadline: DateTime.parse('2026-06-25'),
        maxTeams: 16,
        format: TournamentFormat.knockout,
        status: TournamentStatus.preparing,
        organizerId: 'org_1',
        organizerName: 'BTC',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createTournament(tournament);

      expect(sentBody['name'], 'Saigon Cup');
      expect(sentBody['maxTeams'], 16);
      expect(sentBody['format'], 'knockout');
    });

    test('generateSchedule posts to /tournaments/:id/schedule and triggers schedule update', () async {
      bool scheduleCalled = false;
      final mockClient = MockHttpClient((req) async {
        if (req.url.path == '/api/v1/tournaments/tour_1/schedule') {
          scheduleCalled = true;
          return http.Response(jsonEncode({'success': true, 'data': []}), 201);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      await repo.generateSchedule('tour_1', venue: 'San 1');
      expect(scheduleCalled, true);
    });

    test('updateMatchResult puts score to /matches/:matchId/result', () async {
      late Map<String, dynamic> resultBody;
      final mockClient = MockHttpClient((req) async {
        if (req.url.path == '/api/v1/matches/m_1/result') {
          final bodyStr = (req as http.Request).body;
          resultBody = jsonDecode(bodyStr);
          return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      await repo.updateMatchResult(
        tournamentId: 'tour_1',
        matchId: 'm_1',
        homeScore: 2,
        awayScore: 0,
        status: MatchStatus.finished,
        isConfirmed: true,
        updatedBy: 'Admin',
        reason: 'Hop le',
      );

      expect(resultBody['homeScore'], 2);
      expect(resultBody['awayScore'], 0);
      expect(resultBody['isConfirmed'], true);
    });
  });
}

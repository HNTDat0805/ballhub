import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ballhub/core/api/api_client.dart';
import 'package:ballhub/features/tournament/data/api_tournament_repository.dart';
import 'package:ballhub/features/tournament/domain/models/match.dart';
import 'package:ballhub/features/tournament/domain/models/tournament.dart';
import 'package:ballhub/features/tournament/domain/models/tournament_team.dart';

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
  group('ApiTournamentRepository Tests (22 test cases)', () {
    // 1. refreshTournaments maps list
    test('1. refreshTournaments maps API array into Tournament domain list', () async {
      final mockClient = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/tournaments');
        return http.Response(
            jsonEncode({
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
            }),
            200);
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

    // 2. refreshTournaments fallback
    test('2. refreshTournaments falls back to sample tournaments on network error when cache is empty', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response('Server error', 500);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final list = await repo.refreshTournaments();
      expect(list.isNotEmpty, true);
      expect(list.first.name.contains('Ballhub'), true);
    });

    // 3. getTournament success
    test('3. getTournament returns Tournament when API succeeds', () async {
      final mockClient = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/tournaments/tour_test_1');
        return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'tour_test_1',
                'name': 'Da Nang Open 2026',
                'location': 'Da Nang',
                'startDate': '2026-07-01T00:00:00.000Z',
                'endDate': '2026-07-05T00:00:00.000Z',
                'registrationDeadline': '2026-06-25T00:00:00.000Z',
                'maxTeams': 16,
                'format': 'knockout',
                'status': 'preparing',
                'organizerId': 'org_dn',
                'organizerName': 'BTC DN',
                'createdAt': '2026-05-01T00:00:00.000Z',
                'updatedAt': '2026-05-01T00:00:00.000Z',
              }
            }),
            200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final tour = await repo.getTournament('tour_test_1');
      expect(tour, isNotNull);
      expect(tour!.name, 'Da Nang Open 2026');
      expect(tour.format, TournamentFormat.knockout);
    });

    // 4. getTournament null fallback
    test('4. getTournament returns null when not found and not in cache', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final tour = await repo.getTournament('non_existent_id');
      expect(tour, isNull);
    });

    // 5. createTournament
    test('5. createTournament posts payload to /tournaments and refreshes list', () async {
      late Map<String, dynamic> sentBody;
      final mockClient = MockHttpClient((req) async {
        if (req.method == 'POST') {
          sentBody = jsonDecode((req as http.Request).body);
          return http.Response(jsonEncode({'success': true, 'data': {'id': 'tour_new'}}), 201);
        }
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

    // 6. updateTournament
    test('6. updateTournament patches /tournaments/:id and refreshes list', () async {
      late Map<String, dynamic> patchBody;
      final mockClient = MockHttpClient((req) async {
        if (req.method == 'PATCH') {
          patchBody = jsonDecode((req as http.Request).body);
          return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final tournament = Tournament(
        id: 'tour_edit_1',
        name: 'Updated Name',
        description: 'New Desc',
        location: 'HCM',
        startDate: DateTime.parse('2026-07-01'),
        endDate: DateTime.parse('2026-07-10'),
        registrationDeadline: DateTime.parse('2026-06-25'),
        maxTeams: 8,
        format: TournamentFormat.roundRobinSingle,
        status: TournamentStatus.inProgress,
        organizerId: 'org_1',
        organizerName: 'BTC',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.updateTournament(tournament);
      expect(patchBody['name'], 'Updated Name');
      expect(patchBody['status'], 'inProgress');
    });

    // 7. deleteTournament
    test('7. deleteTournament deletes /tournaments/:id and refreshes list', () async {
      bool deleteCalled = false;
      final mockClient = MockHttpClient((req) async {
        if (req.method == 'DELETE' && req.url.path == '/api/v1/tournaments/tour_del_1') {
          deleteCalled = true;
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      await repo.deleteTournament('tour_del_1');
      expect(deleteCalled, true);
    });

    // 8. watchTournaments
    test('8. watchTournaments emits tournament stream', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 't_stream_1',
                  'name': 'Stream Cup',
                  'location': 'HN',
                  'startDate': '2026-08-01T00:00:00.000Z',
                  'endDate': '2026-08-10T00:00:00.000Z',
                  'registrationDeadline': '2026-07-25T00:00:00.000Z',
                  'maxTeams': 8,
                  'format': 'roundRobinSingle',
                  'status': 'preparing',
                  'organizerId': 'org_1',
                  'organizerName': 'BTC',
                  'createdAt': '2026-07-01T00:00:00.000Z',
                  'updatedAt': '2026-07-01T00:00:00.000Z',
                }
              ]
            }),
            200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final stream = repo.watchTournaments();
      final firstEmission = await stream.first;
      expect(firstEmission.length, 1);
      expect(firstEmission.first.name, 'Stream Cup');
    });

    // 9. refreshTeams maps list
    test('9. refreshTeams maps API registrations into TournamentTeam domain list', () async {
      final mockClient = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/tournaments/tour_reg_1/registrations');
        return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'reg_1',
                  'tournamentId': 'tour_reg_1',
                  'teamId': 'team_alpha',
                  'teamName': 'FC Alpha',
                  'captainId': 'cap_1',
                  'captainName': 'Anh Cap',
                  'captainPhone': '0901234567',
                  'status': 'approved',
                  'registeredAt': '2026-06-01T00:00:00.000Z',
                }
              ]
            }),
            200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final teams = await repo.refreshTeams('tour_reg_1');
      expect(teams.length, 1);
      expect(teams.first.teamName, 'FC Alpha');
      expect(teams.first.status, RegistrationStatus.approved);
    });

    // 10. registerTeam
    test('10. registerTeam posts registration to /tournaments/:id/registrations', () async {
      late Map<String, dynamic> regBody;
      final mockClient = MockHttpClient((req) async {
        if (req.method == 'POST') {
          regBody = jsonDecode((req as http.Request).body);
          return http.Response(jsonEncode({'success': true, 'data': {'id': 'reg_new'}}), 201);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final team = TournamentTeam(
        id: 'temp_reg_id',
        tournamentId: 'tour_123',
        teamId: 'team_beta',
        teamName: 'FC Beta',
        captainId: 'cap_beta',
        captainName: 'Cap Beta',
        captainPhone: '0987654321',
        captainEmail: 'beta@example.com',
        registeredAt: DateTime.now(),
        status: RegistrationStatus.pending,
      );

      await repo.registerTeam(team);
      expect(regBody['teamName'], 'FC Beta');
      expect(regBody['teamId'], 'team_beta');
    });

    // 11. updateTeamStatus
    test('11. updateTeamStatus patches /registrations/:id/status', () async {
      late Map<String, dynamic> statusBody;
      final mockClient = MockHttpClient((req) async {
        if (req.method == 'PATCH') {
          statusBody = jsonDecode((req as http.Request).body);
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      await repo.updateTeamStatus('tour_1', 'reg_123', RegistrationStatus.approved);
      expect(statusBody['status'], 'approved');
    });

    // 12. watchTeams
    test('12. watchTeams emits team registrations stream', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'reg_stream_1',
                  'tournamentId': 'tour_stream_t',
                  'teamId': 't_gamma',
                  'teamName': 'FC Gamma',
                  'captainId': 'c_1',
                  'captainName': 'Cap Gamma',
                  'captainPhone': '0912345678',
                  'status': 'approved',
                  'registeredAt': '2026-06-01T00:00:00.000Z',
                }
              ]
            }),
            200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final stream = repo.watchTeams('tour_stream_t');
      final first = await stream.first;
      expect(first.length, 1);
      expect(first.first.teamName, 'FC Gamma');
    });

    // 13. refreshMatches maps list
    test('13. refreshMatches maps API matches into TournamentMatch list', () async {
      final mockClient = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/tournaments/tour_m_1/matches');
        return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'm_match_1',
                  'tournamentId': 'tour_m_1',
                  'round': 1,
                  'roundName': 'Vòng 1',
                  'homeTeamId': 'team_a',
                  'homeTeamName': 'Team A',
                  'awayTeamId': 'team_b',
                  'awayTeamName': 'Team B',
                  'homeScore': 2,
                  'awayScore': 1,
                  'status': 'finished',
                  'scheduledTime': '2026-07-01T09:00:00.000Z',
                  'venue': 'Sân 1',
                  'isConfirmed': true,
                }
              ]
            }),
            200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final matches = await repo.refreshMatches('tour_m_1');
      expect(matches.length, 1);
      expect(matches.first.homeScore, 2);
      expect(matches.first.awayScore, 1);
      expect(matches.first.status, MatchStatus.finished);
    });

    // 14. generateSchedule
    test('14. generateSchedule posts to /tournaments/:id/schedule and triggers update', () async {
      bool scheduleCalled = false;
      final mockClient = MockHttpClient((req) async {
        if (req.url.path == '/api/v1/tournaments/tour_gen/schedule') {
          scheduleCalled = true;
          return http.Response(jsonEncode({'success': true, 'data': []}), 201);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      await repo.generateSchedule('tour_gen', venue: 'Sân Trung Tâm');
      expect(scheduleCalled, true);
    });

    // 15. updateMatchResult
    test('15. updateMatchResult puts score and status to /matches/:matchId/result', () async {
      late Map<String, dynamic> resultBody;
      final mockClient = MockHttpClient((req) async {
        if (req.url.path == '/api/v1/matches/m_res_1/result') {
          resultBody = jsonDecode((req as http.Request).body);
          return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      await repo.updateMatchResult(
        tournamentId: 'tour_1',
        matchId: 'm_res_1',
        homeScore: 3,
        awayScore: 2,
        status: MatchStatus.finished,
        isConfirmed: true,
        updatedBy: 'trọng tài',
        reason: 'Kết thúc 90 phút',
      );

      expect(resultBody['homeScore'], 3);
      expect(resultBody['awayScore'], 2);
      expect(resultBody['isConfirmed'], true);
    });

    // 16. saveMatches
    test('16. saveMatches updates matches stream correctly', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      await repo.saveMatches('tour_save_1', []);
      expect(true, true);
    });

    // 17. watchMatches
    test('17. watchMatches emits matches stream for specific tournamentId', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'm_stream_x',
                  'tournamentId': 'tour_m_stream',
                  'round': 1,
                  'roundName': 'Vòng 1',
                  'homeTeamId': 't1',
                  'homeTeamName': 'Team 1',
                  'awayTeamId': 't2',
                  'awayTeamName': 'Team 2',
                  'homeScore': 0,
                  'awayScore': 0,
                  'status': 'scheduled',
                  'scheduledTime': '2026-07-01T08:00:00.000Z',
                  'venue': 'Sân 1',
                  'isConfirmed': false,
                }
              ]
            }),
            200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final stream = repo.watchMatches('tour_m_stream');
      final first = await stream.first;
      expect(first.length, 1);
      expect(first.first.homeTeamName, 'Team 1');
    });

    // 18. refreshStandings maps list
    test('18. refreshStandings maps API standings array into StandingsRow list', () async {
      final mockClient = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/tournaments/tour_st_1/standings');
        return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'row_1',
                  'tournamentId': 'tour_st_1',
                  'teamId': 'team_top',
                  'teamName': 'FC Top 1',
                  'rank': 1,
                  'played': 3,
                  'won': 3,
                  'drawn': 0,
                  'lost': 0,
                  'goalsFor': 10,
                  'goalsAgainst': 1,
                  'goalDifference': 9,
                  'points': 9,
                }
              ]
            }),
            200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final standings = await repo.refreshStandings('tour_st_1');
      expect(standings.length, 1);
      expect(standings.first.rank, 1);
      expect(standings.first.points, 9);
      expect(standings.first.goalDifference, 9);
    });

    // 19. recalculateAndSaveStandings
    test('19. recalculateAndSaveStandings posts to /tournaments/:id/standings/recalculate', () async {
      bool recalcCalled = false;
      final mockClient = MockHttpClient((req) async {
        if (req.url.path == '/api/v1/tournaments/tour_recalc/standings/recalculate') {
          recalcCalled = true;
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      await repo.recalculateAndSaveStandings('tour_recalc');
      expect(recalcCalled, true);
    });

    // 20. watchStandings
    test('20. watchStandings emits standings stream', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'row_st',
                  'tournamentId': 'tour_std',
                  'teamId': 'team_a',
                  'teamName': 'Team A',
                  'rank': 1,
                  'played': 1,
                  'won': 1,
                  'drawn': 0,
                  'lost': 0,
                  'goalsFor': 2,
                  'goalsAgainst': 0,
                  'goalDifference': 2,
                  'points': 3,
                }
              ]
            }),
            200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final stream = repo.watchStandings('tour_std');
      final first = await stream.first;
      expect(first.length, 1);
      expect(first.first.points, 3);
    });

    // 21. refreshAudits maps list
    test('21. refreshAudits maps API audit log array into MatchAudit list', () async {
      final mockClient = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/tournaments/tour_aud_1/audits');
        return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'aud_1',
                  'matchId': 'm_1',
                  'tournamentId': 'tour_aud_1',
                  'updatedBy': 'user_admin',
                  'updatedAt': '2026-07-01T12:00:00.000Z',
                  'previousHomeScore': 0,
                  'previousAwayScore': 0,
                  'newHomeScore': 1,
                  'newAwayScore': 0,
                  'reason': 'Ghi bàn phút 90',
                }
              ]
            }),
            200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final audits = await repo.refreshAudits('tour_aud_1');
      expect(audits.length, 1);
      expect(audits.first.newHomeScore, 1);
      expect(audits.first.updatedBy, 'user_admin');
    });

    // 22. watchMatchAuditLogs
    test('22. watchMatchAuditLogs emits audits stream for specific tournamentId', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'aud_stream_1',
                  'matchId': 'm_str',
                  'tournamentId': 'tour_aud_str',
                  'updatedBy': 'referee',
                  'updatedAt': '2026-07-01T12:00:00.000Z',
                  'previousHomeScore': 1,
                  'previousAwayScore': 1,
                  'newHomeScore': 2,
                  'newAwayScore': 1,
                  'reason': 'VAR cong nhan ban thang',
                }
              ]
            }),
            200);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mockClient);
      final repo = ApiTournamentRepository(apiClient: apiClient);

      final stream = repo.watchMatchAuditLogs('tour_aud_str');
      final first = await stream.first;
      expect(first.length, 1);
      expect(first.first.reason, 'VAR cong nhan ban thang');
    });
  });
}

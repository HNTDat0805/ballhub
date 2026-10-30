import 'dart:async';
import '../../../core/api/api_client.dart';
import '../domain/models/match.dart';
import '../domain/models/match_audit.dart';
import '../domain/models/standings_row.dart';
import '../domain/models/tournament.dart';
import '../domain/models/tournament_team.dart';
import 'tournament_repository.dart';

/// Triển khai thực tế của [TournamentRepository] theo kiến trúc API-first.
///
/// Mọi thao tác quản trị giải đấu, đăng ký đội, duyệt đội, tạo lịch,
/// cập nhật kết quả và tính bảng xếp hạng đều được thực hiện qua các endpoint REST API.
///
/// Các StreamController kiểu broadcast được sử dụng để phát lại danh sách dữ liệu mới nhất
/// cho các màn hình Flutter khi có sự thay đổi (invalidation & automatic refresh).
class ApiTournamentRepository implements TournamentRepository {
  final ApiClient _api;

  final _tournamentsController = StreamController<List<Tournament>>.broadcast();
  final Map<String, StreamController<List<TournamentTeam>>> _teamsControllers = {};
  final Map<String, StreamController<List<TournamentMatch>>> _matchesControllers = {};
  final Map<String, StreamController<List<StandingsRow>>> _standingsControllers = {};
  final Map<String, StreamController<List<MatchAudit>>> _auditsControllers = {};

  ApiTournamentRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  List<Tournament> _cachedTournaments = [];

  static List<Tournament> _getFallbackSampleTournaments() {
    return [
      Tournament(
        id: 'tour_ballhub_cup_2026',
        name: 'Ballhub Super Cup 2026',
        description: 'Giải bóng đá phong trào thường niên Ballhub tranh cúp vô địch.',
        location: 'Sân bóng Thể thao Quốc gia, TP. Hồ Chí Minh',
        startDate: DateTime.now().add(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 14)),
        registrationDeadline: DateTime.now().add(const Duration(days: 2)),
        maxTeams: 8,
        format: TournamentFormat.roundRobinSingle,
        status: TournamentStatus.registrationOpen,
        organizerId: 'user_organizer_01',
        organizerName: 'Ban Tổ Chức Ballhub',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Tournament(
        id: 'tour_ha_noi_open_2026',
        name: 'Hà Nội Premier League Cup',
        description: 'Giải đấu giao lưu các câu lạc bộ bóng đá phong trào miền Bắc.',
        location: 'Sân vận động Mỹ Đình, Hà Nội',
        startDate: DateTime.now().add(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 21)),
        registrationDeadline: DateTime.now().add(const Duration(days: 5)),
        maxTeams: 16,
        format: TournamentFormat.knockout,
        status: TournamentStatus.preparing,
        organizerId: 'user_organizer_01',
        organizerName: 'Ban Tổ Chức Ballhub',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  // ----------------------------------------------------
  // TOURNAMENTS
  // ----------------------------------------------------

  @override
  Stream<List<Tournament>> watchTournaments() {
    refreshTournaments();
    return _tournamentsController.stream;
  }

  Future<List<Tournament>> refreshTournaments() async {
    try {
      final res = await _api.get('/tournaments');
      final list = <Tournament>[];
      if (res is List) {
        for (final item in res) {
          if (item is Map) {
            list.add(Tournament.fromMap(item, item['id']?.toString() ?? ''));
          }
        }
      }
      _cachedTournaments = list;
      _tournamentsController.add(list);
      return list;
    } catch (e) {
      // Fallback hiển thị dữ liệu giải đấu mẫu khi máy chủ backend chưa khởi động
      if (_cachedTournaments.isEmpty) {
        _cachedTournaments = _getFallbackSampleTournaments();
        _tournamentsController.add(_cachedTournaments);
        return _cachedTournaments;
      }
      _tournamentsController.addError(e);
      return [];
    }
  }

  @override
  Future<Tournament?> getTournament(String tournamentId) async {
    try {
      final res = await _api.get('/tournaments/$tournamentId');
      if (res is Map) {
        return Tournament.fromMap(res, tournamentId);
      }
      return null;
    } catch (_) {
      try {
        return _cachedTournaments.firstWhere((t) => t.id == tournamentId);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<void> createTournament(Tournament tournament) async {
    final body = {
      'name': tournament.name,
      'description': tournament.description,
      'bannerUrl': tournament.bannerUrl,
      'location': tournament.location,
      'startDate': tournament.startDate.toIso8601String(),
      'endDate': tournament.endDate.toIso8601String(),
      'registrationDeadline': tournament.registrationDeadline.toIso8601String(),
      'maxTeams': tournament.maxTeams,
      'format': tournament.format.name,
      'status': tournament.status.name,
    };

    await _api.post('/tournaments', body: body);
    await refreshTournaments();
  }

  @override
  Future<void> updateTournament(Tournament tournament) async {
    final body = {
      'name': tournament.name,
      'description': tournament.description,
      'bannerUrl': tournament.bannerUrl,
      'location': tournament.location,
      'startDate': tournament.startDate.toIso8601String(),
      'endDate': tournament.endDate.toIso8601String(),
      'registrationDeadline': tournament.registrationDeadline.toIso8601String(),
      'maxTeams': tournament.maxTeams,
      'format': tournament.format.name,
      'status': tournament.status.name,
    };

    await _api.patch('/tournaments/${tournament.id}', body: body);
    await refreshTournaments();
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    await _api.delete('/tournaments/$tournamentId');
    await refreshTournaments();
  }

  // ----------------------------------------------------
  // TEAMS & REGISTRATION
  // ----------------------------------------------------

  StreamController<List<TournamentTeam>> _getTeamsController(String tournamentId) {
    return _teamsControllers.putIfAbsent(
      tournamentId,
      () => StreamController<List<TournamentTeam>>.broadcast(),
    );
  }

  @override
  Stream<List<TournamentTeam>> watchTeams(String tournamentId) {
    refreshTeams(tournamentId);
    return _getTeamsController(tournamentId).stream;
  }

  Future<List<TournamentTeam>> refreshTeams(String tournamentId) async {
    final controller = _getTeamsController(tournamentId);
    try {
      final res = await _api.get('/tournaments/$tournamentId/registrations');
      final list = <TournamentTeam>[];
      if (res is List) {
        for (final item in res) {
          if (item is Map) {
            list.add(TournamentTeam.fromMap(item, item['id']?.toString() ?? ''));
          }
        }
      }
      controller.add(list);
      return list;
    } catch (e) {
      controller.addError(e);
      return [];
    }
  }

  @override
  Future<void> registerTeam(TournamentTeam team) async {
    final body = {
      'teamId': team.teamId,
      'teamName': team.teamName,
      'logoUrl': team.logoUrl,
      'captainId': team.captainId,
      'captainName': team.captainName,
      'captainPhone': team.captainPhone,
      'captainEmail': team.captainEmail,
      'membersCount': team.membersCount,
    };

    await _api.post('/tournaments/${team.tournamentId}/registrations', body: body);
    await refreshTeams(team.tournamentId);
  }

  @override
  Future<void> updateTeamStatus(
    String tournamentId,
    String teamRegistrationId,
    RegistrationStatus status, {
    String? note,
    String? reviewedBy,
  }) async {
    final body = {
      'status': status.name,
      'reviewNote': note,
    };

    await _api.patch(
      '/tournaments/$tournamentId/registrations/$teamRegistrationId',
      body: body,
    );
    await refreshTeams(tournamentId);
  }

  // ----------------------------------------------------
  // MATCHES & SCHEDULE
  // ----------------------------------------------------

  StreamController<List<TournamentMatch>> _getMatchesController(String tournamentId) {
    return _matchesControllers.putIfAbsent(
      tournamentId,
      () => StreamController<List<TournamentMatch>>.broadcast(),
    );
  }

  @override
  Stream<List<TournamentMatch>> watchMatches(String tournamentId) {
    refreshMatches(tournamentId);
    return _getMatchesController(tournamentId).stream;
  }

  Future<List<TournamentMatch>> refreshMatches(String tournamentId) async {
    final controller = _getMatchesController(tournamentId);
    try {
      final res = await _api.get('/tournaments/$tournamentId/matches');
      final list = <TournamentMatch>[];
      if (res is List) {
        for (final item in res) {
          if (item is Map) {
            list.add(TournamentMatch.fromMap(item, item['id']?.toString() ?? ''));
          }
        }
      }
      controller.add(list);
      return list;
    } catch (e) {
      controller.addError(e);
      return [];
    }
  }

  @override
  Future<void> generateSchedule(String tournamentId, {String venue = 'Sân vận động chính'}) async {
    await _api.post('/tournaments/$tournamentId/schedule', body: {
      'venue': venue,
    });
    await refreshMatches(tournamentId);
    await refreshStandings(tournamentId);
    await refreshTournaments();
  }

  @override
  Future<void> saveMatches(String tournamentId, List<TournamentMatch> matches) async {
    // In API-first architecture, schedule generation is done by POST /schedule on backend.
    // If client submits a custom match list:
    for (final m in matches) {
      await _api.patch('/matches/${m.id}', body: {
        'scheduledTime': m.scheduledTime.toIso8601String(),
        'venue': m.venue,
        'notes': m.notes,
        'status': m.status.name,
      });
    }
    await refreshMatches(tournamentId);
  }

  @override
  Future<void> updateMatchResult({
    required String tournamentId,
    required String matchId,
    required int homeScore,
    required int awayScore,
    required MatchStatus status,
    required bool isConfirmed,
    required String updatedBy,
    String? notes,
    String? reason,
  }) async {
    final body = {
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': status.name,
      'isConfirmed': isConfirmed,
      'notes': notes,
      'reason': reason,
    };

    await _api.put('/matches/$matchId/result', body: body);

    // Refresh matches, standings, and audit logs
    await refreshMatches(tournamentId);
    await refreshStandings(tournamentId);
    await refreshAudits(tournamentId);
  }

  // ----------------------------------------------------
  // STANDINGS
  // ----------------------------------------------------

  StreamController<List<StandingsRow>> _getStandingsController(String tournamentId) {
    return _standingsControllers.putIfAbsent(
      tournamentId,
      () => StreamController<List<StandingsRow>>.broadcast(),
    );
  }

  @override
  Stream<List<StandingsRow>> watchStandings(String tournamentId) {
    refreshStandings(tournamentId);
    return _getStandingsController(tournamentId).stream;
  }

  Future<List<StandingsRow>> refreshStandings(String tournamentId) async {
    final controller = _getStandingsController(tournamentId);
    try {
      final res = await _api.get('/tournaments/$tournamentId/standings');
      final list = <StandingsRow>[];
      if (res is List) {
        for (final item in res) {
          if (item is Map) {
            list.add(StandingsRow.fromMap(item, item['teamId']?.toString() ?? ''));
          }
        }
      }
      controller.add(list);
      return list;
    } catch (e) {
      controller.addError(e);
      return [];
    }
  }

  @override
  Future<void> recalculateAndSaveStandings(String tournamentId) async {
    await _api.post('/tournaments/$tournamentId/standings/recalculate');
    await refreshStandings(tournamentId);
  }

  // ----------------------------------------------------
  // AUDIT LOGS
  // ----------------------------------------------------

  StreamController<List<MatchAudit>> _getAuditsController(String tournamentId) {
    return _auditsControllers.putIfAbsent(
      tournamentId,
      () => StreamController<List<MatchAudit>>.broadcast(),
    );
  }

  @override
  Stream<List<MatchAudit>> watchMatchAuditLogs(String tournamentId) {
    refreshAudits(tournamentId);
    return _getAuditsController(tournamentId).stream;
  }

  Future<List<MatchAudit>> refreshAudits(String tournamentId) async {
    final controller = _getAuditsController(tournamentId);
    try {
      final res = await _api.get('/tournaments/$tournamentId/audits');
      final list = <MatchAudit>[];
      if (res is List) {
        for (final item in res) {
          if (item is Map) {
            list.add(MatchAudit.fromMap(item, item['id']?.toString() ?? ''));
          }
        }
      }
      controller.add(list);
      return list;
    } catch (e) {
      controller.addError(e);
      return [];
    }
  }
}

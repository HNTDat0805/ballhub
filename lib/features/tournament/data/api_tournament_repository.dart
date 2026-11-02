import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../domain/models/match.dart';
import '../domain/models/match_audit.dart';
import '../domain/models/standings_row.dart';
import '../domain/models/tournament.dart';
import '../domain/models/tournament_team.dart';
import '../domain/services/schedule_generator.dart';
import '../domain/services/standings_calculator.dart';
import 'tournament_repository.dart';
import 'seeds/tournament_seed_data.dart';

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
  final Map<String, StreamController<List<TournamentTeam>>> _teamsControllers =
      {};
  final Map<String, StreamController<List<TournamentMatch>>>
  _matchesControllers = {};
  final Map<String, StreamController<List<StandingsRow>>>
  _standingsControllers = {};
  final Map<String, StreamController<List<MatchAudit>>> _auditsControllers = {};

  List<Tournament> _cachedTournaments = [];

  /// ID của giải đấu demo duy nhất có sẵn dữ liệu mẫu dự phòng khi chưa có mạng.
  /// Tuyệt đối KHÔNG gán dữ liệu mẫu cho bất kỳ giải đấu nào do người dùng tạo.
  static const String sampleDemoTournamentId =
      TournamentSeedData.sampleDemoTournamentId;

  // Lưu trữ cục bộ cho các giải đấu, đội đăng ký, trận đấu do người dùng tự tạo / thao tác
  static final Map<String, List<TournamentTeam>> _userRegisteredTeams = {};
  static final Map<String, List<TournamentMatch>> _userGeneratedMatches = {};
  static final Map<String, List<StandingsRow>> _userStandings = {};

  ApiTournamentRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient() {
    _cachedTournaments = TournamentSeedData.getSampleTournaments();
  }

  @visibleForTesting
  static void resetCacheForTesting() {
    _userRegisteredTeams.clear();
    _userGeneratedMatches.clear();
    _userStandings.clear();
  }

  // ----------------------------------------------------
  // TOURNAMENTS
  // ----------------------------------------------------

  @override
  Stream<List<Tournament>> watchTournaments() {
    scheduleMicrotask(() => refreshTournaments());
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
    } catch (_) {
      if (_cachedTournaments.isEmpty) {
        _cachedTournaments = TournamentSeedData.getSampleTournaments();
      }
      _tournamentsController.add(_cachedTournaments);
      return _cachedTournaments;
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

    try {
      final res = await _api.post('/tournaments', body: body);
      final id = (res is Map && res['id'] != null)
          ? res['id'].toString()
          : tournament.id;
      final created = tournament.copyWith(id: id);
      if (_cachedTournaments.isEmpty) {
        _cachedTournaments = TournamentSeedData.getSampleTournaments();
      }
      _cachedTournaments = [
        created,
        ..._cachedTournaments.where((t) => t.id != id),
      ];
      _tournamentsController.add(_cachedTournaments);
    } catch (e) {
      if (e is ApiException &&
          (e.code == 'NETWORK_ERROR' ||
              e.code == 'TIMEOUT' ||
              e.statusCode == 503)) {
        if (_cachedTournaments.isEmpty) {
          _cachedTournaments = TournamentSeedData.getSampleTournaments();
        }
        _cachedTournaments = [
          tournament,
          ..._cachedTournaments.where((t) => t.id != tournament.id),
        ];
        _tournamentsController.add(_cachedTournaments);
        return;
      }
      rethrow;
    }
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

    try {
      await _api.patch('/tournaments/${tournament.id}', body: body);
      _cachedTournaments = _cachedTournaments
          .map((t) => t.id == tournament.id ? tournament : t)
          .toList();
      _tournamentsController.add(_cachedTournaments);
    } catch (e) {
      if (e is ApiException &&
          (e.code == 'NETWORK_ERROR' ||
              e.code == 'TIMEOUT' ||
              e.statusCode == 503)) {
        _cachedTournaments = _cachedTournaments
            .map((t) => t.id == tournament.id ? tournament : t)
            .toList();
        _tournamentsController.add(_cachedTournaments);
        return;
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    _userRegisteredTeams.remove(tournamentId);
    _userGeneratedMatches.remove(tournamentId);
    _userStandings.remove(tournamentId);
    try {
      await _api.delete('/tournaments/$tournamentId');
      _cachedTournaments = _cachedTournaments
          .where((t) => t.id != tournamentId)
          .toList();
      _tournamentsController.add(_cachedTournaments);
    } catch (e) {
      if (e is ApiException &&
          (e.code == 'NETWORK_ERROR' ||
              e.code == 'TIMEOUT' ||
              e.statusCode == 503)) {
        _cachedTournaments = _cachedTournaments
            .where((t) => t.id != tournamentId)
            .toList();
        _tournamentsController.add(_cachedTournaments);
        return;
      }
      rethrow;
    }
  }

  // ----------------------------------------------------
  // TEAMS & REGISTRATION
  // ----------------------------------------------------

  /// Quản lý luồng phát sóng (Broadcast Stream) danh sách đội bóng cho từng giải đấu
  StreamController<List<TournamentTeam>> _getTeamsController(
    String tournamentId,
  ) {
    return _teamsControllers.putIfAbsent(
      tournamentId,
      () => StreamController<List<TournamentTeam>>.broadcast(),
    );
  }

  /// Lắng nghe luồng dữ liệu đội bóng theo thời gian thực cho giải đấu [tournamentId]
  @override
  Stream<List<TournamentTeam>> watchTeams(String tournamentId) {
    refreshTeams(tournamentId);
    return _getTeamsController(tournamentId).stream;
  }

  /// Tải mới danh sách đội bóng từ Backend REST API và cập nhật luồng phát sóng
  Future<List<TournamentTeam>> refreshTeams(String tournamentId) async {
    final controller = _getTeamsController(tournamentId);
    try {
      final res = await _api.get('/tournaments/$tournamentId/registrations');
      final list = <TournamentTeam>[];
      if (res is List) {
        for (final item in res) {
          if (item is Map) {
            list.add(
              TournamentTeam.fromMap(item, item['id']?.toString() ?? ''),
            );
          }
        }
      }
      final local = _userRegisteredTeams[tournamentId] ?? [];
      final combined = [
        ...local,
        ...list.where((t) => !local.any((l) => l.teamId == t.teamId)),
      ];
      controller.add(combined);
      return combined;
    } catch (_) {
      // Chỉ gán dữ liệu mẫu khi là giải đấu demo hệ thống ('tour_ballhub_cup_2026')
      // Tuyệt đối không để dữ liệu mẫu rò rỉ vào giải đấu do người dùng tự tạo
      if (tournamentId == sampleDemoTournamentId &&
          (!_userRegisteredTeams.containsKey(tournamentId) ||
              _userRegisteredTeams[tournamentId]!.isEmpty)) {
        final fallback = TournamentSeedData.getSampleTeams(tournamentId);
        controller.add(fallback);
        return fallback;
      }
      final local = _userRegisteredTeams[tournamentId] ?? [];
      controller.add(local);
      return local;
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

    final list = _userRegisteredTeams.putIfAbsent(team.tournamentId, () => []);
    if (!list.any((t) => t.teamId == team.teamId)) {
      list.add(team);
    }

    try {
      await _api.post(
        '/tournaments/${team.tournamentId}/registrations',
        body: body,
      );
    } catch (e) {
      if (e is! ApiException ||
          (e.code != 'NETWORK_ERROR' &&
              e.code != 'TIMEOUT' &&
              e.statusCode != 503)) {
        list.removeWhere((t) => t.id == team.id);
        rethrow;
      }
    }
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
    final body = {'status': status.name, 'reviewNote': note};

    final list = _userRegisteredTeams[tournamentId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == teamRegistrationId);
      if (index != -1) {
        list[index] = list[index].copyWith(
          status: status,
          reviewNote: note,
          reviewedBy: reviewedBy ?? 'Admin',
          reviewedAt: DateTime.now(),
        );
      }
    }

    try {
      await _api.patch(
        '/tournaments/$tournamentId/registrations/$teamRegistrationId',
        body: body,
      );
    } catch (e) {
      if (e is! ApiException ||
          (e.code != 'NETWORK_ERROR' &&
              e.code != 'TIMEOUT' &&
              e.statusCode != 503)) {
        rethrow;
      }
    }
    await refreshTeams(tournamentId);
  }

  // ----------------------------------------------------
  // MATCHES & SCHEDULE
  // ----------------------------------------------------

  StreamController<List<TournamentMatch>> _getMatchesController(
    String tournamentId,
  ) {
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
            list.add(
              TournamentMatch.fromMap(item, item['id']?.toString() ?? ''),
            );
          }
        }
      }
      final local = _userGeneratedMatches[tournamentId] ?? [];
      final combined = [
        ...local,
        ...list.where((m) => !local.any((l) => l.id == m.id)),
      ];
      controller.add(combined);
      return combined;
    } catch (_) {
      // Chỉ gán lịch thi đấu mẫu khi là giải đấu demo hệ thống
      if (tournamentId == sampleDemoTournamentId &&
          (!_userGeneratedMatches.containsKey(tournamentId) ||
              _userGeneratedMatches[tournamentId]!.isEmpty)) {
        final fallback = TournamentSeedData.getSampleMatches(tournamentId);
        controller.add(fallback);
        return fallback;
      }
      final local = _userGeneratedMatches[tournamentId] ?? [];
      controller.add(local);
      return local;
    }
  }

  @override
  Future<void> generateSchedule(
    String tournamentId, {
    String venue = 'Sân vận động chính',
  }) async {
    try {
      await _api.post(
        '/tournaments/$tournamentId/schedule',
        body: {'venue': venue},
      );
    } catch (e) {
      if (e is! ApiException ||
          (e.code != 'NETWORK_ERROR' &&
              e.code != 'TIMEOUT' &&
              e.statusCode != 503)) {
        rethrow;
      }
      final tournament = await getTournament(tournamentId);
      if (tournament != null) {
        final teams = (_userRegisteredTeams[tournamentId] ?? [])
            .where((t) => t.isApproved)
            .toList();
        final existing = _userGeneratedMatches[tournamentId] ?? [];
        if (teams.length >= 2) {
          final generated = ScheduleGenerator.generate(
            tournament: tournament,
            approvedTeams: teams,
            existingMatches: existing,
            defaultVenue: venue,
          );
          _userGeneratedMatches[tournamentId] = generated;
        }
      }
    }
    await refreshMatches(tournamentId);
    await refreshStandings(tournamentId);
    await refreshTournaments();
  }

  @override
  Future<void> saveMatches(
    String tournamentId,
    List<TournamentMatch> matches,
  ) async {
    final list = _userGeneratedMatches.putIfAbsent(tournamentId, () => []);
    list.clear();
    list.addAll(matches);

    try {
      for (final m in matches) {
        await _api.patch(
          '/matches/${m.id}',
          body: {
            'scheduledTime': m.scheduledTime.toIso8601String(),
            'venue': m.venue,
            'notes': m.notes,
            'status': m.status.name,
          },
        );
      }
    } catch (e) {
      if (e is! ApiException ||
          (e.code != 'NETWORK_ERROR' &&
              e.code != 'TIMEOUT' &&
              e.statusCode != 503)) {
        rethrow;
      }
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

  StreamController<List<StandingsRow>> _getStandingsController(
    String tournamentId,
  ) {
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
            list.add(
              StandingsRow.fromMap(item, item['teamId']?.toString() ?? ''),
            );
          }
        }
      }
      final local = _userStandings[tournamentId] ?? [];
      final combined = [
        ...local,
        ...list.where((s) => !local.any((l) => l.teamId == s.teamId)),
      ];
      controller.add(combined);
      return combined;
    } catch (_) {
      // Chỉ gán bảng xếp hạng mẫu khi là giải đấu demo hệ thống
      if (tournamentId == sampleDemoTournamentId &&
          (!_userStandings.containsKey(tournamentId) ||
              _userStandings[tournamentId]!.isEmpty)) {
        final fallback = TournamentSeedData.getSampleStandings(tournamentId);
        controller.add(fallback);
        return fallback;
      }
      final local = _userStandings[tournamentId] ?? [];
      controller.add(local);
      return local;
    }
  }

  @override
  Future<void> recalculateAndSaveStandings(String tournamentId) async {
    try {
      await _api.post('/tournaments/$tournamentId/standings/recalculate');
    } catch (e) {
      if (e is! ApiException ||
          (e.code != 'NETWORK_ERROR' &&
              e.code != 'TIMEOUT' &&
              e.statusCode != 503)) {
        rethrow;
      }
      final teams = (_userRegisteredTeams[tournamentId] ?? [])
          .where((t) => t.isApproved)
          .toList();
      final matches = _userGeneratedMatches[tournamentId] ?? [];
      final calculated = StandingsCalculator.compute(
        teams: teams,
        matches: matches,
      );
      _userStandings[tournamentId] = calculated;
    }
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

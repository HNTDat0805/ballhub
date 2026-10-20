import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../domain/models/match.dart';
import '../domain/models/match_audit.dart';
import '../domain/models/standings_row.dart';
import '../domain/models/tournament.dart';
import '../domain/models/tournament_team.dart';
import '../domain/services/schedule_generator.dart';
import '../domain/services/standings_calculator.dart';
import 'tournament_repository.dart';

class FirebaseTournamentRepository implements TournamentRepository {
  final FirebaseDatabase? _db;
  final bool _isFirebaseReady;

  // In-memory fallback cache to ensure offline safety and resilience
  final Map<String, Tournament> _cacheTournaments = {};
  final Map<String, List<TournamentTeam>> _cacheTeams = {};
  final Map<String, List<TournamentMatch>> _cacheMatches = {};
  final Map<String, List<StandingsRow>> _cacheStandings = {};
  final Map<String, List<MatchAudit>> _cacheAudits = {};

  final _tournamentStreamController = StreamController<List<Tournament>>.broadcast();
  final Map<String, StreamController<List<TournamentTeam>>> _teamsControllers = {};
  final Map<String, StreamController<List<TournamentMatch>>> _matchesControllers = {};
  final Map<String, StreamController<List<StandingsRow>>> _standingsControllers = {};
  final Map<String, StreamController<List<MatchAudit>>> _auditsControllers = {};

  FirebaseTournamentRepository({FirebaseDatabase? database})
      : _db = database ?? _tryGetDatabase(),
        _isFirebaseReady = Firebase.apps.isNotEmpty {
    _initSampleDataIfEmpty();
  }

  static FirebaseDatabase? _tryGetDatabase() {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseDatabase.instance;
      }
    } catch (_) {}
    return null;
  }

  bool get isConnectedToFirebase => _isFirebaseReady && _db != null;

  void _initSampleDataIfEmpty() {
    if (_cacheTournaments.isEmpty) {
      final sampleId = 'tour_ballhub_cup_2026';
      final sampleTournament = Tournament(
        id: sampleId,
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
      );
      _cacheTournaments[sampleId] = sampleTournament;

      final sampleTeams = [
        TournamentTeam(
          id: 'reg_01',
          tournamentId: sampleId,
          teamId: 'team_sao_vang',
          teamName: 'FC Sao Vàng',
          captainId: 'user_captain_01',
          captainName: 'Trần Đội Trưởng',
          captainPhone: '0901234567',
          captainEmail: 'captain1@ballhub.vn',
          status: RegistrationStatus.approved,
          registeredAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        TournamentTeam(
          id: 'reg_02',
          tournamentId: sampleId,
          teamId: 'team_rong_do',
          teamName: 'FC Rồng Đỏ',
          captainId: 'user_captain_02',
          captainName: 'Lê Đội Trưởng',
          captainPhone: '0907654321',
          captainEmail: 'captain2@ballhub.vn',
          status: RegistrationStatus.approved,
          registeredAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        TournamentTeam(
          id: 'reg_03',
          tournamentId: sampleId,
          teamId: 'team_dai_bang',
          teamName: 'FC Đại Bàng',
          captainId: 'user_captain_03',
          captainName: 'Nguyễn Văn Ba',
          captainPhone: '0912345678',
          captainEmail: 'captain3@ballhub.vn',
          status: RegistrationStatus.approved,
          registeredAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        TournamentTeam(
          id: 'reg_04',
          tournamentId: sampleId,
          teamId: 'team_chien_binh',
          teamName: 'FC Chiến Binh',
          captainId: 'user_captain_04',
          captainName: 'Hoàng Văn Bốn',
          captainPhone: '0987654321',
          captainEmail: 'captain4@ballhub.vn',
          status: RegistrationStatus.approved,
          registeredAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      _cacheTeams[sampleId] = sampleTeams;
    }
  }

  // ----------------------------------------------------
  // TOURNAMENTS
  // ----------------------------------------------------

  @override
  Stream<List<Tournament>> watchTournaments() {
    if (isConnectedToFirebase) {
      return _db!.ref('tournaments').onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return [];
        final list = <Tournament>[];
        if (data is Map) {
          data.forEach((key, val) {
            if (val is Map) {
              list.add(Tournament.fromMap(val, key.toString()));
            }
          });
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    }

    // Local stream fallback
    Timer.run(() => _tournamentStreamController.add(_cacheTournaments.values.toList()));
    return _tournamentStreamController.stream;
  }

  @override
  Future<Tournament?> getTournament(String tournamentId) async {
    if (isConnectedToFirebase) {
      final snap = await _db!.ref('tournaments/$tournamentId').get();
      if (snap.exists && snap.value is Map) {
        return Tournament.fromMap(snap.value as Map, tournamentId);
      }
      return null;
    }
    return _cacheTournaments[tournamentId];
  }

  @override
  Future<void> createTournament(Tournament tournament) async {
    if (isConnectedToFirebase) {
      await _db!.ref('tournaments/${tournament.id}').set(tournament.toMap());
    }
    _cacheTournaments[tournament.id] = tournament;
    _tournamentStreamController.add(_cacheTournaments.values.toList());
  }

  @override
  Future<void> updateTournament(Tournament tournament) async {
    if (isConnectedToFirebase) {
      await _db!.ref('tournaments/${tournament.id}').update(tournament.toMap());
    }
    _cacheTournaments[tournament.id] = tournament;
    _tournamentStreamController.add(_cacheTournaments.values.toList());
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    final db = _db;
    if (isConnectedToFirebase && db != null) {
      // Safe cleanup of related nodes
      await db.ref('tournaments/$tournamentId').remove();
      await db.ref('tournament_teams/$tournamentId').remove();
      await db.ref('matches/$tournamentId').remove();
      await db.ref('standings/$tournamentId').remove();
      await db.ref('match_audit/$tournamentId').remove();
    }
    _cacheTournaments.remove(tournamentId);
    _cacheTeams.remove(tournamentId);
    _cacheMatches.remove(tournamentId);
    _cacheStandings.remove(tournamentId);
    _cacheAudits.remove(tournamentId);
    _tournamentStreamController.add(_cacheTournaments.values.toList());
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
    if (isConnectedToFirebase) {
      return _db!.ref('tournament_teams/$tournamentId').onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return [];
        final list = <TournamentTeam>[];
        if (data is Map) {
          data.forEach((key, val) {
            if (val is Map) {
              list.add(TournamentTeam.fromMap(val, key.toString()));
            }
          });
        }
        list.sort((a, b) => a.registeredAt.compareTo(b.registeredAt));
        return list;
      });
    }

    final controller = _getTeamsController(tournamentId);
    final teams = _cacheTeams[tournamentId] ?? [];
    Timer.run(() => controller.add(teams));
    return controller.stream;
  }

  @override
  Future<void> registerTeam(TournamentTeam team) async {
    final db = _db;
    if (isConnectedToFirebase && db != null) {
      // Prevent duplicate registration: check by teamId
      final existingSnap = await db
          .ref('tournament_teams/${team.tournamentId}')
          .orderByChild('teamId')
          .equalTo(team.teamId)
          .get();

      if (existingSnap.exists && existingSnap.value != null) {
        throw Exception('Đội bóng "${team.teamName}" đã đăng ký tham gia giải đấu này rồi.');
      }

      await db.ref('tournament_teams/${team.tournamentId}/${team.id}').set(team.toMap());
    }

    final list = _cacheTeams.putIfAbsent(team.tournamentId, () => []);
    if (list.any((t) => t.teamId == team.teamId && t.status != RegistrationStatus.cancelled)) {
      throw Exception('Đội bóng "${team.teamName}" đã đăng ký giải này rồi.');
    }
    list.add(team);
    _getTeamsController(team.tournamentId).add(List.from(list));
  }

  @override
  Future<void> updateTeamStatus(
    String tournamentId,
    String teamRegistrationId,
    RegistrationStatus status, {
    String? note,
    String? reviewedBy,
  }) async {
    final now = DateTime.now();
    final updates = {
      'status': status.name,
      'reviewedAt': now.toIso8601String(),
      'reviewedBy': reviewedBy ?? 'Admin',
      'reviewNote': note,
    };

    if (isConnectedToFirebase) {
      await _db!.ref('tournament_teams/$tournamentId/$teamRegistrationId').update(updates);
    }

    final list = _cacheTeams[tournamentId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == teamRegistrationId);
      if (index != -1) {
        list[index] = list[index].copyWith(
          status: status,
          reviewedAt: now,
          reviewedBy: reviewedBy ?? 'Admin',
          reviewNote: note,
        );
        _getTeamsController(tournamentId).add(List.from(list));
      }
    }
  }

  // ----------------------------------------------------
  // MATCHES & RESULTS
  // ----------------------------------------------------

  StreamController<List<TournamentMatch>> _getMatchesController(String tournamentId) {
    return _matchesControllers.putIfAbsent(
      tournamentId,
      () => StreamController<List<TournamentMatch>>.broadcast(),
    );
  }

  @override
  Stream<List<TournamentMatch>> watchMatches(String tournamentId) {
    if (isConnectedToFirebase) {
      return _db!.ref('matches/$tournamentId').onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return [];
        final list = <TournamentMatch>[];
        if (data is Map) {
          data.forEach((key, val) {
            if (val is Map) {
              list.add(TournamentMatch.fromMap(val, key.toString()));
            }
          });
        }
        list.sort((a, b) {
          final rComp = a.round.compareTo(b.round);
          if (rComp != 0) return rComp;
          return a.scheduledTime.compareTo(b.scheduledTime);
        });
        return list;
      });
    }

    final controller = _getMatchesController(tournamentId);
    final matches = _cacheMatches[tournamentId] ?? [];
    Timer.run(() => controller.add(matches));
    return controller.stream;
  }

  @override
  Future<void> saveMatches(String tournamentId, List<TournamentMatch> matches) async {
    if (isConnectedToFirebase) {
      final map = <String, dynamic>{};
      for (final m in matches) {
        map[m.id] = m.toMap();
      }
      await _db!.ref('matches/$tournamentId').set(map);
    }

    _cacheMatches[tournamentId] = List.from(matches);
    _getMatchesController(tournamentId).add(List.from(matches));
  }

  @override
  Future<void> generateSchedule(String tournamentId, {String venue = 'Sân vận động chính'}) async {
    final tournament = await getTournament(tournamentId);
    if (tournament == null) return;
    final teams = _cacheTeams[tournamentId] ?? [];
    final approved = teams.where((t) => t.isApproved).toList();
    final existing = _cacheMatches[tournamentId] ?? [];
    final matches = ScheduleGenerator.generate(
      tournament: tournament,
      approvedTeams: approved,
      existingMatches: existing,
      defaultVenue: venue,
    );
    await saveMatches(tournamentId, matches);
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
    if (homeScore < 0 || awayScore < 0) {
      throw ArgumentError('Tỷ số trận đấu không được là số âm.');
    }

    final now = DateTime.now();

    // 1. Fetch current match to record old values for audit
    TournamentMatch? currentMatch;
    if (isConnectedToFirebase) {
      final snap = await _db!.ref('matches/$tournamentId/$matchId').get();
      if (snap.exists && snap.value is Map) {
        currentMatch = TournamentMatch.fromMap(snap.value as Map, matchId);
      }
    } else {
      final list = _cacheMatches[tournamentId] ?? [];
      currentMatch = list.firstWhere((m) => m.id == matchId, orElse: () => throw Exception('Không tìm thấy trận đấu'));
    }

    final matchUpdateData = {
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': status.name,
      'isConfirmed': isConfirmed,
      'confirmedBy': isConfirmed ? updatedBy : null,
      'confirmedAt': isConfirmed ? now.toIso8601String() : null,
      'notes': notes,
    };

    if (isConnectedToFirebase) {
      await _db!.ref('matches/$tournamentId/$matchId').update(matchUpdateData);
    }

    // 2. Log audit trail
    final auditId = 'audit_${now.millisecondsSinceEpoch}_$matchId';
    final audit = MatchAudit(
      id: auditId,
      tournamentId: tournamentId,
      matchId: matchId,
      action: isConfirmed
          ? (currentMatch?.isConfirmed == true ? 'result_modified' : 'result_confirmed')
          : 'score_draft_updated',
      oldHomeScore: currentMatch?.homeScore,
      oldAwayScore: currentMatch?.awayScore,
      newHomeScore: homeScore,
      newAwayScore: awayScore,
      updatedBy: updatedBy,
      updatedAt: now,
      reason: reason,
    );

    if (isConnectedToFirebase) {
      await _db!.ref('match_audit/$tournamentId/$auditId').set(audit.toMap());
    }
    final auditList = _cacheAudits.putIfAbsent(tournamentId, () => []);
    auditList.insert(0, audit);
    _getAuditsController(tournamentId).add(List.from(auditList));

    // Update in-memory match cache
    final mList = _cacheMatches[tournamentId];
    if (mList != null) {
      final idx = mList.indexWhere((m) => m.id == matchId);
      if (idx != -1) {
        mList[idx] = mList[idx].copyWith(
          homeScore: homeScore,
          awayScore: awayScore,
          status: status,
          isConfirmed: isConfirmed,
          confirmedBy: isConfirmed ? updatedBy : null,
          confirmedAt: isConfirmed ? now : null,
          notes: notes,
        );
        _getMatchesController(tournamentId).add(List.from(mList));
      }
    }

    // 3. Automatically trigger deterministic standings recalculation if result is official
    await recalculateAndSaveStandings(tournamentId);
  }

  // ----------------------------------------------------
  // STANDINGS (BẢNG XẾP HẠNG TỰ ĐỘNG)
  // ----------------------------------------------------

  StreamController<List<StandingsRow>> _getStandingsController(String tournamentId) {
    return _standingsControllers.putIfAbsent(
      tournamentId,
      () => StreamController<List<StandingsRow>>.broadcast(),
    );
  }

  @override
  Stream<List<StandingsRow>> watchStandings(String tournamentId) {
    if (isConnectedToFirebase) {
      return _db!.ref('standings/$tournamentId').onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return [];
        final list = <StandingsRow>[];
        if (data is Map) {
          data.forEach((key, val) {
            if (val is Map) {
              list.add(StandingsRow.fromMap(val, key.toString()));
            }
          });
        }
        list.sort((a, b) => a.rank.compareTo(b.rank));
        return list;
      });
    }

    final controller = _getStandingsController(tournamentId);
    final standings = _cacheStandings[tournamentId] ?? [];
    Timer.run(() => controller.add(standings));
    return controller.stream;
  }

  @override
  Future<void> recalculateAndSaveStandings(String tournamentId) async {
    List<TournamentTeam> approvedTeams = [];
    List<TournamentMatch> allMatches = [];

    final db = _db;
    if (isConnectedToFirebase && db != null) {
      final teamsSnap = await db.ref('tournament_teams/$tournamentId').get();
      if (teamsSnap.exists && teamsSnap.value is Map) {
        (teamsSnap.value as Map).forEach((k, v) {
          if (v is Map) {
            final t = TournamentTeam.fromMap(v, k.toString());
            if (t.isApproved) approvedTeams.add(t);
          }
        });
      }

      final matchesSnap = await db.ref('matches/$tournamentId').get();
      if (matchesSnap.exists && matchesSnap.value is Map) {
        (matchesSnap.value as Map).forEach((k, v) {
          if (v is Map) {
            allMatches.add(TournamentMatch.fromMap(v, k.toString()));
          }
        });
      }
    } else {
      approvedTeams = (_cacheTeams[tournamentId] ?? []).where((t) => t.isApproved).toList();
      allMatches = _cacheMatches[tournamentId] ?? [];
    }

    // Pure deterministic calculation: handles ties, goal diff, points, head-to-head
    final newStandings = StandingsCalculator.compute(
      teams: approvedTeams,
      matches: allMatches,
    );

    if (isConnectedToFirebase) {
      final standingsMap = <String, dynamic>{};
      for (final s in newStandings) {
        standingsMap[s.teamId] = s.toMap();
      }
      await _db!.ref('standings/$tournamentId').set(standingsMap);
    }

    _cacheStandings[tournamentId] = List.from(newStandings);
    _getStandingsController(tournamentId).add(List.from(newStandings));
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
    if (isConnectedToFirebase) {
      return _db!.ref('match_audit/$tournamentId').onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return [];
        final list = <MatchAudit>[];
        if (data is Map) {
          data.forEach((key, val) {
            if (val is Map) {
              list.add(MatchAudit.fromMap(val, key.toString()));
            }
          });
        }
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return list;
      });
    }

    final controller = _getAuditsController(tournamentId);
    final audits = _cacheAudits[tournamentId] ?? [];
    Timer.run(() => controller.add(audits));
    return controller.stream;
  }
}

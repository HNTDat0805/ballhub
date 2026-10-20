import 'package:flutter/foundation.dart';
import '../../data/tournament_repository.dart';
import '../../domain/models/match.dart';
import '../../domain/models/standings_row.dart';
import '../../domain/models/tournament.dart';
import '../../domain/models/tournament_team.dart';

class TournamentController extends ChangeNotifier {
  final TournamentRepository repository;

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  TournamentStatus? _selectedStatusFilter;

  TournamentController({required this.repository});

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  TournamentStatus? get selectedStatusFilter => _selectedStatusFilter;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(TournamentStatus? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Stream<List<Tournament>> watchTournaments() {
    return repository.watchTournaments().map((list) {
      return list.where((t) {
        final matchesQuery = _searchQuery.isEmpty ||
            t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.location.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesStatus = _selectedStatusFilter == null || t.status == _selectedStatusFilter;
        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  Stream<List<TournamentTeam>> watchTeams(String tournamentId) {
    return repository.watchTeams(tournamentId);
  }

  Stream<List<TournamentMatch>> watchMatches(String tournamentId) {
    return repository.watchMatches(tournamentId);
  }

  Stream<List<StandingsRow>> watchStandings(String tournamentId) {
    return repository.watchStandings(tournamentId);
  }

  Future<bool> createTournament(Tournament tournament) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.createTournament(tournament);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể tạo giải đấu: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTournament(Tournament tournament) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.updateTournament(tournament);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật giải đấu: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTournament(String tournamentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.deleteTournament(tournamentId);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa giải đấu: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerTeam(TournamentTeam team) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.registerTeam(team);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTeamStatus(
    String tournamentId,
    String teamRegistrationId,
    RegistrationStatus status, {
    String? note,
    String? reviewedBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.updateTeamStatus(
        tournamentId,
        teamRegistrationId,
        status,
        note: note,
        reviewedBy: reviewedBy,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật trạng thái đội: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> generateSchedule({
    required Tournament tournament,
    required List<TournamentTeam> approvedTeams,
    required List<TournamentMatch> existingMatches,
    String venue = 'Sân vận động chính',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.generateSchedule(tournament.id, venue: venue);
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi tạo lịch thi đấu: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMatchResult({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.updateMatchResult(
        tournamentId: tournamentId,
        matchId: matchId,
        homeScore: homeScore,
        awayScore: awayScore,
        status: status,
        isConfirmed: isConfirmed,
        updatedBy: updatedBy,
        notes: notes,
        reason: reason,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi cập nhật tỷ số: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

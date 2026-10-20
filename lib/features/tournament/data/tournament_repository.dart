import '../domain/models/match.dart';
import '../domain/models/match_audit.dart';
import '../domain/models/standings_row.dart';
import '../domain/models/tournament.dart';
import '../domain/models/tournament_team.dart';

abstract class TournamentRepository {
  Stream<List<Tournament>> watchTournaments();
  Future<Tournament?> getTournament(String tournamentId);
  Future<void> createTournament(Tournament tournament);
  Future<void> updateTournament(Tournament tournament);
  Future<void> deleteTournament(String tournamentId);

  Stream<List<TournamentTeam>> watchTeams(String tournamentId);
  Future<void> registerTeam(TournamentTeam team);
  Future<void> updateTeamStatus(
    String tournamentId,
    String teamRegistrationId,
    RegistrationStatus status, {
    String? note,
    String? reviewedBy,
  });

  Stream<List<TournamentMatch>> watchMatches(String tournamentId);
  Future<void> saveMatches(String tournamentId, List<TournamentMatch> matches);
  Future<void> generateSchedule(String tournamentId, {String venue = 'Sân vận động chính'});
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
  });

  Stream<List<StandingsRow>> watchStandings(String tournamentId);
  Future<void> recalculateAndSaveStandings(String tournamentId);

  Stream<List<MatchAudit>> watchMatchAuditLogs(String tournamentId);
}

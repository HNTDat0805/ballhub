import '../models/match.dart';
import '../models/tournament.dart';
import '../models/tournament_team.dart';

/// Bộ tạo lịch thi đấu tự động cho giải đấu bóng đá (Schedule Generator).
///
/// Hỗ trợ:
/// 1. Vòng tròn 1 lượt (Single Round Robin - thuật toán Berger xoay vòng).
/// 2. Vòng tròn 2 lượt (Double Round Robin - lượt đi và lượt về).
/// 3. Loại trực tiếp (Single Elimination Knockout).
/// 4. Bảo toàn kết quả: không ghi đè hoặc làm mất các trận đấu đã có kết quả chính thức.
class ScheduleGenerator {
  /// Sinh danh sách các trận đấu dựa trên thể thức giải và danh sách đội đã duyệt.
  /// Nếu đã có các trận đấu trước đó có kết quả chính thức, chúng sẽ được giữ nguyên an toàn.
  static List<TournamentMatch> generate({
    required Tournament tournament,
    required List<TournamentTeam> approvedTeams,
    List<TournamentMatch> existingMatches = const [],
    String defaultVenue = 'Sân vận động chính',
  }) {
    if (approvedTeams.length < 2) {
      return existingMatches;
    }

    final confirmedMatches = existingMatches.where((m) => m.isOfficialResult).toList();
    final hasExistingConfirmed = confirmedMatches.isNotEmpty;

    List<TournamentMatch> newMatches;
    switch (tournament.format) {
      case TournamentFormat.roundRobinSingle:
        newMatches = _generateRoundRobin(
          tournament: tournament,
          teams: approvedTeams,
          isDouble: false,
          venue: defaultVenue,
        );
        break;
      case TournamentFormat.roundRobinDouble:
        newMatches = _generateRoundRobin(
          tournament: tournament,
          teams: approvedTeams,
          isDouble: true,
          venue: defaultVenue,
        );
        break;
      case TournamentFormat.knockout:
        newMatches = _generateKnockout(
          tournament: tournament,
          teams: approvedTeams,
          venue: defaultVenue,
        );
        break;
    }

    // Safe merge: preserve any matches that already had confirmed results
    if (hasExistingConfirmed) {
      final merged = <TournamentMatch>[];
      for (final generated in newMatches) {
        final existing = existingMatches.firstWhere(
          (e) =>
              (e.homeTeamId == generated.homeTeamId && e.awayTeamId == generated.awayTeamId) ||
              (e.round == generated.round &&
                  e.homeTeamId == generated.homeTeamId &&
                  e.awayTeamId == generated.awayTeamId),
          orElse: () => generated,
        );
        merged.add(existing);
      }
      return merged;
    }

    return newMatches;
  }

  /// Implements standard Berger Round-Robin (Circle Method).
  /// Handles both even and odd team counts gracefully without ghost matches.
  static List<TournamentMatch> _generateRoundRobin({
    required Tournament tournament,
    required List<TournamentTeam> teams,
    required bool isDouble,
    required String venue,
  }) {
    final matches = <TournamentMatch>[];
    final teamList = List<TournamentTeam?>.from(teams);

    // If odd number of teams, add null as a BYE (nghỉ lượt)
    final isOdd = teamList.length % 2 != 0;
    if (isOdd) {
      teamList.add(null);
    }

    final n = teamList.length;
    final totalRounds = n - 1;
    final matchesPerRound = n ~/ 2;

    DateTime matchDateTime = tournament.startDate.copyWith(hour: 8, minute: 0);

    // First leg (Lượt đi)
    for (int round = 0; round < totalRounds; round++) {
      final roundNumber = round + 1;
      final roundName = 'Vòng $roundNumber';

      for (int matchIdx = 0; matchIdx < matchesPerRound; matchIdx++) {
        final team1 = teamList[matchIdx];
        final team2 = teamList[n - 1 - matchIdx];

        // If either team is null, this is an off-day (BYE) for the other team
        if (team1 == null || team2 == null) {
          continue;
        }

        // Alternate home/away to ensure fairness
        final homeTeam = (round % 2 == 0) ? team1 : team2;
        final awayTeam = (round % 2 == 0) ? team2 : team1;

        final matchId = '${tournament.id}_r${roundNumber}_m${matchIdx + 1}_${homeTeam.id}_${awayTeam.id}';

        // Schedule time: stagger matches by 2 hours
        final scheduledTime = matchDateTime.add(Duration(days: round, hours: matchIdx * 2));

        matches.add(TournamentMatch(
          id: matchId,
          tournamentId: tournament.id,
          round: roundNumber,
          roundName: roundName,
          homeTeamId: homeTeam.teamId,
          homeTeamName: homeTeam.teamName,
          awayTeamId: awayTeam.teamId,
          awayTeamName: awayTeam.teamName,
          scheduledTime: scheduledTime,
          venue: venue,
          status: MatchStatus.scheduled,
        ));
      }

      // Rotate teams using Circle method: keep teamList[0] fixed, rotate remaining
      final last = teamList.removeLast();
      teamList.insert(1, last);
    }

    // Second leg (Lượt về) if double round-robin
    if (isDouble) {
      final firstLegCount = matches.length;
      final returnStartDay = totalRounds + 2;

      for (int i = 0; i < firstLegCount; i++) {
        final original = matches[i];
        final returnRoundNumber = original.round + totalRounds;
        final returnRoundName = 'Vòng $returnRoundNumber (Lượt về)';
        final returnScheduledTime = original.scheduledTime.add(Duration(days: returnStartDay));
        final returnMatchId = '${tournament.id}_r${returnRoundNumber}_return_${original.awayTeamId}_${original.homeTeamId}';

        matches.add(TournamentMatch(
          id: returnMatchId,
          tournamentId: tournament.id,
          round: returnRoundNumber,
          roundName: returnRoundName,
          homeTeamId: original.awayTeamId,
          homeTeamName: original.awayTeamName,
          awayTeamId: original.homeTeamId,
          awayTeamName: original.homeTeamName,
          scheduledTime: returnScheduledTime,
          venue: venue,
          status: MatchStatus.scheduled,
        ));
      }
    }

    return matches;
  }

  /// Generates initial knockout round fixtures.
  static List<TournamentMatch> _generateKnockout({
    required Tournament tournament,
    required List<TournamentTeam> teams,
    required String venue,
  }) {
    final matches = <TournamentMatch>[];
    final teamCount = teams.length;

    // Power of 2 bracket size
    int bracketSize = 2;
    while (bracketSize < teamCount) {
      bracketSize *= 2;
    }

    String roundName;
    if (bracketSize == 2) {
      roundName = 'Chung kết';
    } else if (bracketSize == 4) {
      roundName = 'Bán kết';
    } else if (bracketSize == 8) {
      roundName = 'Tứ kết';
    } else {
      roundName = 'Vòng 1/$bracketSize';
    }

    DateTime matchDateTime = tournament.startDate.copyWith(hour: 8, minute: 0);

    for (int i = 0; i < teamCount ~/ 2; i++) {
      final homeTeam = teams[i];
      final awayTeam = teams[teamCount - 1 - i];
      final matchId = '${tournament.id}_ko1_m${i + 1}_${homeTeam.id}_${awayTeam.id}';
      final scheduledTime = matchDateTime.add(Duration(hours: i * 2));

      matches.add(TournamentMatch(
        id: matchId,
        tournamentId: tournament.id,
        round: 1,
        roundName: roundName,
        homeTeamId: homeTeam.teamId,
        homeTeamName: homeTeam.teamName,
        awayTeamId: awayTeam.teamId,
        awayTeamName: awayTeam.teamName,
        scheduledTime: scheduledTime,
        venue: venue,
        status: MatchStatus.scheduled,
      ));
    }

    return matches;
  }
}

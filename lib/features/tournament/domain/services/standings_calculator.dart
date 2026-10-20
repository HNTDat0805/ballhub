import '../models/match.dart';
import '../models/standings_row.dart';
import '../models/tournament_team.dart';

class StandingsCalculator {
  /// Pure function: computes tournament standings deterministically
  /// from all official, confirmed matches.
  static List<StandingsRow> compute({
    required List<TournamentTeam> teams,
    required List<TournamentMatch> matches,
  }) {
    // 1. Initialize stats table for each approved team
    final stats = <String, _MutableTeamStats>{};
    for (final team in teams) {
      stats[team.teamId] = _MutableTeamStats(
        teamId: team.teamId,
        teamName: team.teamName,
        logoUrl: team.logoUrl,
      );
    }

    // 2. Accumulate results from official confirmed matches only
    final confirmedMatches = matches.where((m) => m.isOfficialResult).toList();

    for (final match in confirmedMatches) {
      final home = stats[match.homeTeamId];
      final away = stats[match.awayTeamId];

      if (home == null || away == null) continue;

      final hScore = match.homeScore!;
      final aScore = match.awayScore!;

      home.played += 1;
      away.played += 1;

      home.goalsFor += hScore;
      home.goalsAgainst += aScore;

      away.goalsFor += aScore;
      away.goalsAgainst += hScore;

      if (hScore > aScore) {
        home.won += 1;
        away.lost += 1;
      } else if (hScore < aScore) {
        away.won += 1;
        home.lost += 1;
      } else {
        home.drawn += 1;
        away.drawn += 1;
      }
    }

    // 3. Convert to list and sort using official football tie-breakers
    final list = stats.values.toList();

    list.sort((a, b) {
      // Criterion 1: Points
      final ptsCompare = b.points.compareTo(a.points);
      if (ptsCompare != 0) return ptsCompare;

      // Criterion 2: Goal Difference
      final gdCompare = b.goalDifference.compareTo(a.goalDifference);
      if (gdCompare != 0) return gdCompare;

      // Criterion 3: Goals For (Scored)
      final gfCompare = b.goalsFor.compareTo(a.goalsFor);
      if (gfCompare != 0) return gfCompare;

      // Criterion 4: Head-to-Head points between tied teams
      final h2hCompare = _compareHeadToHead(a.teamId, b.teamId, confirmedMatches);
      if (h2hCompare != 0) return h2hCompare;

      // Fallback: Alphabetical
      return a.teamName.compareTo(b.teamName);
    });

    // 4. Assign ranks (1-indexed)
    final standings = <StandingsRow>[];
    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      standings.add(StandingsRow(
        teamId: item.teamId,
        teamName: item.teamName,
        logoUrl: item.logoUrl,
        played: item.played,
        won: item.won,
        drawn: item.drawn,
        lost: item.lost,
        goalsFor: item.goalsFor,
        goalsAgainst: item.goalsAgainst,
        goalDifference: item.goalDifference,
        points: item.points,
        rank: i + 1,
      ));
    }

    return standings;
  }

  /// Calculates head-to-head point difference between two tied teams
  static int _compareHeadToHead(String teamA, String teamB, List<TournamentMatch> matches) {
    int pointsA = 0;
    int pointsB = 0;

    for (final m in matches) {
      if ((m.homeTeamId == teamA && m.awayTeamId == teamB) ||
          (m.homeTeamId == teamB && m.awayTeamId == teamA)) {
        final scoreA = (m.homeTeamId == teamA) ? m.homeScore! : m.awayScore!;
        final scoreB = (m.homeTeamId == teamB) ? m.homeScore! : m.awayScore!;

        if (scoreA > scoreB) {
          pointsA += 3;
        } else if (scoreB > scoreA) {
          pointsB += 3;
        } else {
          pointsA += 1;
          pointsB += 1;
        }
      }
    }

    return pointsB.compareTo(pointsA); // descending
  }
}

class _MutableTeamStats {
  final String teamId;
  final String teamName;
  final String logoUrl;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  _MutableTeamStats({
    required this.teamId,
    required this.teamName,
    required this.logoUrl,
  });

  int get goalDifference => goalsFor - goalsAgainst;
  int get points => won * 3 + drawn * 1;
}

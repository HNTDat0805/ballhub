import 'package:flutter_test/flutter_test.dart';
import 'package:ballhub/features/tournament/domain/models/match.dart';
import 'package:ballhub/features/tournament/domain/models/tournament_team.dart';
import 'package:ballhub/features/tournament/domain/services/standings_calculator.dart';

void main() {
  group('StandingsCalculator Tests', () {
    late List<TournamentTeam> teams;

    setUp(() {
      teams = [
        TournamentTeam(
          id: 'reg_A',
          tournamentId: 't1',
          teamId: 'team_A',
          teamName: 'FC Sao Vàng',
          captainId: 'c1',
          captainName: 'Cap A',
          captainPhone: '0901',
          captainEmail: 'a@mail.com',
          status: RegistrationStatus.approved,
          registeredAt: DateTime(2026, 10, 1),
        ),
        TournamentTeam(
          id: 'reg_B',
          tournamentId: 't1',
          teamId: 'team_B',
          teamName: 'FC Rồng Đỏ',
          captainId: 'c2',
          captainName: 'Cap B',
          captainPhone: '0902',
          captainEmail: 'b@mail.com',
          status: RegistrationStatus.approved,
          registeredAt: DateTime(2026, 10, 1),
        ),
        TournamentTeam(
          id: 'reg_C',
          tournamentId: 't1',
          teamId: 'team_C',
          teamName: 'FC Đại Bàng',
          captainId: 'c3',
          captainName: 'Cap C',
          captainPhone: '0903',
          captainEmail: 'c@mail.com',
          status: RegistrationStatus.approved,
          registeredAt: DateTime(2026, 10, 1),
        ),
      ];
    });

    test('Initial table with no matches played has 0 points and 0 games for all', () {
      final standings = StandingsCalculator.compute(
        teams: teams,
        matches: [],
      );

      expect(standings.length, equals(3));
      for (final row in standings) {
        expect(row.played, equals(0));
        expect(row.points, equals(0));
        expect(row.goalDifference, equals(0));
      }
    });

    test('Winning team gets 3 points, losing team gets 0, goal difference calculated correctly', () {
      final match1 = TournamentMatch(
        id: 'm1',
        tournamentId: 't1',
        round: 1,
        roundName: 'Vòng 1',
        homeTeamId: 'team_A',
        homeTeamName: 'FC Sao Vàng',
        awayTeamId: 'team_B',
        awayTeamName: 'FC Rồng Đỏ',
        scheduledTime: DateTime.now(),
        venue: 'Sân 1',
        status: MatchStatus.finished,
        homeScore: 3,
        awayScore: 1,
        isConfirmed: true, // Official
      );

      final standings = StandingsCalculator.compute(
        teams: teams,
        matches: [match1],
      );

      final rowA = standings.firstWhere((r) => r.teamId == 'team_A');
      final rowB = standings.firstWhere((r) => r.teamId == 'team_B');

      expect(rowA.played, equals(1));
      expect(rowA.won, equals(1));
      expect(rowA.points, equals(3));
      expect(rowA.goalsFor, equals(3));
      expect(rowA.goalsAgainst, equals(1));
      expect(rowA.goalDifference, equals(2));
      expect(rowA.rank, equals(1));

      expect(rowB.played, equals(1));
      expect(rowB.lost, equals(1));
      expect(rowB.points, equals(0));
      expect(rowB.goalDifference, equals(-2));
      expect(rowB.rank, equals(3));
    });

    test('Draw match awards 1 point each', () {
      final matchDraw = TournamentMatch(
        id: 'm1',
        tournamentId: 't1',
        round: 1,
        roundName: 'Vòng 1',
        homeTeamId: 'team_A',
        homeTeamName: 'FC Sao Vàng',
        awayTeamId: 'team_B',
        awayTeamName: 'FC Rồng Đỏ',
        scheduledTime: DateTime.now(),
        venue: 'Sân 1',
        status: MatchStatus.finished,
        homeScore: 2,
        awayScore: 2,
        isConfirmed: true,
      );

      final standings = StandingsCalculator.compute(
        teams: teams,
        matches: [matchDraw],
      );

      final rowA = standings.firstWhere((r) => r.teamId == 'team_A');
      final rowB = standings.firstWhere((r) => r.teamId == 'team_B');

      expect(rowA.points, equals(1));
      expect(rowA.drawn, equals(1));
      expect(rowB.points, equals(1));
      expect(rowB.drawn, equals(1));
    });

    test('Unconfirmed / Draft matches are NOT counted in standings', () {
      final unconfirmedMatch = TournamentMatch(
        id: 'm1',
        tournamentId: 't1',
        round: 1,
        roundName: 'Vòng 1',
        homeTeamId: 'team_A',
        homeTeamName: 'FC Sao Vàng',
        awayTeamId: 'team_B',
        awayTeamName: 'FC Rồng Đỏ',
        scheduledTime: DateTime.now(),
        venue: 'Sân 1',
        status: MatchStatus.finished,
        homeScore: 5,
        awayScore: 0,
        isConfirmed: false, // Draft only!
      );

      final standings = StandingsCalculator.compute(
        teams: teams,
        matches: [unconfirmedMatch],
      );

      final rowA = standings.firstWhere((r) => r.teamId == 'team_A');
      expect(rowA.played, equals(0));
      expect(rowA.points, equals(0));
    });

    test('Head-to-head tie breaker resolves rank between teams with equal points and GD', () {
      // Team A beats Team B 1-0 (A: 3 pts, +1 GD)
      // Team B beats Team C 2-0 (B: 3 pts, +1 GD)
      // Team C beats Team A 2-0 (C: 3 pts, 0 GD)
      // Let's test a simple 2-team tie:
      // Match 1: Team A vs Team B -> Team A wins 2-1
      // Match 2: Team A vs Team C -> Team C wins 1-0 (A has 3 pts, GD 0, GF 2)
      // Match 3: Team B vs Team C -> Team B wins 1-0 (B has 3 pts, GD 0, GF 2)
      // Both Team A and Team B have 3 pts, 0 GD, 2 GF.
      // But in Match 1 (Head-to-head), Team A beat Team B 2-1!
      final m1 = TournamentMatch(
        id: 'm1',
        tournamentId: 't1',
        round: 1,
        roundName: 'R1',
        homeTeamId: 'team_A',
        homeTeamName: 'FC Sao Vàng',
        awayTeamId: 'team_B',
        awayTeamName: 'FC Rồng Đỏ',
        scheduledTime: DateTime.now(),
        venue: 'Sân 1',
        status: MatchStatus.finished,
        homeScore: 2,
        awayScore: 1,
        isConfirmed: true,
      );
      final m2 = TournamentMatch(
        id: 'm2',
        tournamentId: 't1',
        round: 2,
        roundName: 'R2',
        homeTeamId: 'team_A',
        homeTeamName: 'FC Sao Vàng',
        awayTeamId: 'team_C',
        awayTeamName: 'FC Đại Bàng',
        scheduledTime: DateTime.now(),
        venue: 'Sân 1',
        status: MatchStatus.finished,
        homeScore: 0,
        awayScore: 1,
        isConfirmed: true,
      );
      final m3 = TournamentMatch(
        id: 'm3',
        tournamentId: 't1',
        round: 3,
        roundName: 'R3',
        homeTeamId: 'team_B',
        homeTeamName: 'FC Rồng Đỏ',
        awayTeamId: 'team_C',
        awayTeamName: 'FC Đại Bàng',
        scheduledTime: DateTime.now(),
        venue: 'Sân 1',
        status: MatchStatus.finished,
        homeScore: 1,
        awayScore: 0,
        isConfirmed: true,
      );

      final standings = StandingsCalculator.compute(
        teams: teams,
        matches: [m1, m2, m3],
      );

      final rowA = standings.firstWhere((r) => r.teamId == 'team_A');
      final rowB = standings.firstWhere((r) => r.teamId == 'team_B');

      // Both have 3 pts, 0 GD, 2 GF
      expect(rowA.points, equals(rowB.points));
      expect(rowA.goalDifference, equals(rowB.goalDifference));
      expect(rowA.goalsFor, equals(rowB.goalsFor));

      // Team A should rank higher than Team B due to Head-to-Head win!
      expect(rowA.rank < rowB.rank, isTrue);
    });
  });
}

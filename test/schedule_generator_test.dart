import 'package:flutter_test/flutter_test.dart';
import 'package:ballhub/features/tournament/domain/models/tournament.dart';
import 'package:ballhub/features/tournament/domain/models/tournament_team.dart';
import 'package:ballhub/features/tournament/domain/models/match.dart';
import 'package:ballhub/features/tournament/domain/services/schedule_generator.dart';

void main() {
  group('ScheduleGenerator Tests', () {
    late Tournament tournament;
    late List<TournamentTeam> fourTeams;

    setUp(() {
      tournament = Tournament(
        id: 'test_tour_01',
        name: 'Giải bóng đá Thử nghiệm',
        description: 'Test',
        location: 'Sân 1',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 10),
        registrationDeadline: DateTime(2026, 10, 25),
        maxTeams: 8,
        format: TournamentFormat.roundRobinSingle,
        status: TournamentStatus.inProgress,
        organizerId: 'org_01',
        organizerName: 'BTC',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      fourTeams = [
        TournamentTeam(
          id: 'reg_1',
          tournamentId: 'test_tour_01',
          teamId: 'team_A',
          teamName: 'Đội A',
          captainId: 'c1',
          captainName: 'Cap A',
          captainPhone: '0901',
          captainEmail: 'a@mail.com',
          status: RegistrationStatus.approved,
          registeredAt: DateTime(2026, 10, 2),
        ),
        TournamentTeam(
          id: 'reg_2',
          tournamentId: 'test_tour_01',
          teamId: 'team_B',
          teamName: 'Đội B',
          captainId: 'c2',
          captainName: 'Cap B',
          captainPhone: '0902',
          captainEmail: 'b@mail.com',
          status: RegistrationStatus.approved,
          registeredAt: DateTime(2026, 10, 3),
        ),
        TournamentTeam(
          id: 'reg_3',
          tournamentId: 'test_tour_01',
          teamId: 'team_C',
          teamName: 'Đội C',
          captainId: 'c3',
          captainName: 'Cap C',
          captainPhone: '0903',
          captainEmail: 'c@mail.com',
          status: RegistrationStatus.approved,
          registeredAt: DateTime(2026, 10, 4),
        ),
        TournamentTeam(
          id: 'reg_4',
          tournamentId: 'test_tour_01',
          teamId: 'team_D',
          teamName: 'Đội D',
          captainId: 'c4',
          captainName: 'Cap D',
          captainPhone: '0904',
          captainEmail: 'd@mail.com',
          status: RegistrationStatus.approved,
          registeredAt: DateTime(2026, 10, 5),
        ),
      ];
    });

    test('Single Round Robin with 4 teams produces 3 rounds and 6 matches', () {
      final matches = ScheduleGenerator.generate(
        tournament: tournament,
        approvedTeams: fourTeams,
      );

      expect(matches.length, equals(6));

      // Mỗi vòng đấu phải có đúng 2 trận đấu
      final round1 = matches.where((m) => m.round == 1).toList();
      final round2 = matches.where((m) => m.round == 2).toList();
      final round3 = matches.where((m) => m.round == 3).toList();

      expect(round1.length, equals(2));
      expect(round2.length, equals(2));
      expect(round3.length, equals(2));

      // Trong bất kỳ vòng đấu đơn nào, không có đội nào phải thi đấu 2 lần
      for (final r in [round1, round2, round3]) {
        final teamsInRound = <String>{};
        for (final m in r) {
          expect(teamsInRound.contains(m.homeTeamId), isFalse);
          expect(teamsInRound.contains(m.awayTeamId), isFalse);
          teamsInRound.add(m.homeTeamId);
          teamsInRound.add(m.awayTeamId);
        }
      }
    });

    test(
      'Round Robin with odd number of teams (3 teams) handles byes correctly',
      () {
        final threeTeams = fourTeams.sublist(0, 3);
        final matches = ScheduleGenerator.generate(
          tournament: tournament,
          approvedTeams: threeTeams,
        );

        // Công thức tính số trận với N=3: N*(N-1)/2 = 3*2/2 = 3 trận
        expect(matches.length, equals(3));

        // Không có đội giả định hoặc giá trị rỗng trong danh sách trận đấu
        for (final m in matches) {
          expect(m.homeTeamId.isNotEmpty, isTrue);
          expect(m.awayTeamId.isNotEmpty, isTrue);
          expect(m.homeTeamId, isNot(equals(m.awayTeamId)));
        }
      },
    );

    test('Double Round Robin generates home and away legs (12 matches for 4 teams)', () {
      final doubleTournament = tournament.copyWith(
        format: TournamentFormat.roundRobinDouble,
      );
      final matches = ScheduleGenerator.generate(
        tournament: doubleTournament,
        approvedTeams: fourTeams,
      );

      expect(matches.length, equals(12));
    });

    test('Preserves confirmed matches during re-generation (Safe Merge)', () {
      final initialMatches = ScheduleGenerator.generate(
        tournament: tournament,
        approvedTeams: fourTeams,
      );

      // Giả sử trận đấu đầu tiên đã diễn ra và được xác nhận chính thức
      final playedMatch = initialMatches[0].copyWith(
        homeScore: 2,
        awayScore: 1,
        status: MatchStatus.finished,
        isConfirmed: true,
      );

      final matchesWithResult = List<TournamentMatch>.from(initialMatches);
      matchesWithResult[0] = playedMatch;

      // Tiến hành tạo lại lịch thi đấu
      final regenerated = ScheduleGenerator.generate(
        tournament: tournament,
        approvedTeams: fourTeams,
        existingMatches: matchesWithResult,
      );

      // Kiểm tra xác nhận rằng trận đấu đã thi đấu vẫn giữ nguyên tỷ số và trạng thái xác nhận
      final preservedMatch = regenerated.firstWhere(
        (m) =>
            m.homeTeamId == playedMatch.homeTeamId &&
            m.awayTeamId == playedMatch.awayTeamId,
      );

      expect(preservedMatch.homeScore, equals(2));
      expect(preservedMatch.awayScore, equals(1));
      expect(preservedMatch.isConfirmed, isTrue);
    });
  });
}

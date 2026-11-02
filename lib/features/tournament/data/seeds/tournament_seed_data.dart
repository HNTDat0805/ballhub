import '../../domain/models/match.dart';
import '../../domain/models/standings_row.dart';
import '../../domain/models/tournament.dart';
import '../../domain/models/tournament_team.dart';

/// Dữ liệu mẫu khởi tạo (Seed / Mock Data) cho phân hệ Giải đấu (Tournament).
///
/// Tách biệt hoàn toàn khỏi logic Repository và Controller để:
/// 1. Giữ code nghiệp vụ sạch sẽ, dễ bảo trì.
/// 2. Đảm bảo dữ liệu mẫu chỉ phục vụ môi trường chạy thử (demo/offline) hoặc kiểm thử tự động.
/// 3. Tuyệt đối không để dữ liệu mẫu rò rỉ hay can thiệp vào các giải đấu thực tế do người dùng tạo ra.
class TournamentSeedData {
  /// ID của giải đấu demo hệ thống duy nhất được phép sử dụng dữ liệu mẫu khi mất kết nối mạng.
  static const String sampleDemoTournamentId = 'tour_ballhub_cup_2026';

  /// Danh sách các giải đấu mẫu dùng cho demo hoặc khi ứng dụng chạy ngoại tuyến
  static List<Tournament> getSampleTournaments() {
    return [
      Tournament(
        id: sampleDemoTournamentId,
        name: 'Ballhub Super Cup 2026',
        description:
            'Giải bóng đá phong trào thường niên Ballhub tranh cúp vô địch.',
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
        description:
            'Giải đấu giao lưu các câu lạc bộ bóng đá phong trào miền Bắc.',
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
      Tournament(
        id: 'tour_da_nang_open',
        name: 'Đà Nẵng City Champions 2026',
        description: 'Giải bóng đá các câu lạc bộ miền Trung cúp Tuyên Sơn.',
        location: 'Làng Thể Thao Tuyên Sơn, Đà Nẵng',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 10)),
        registrationDeadline: DateTime.now().subtract(const Duration(days: 5)),
        maxTeams: 8,
        format: TournamentFormat.roundRobinDouble,
        status: TournamentStatus.inProgress,
        organizerId: 'user_organizer_01',
        organizerName: 'Ban Tổ Chức Đà Nẵng',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Tournament(
        id: 'tour_futsal_saigon',
        name: 'Cúp Vô Địch Sân 7 Sài Gòn',
        description:
            'Giải đấu sân 7 truyền thống các đội bóng phong trào TP.HCM.',
        location: 'Sân bóng Gia Định, TP. Hồ Chí Minh',
        startDate: DateTime.now().subtract(const Duration(days: 20)),
        endDate: DateTime.now().subtract(const Duration(days: 2)),
        registrationDeadline: DateTime.now().subtract(const Duration(days: 25)),
        maxTeams: 16,
        format: TournamentFormat.knockout,
        status: TournamentStatus.completed,
        organizerId: 'user_organizer_01',
        organizerName: 'Ban Tổ Chức Ballhub',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Danh sách các đội bóng mẫu (chỉ dùng cho giải đấu demo)
  static List<TournamentTeam> getSampleTeams(String tournamentId) {
    final now = DateTime.now();
    return [
      TournamentTeam(
        id: 'tt_01',
        tournamentId: tournamentId,
        teamId: 'team_sao_vang',
        teamName: 'FC Sao Vàng',
        logoUrl: '',
        captainId: 'captain_01',
        captainName: 'Nguyễn Văn Đạt',
        captainPhone: '0901234567',
        captainEmail: 'dat@ballhub.com',
        membersCount: 14,
        status: RegistrationStatus.approved,
        registeredAt: now.subtract(const Duration(days: 4)),
      ),
      TournamentTeam(
        id: 'tt_02',
        tournamentId: tournamentId,
        teamId: 'team_pho_nui',
        teamName: 'FC Phố Núi',
        logoUrl: '',
        captainId: 'captain_02',
        captainName: 'Trần Văn Nam',
        captainPhone: '0912345678',
        captainEmail: 'nam@ballhub.com',
        membersCount: 16,
        status: RegistrationStatus.approved,
        registeredAt: now.subtract(const Duration(days: 4)),
      ),
      TournamentTeam(
        id: 'tt_03',
        tournamentId: tournamentId,
        teamId: 'team_con_loc_do',
        teamName: 'FC Cơn Lốc Đỏ',
        logoUrl: '',
        captainId: 'captain_03',
        captainName: 'Lê Hoàng Minh',
        captainPhone: '0987654321',
        captainEmail: 'minh@ballhub.com',
        membersCount: 15,
        status: RegistrationStatus.approved,
        registeredAt: now.subtract(const Duration(days: 3)),
      ),
      TournamentTeam(
        id: 'tt_04',
        tournamentId: tournamentId,
        teamId: 'team_song_han',
        teamName: 'FC Sông Hàn Đà Nẵng',
        logoUrl: '',
        captainId: 'captain_04',
        captainName: 'Phan Đình Tùng',
        captainPhone: '0933445566',
        captainEmail: 'tung@ballhub.com',
        membersCount: 14,
        status: RegistrationStatus.approved,
        registeredAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  /// Danh sách các trận đấu mẫu (chỉ dùng cho giải đấu demo)
  static List<TournamentMatch> getSampleMatches(String tournamentId) {
    final now = DateTime.now();
    return [
      TournamentMatch(
        id: 'match_01',
        tournamentId: tournamentId,
        round: 1,
        roundName: 'Vòng 1',
        homeTeamId: 'team_sao_vang',
        homeTeamName: 'FC Sao Vàng',
        awayTeamId: 'team_con_loc_do',
        awayTeamName: 'FC Cơn Lốc Đỏ',
        scheduledTime: now.subtract(const Duration(hours: 3)),
        venue: 'Sân bóng Gia Định',
        status: MatchStatus.finished,
        homeScore: 3,
        awayScore: 1,
        isConfirmed: true,
      ),
      TournamentMatch(
        id: 'match_02',
        tournamentId: tournamentId,
        round: 1,
        roundName: 'Vòng 1',
        homeTeamId: 'team_song_han',
        homeTeamName: 'FC Sông Hàn Đà Nẵng',
        awayTeamId: 'team_pho_nui',
        awayTeamName: 'FC Phố Núi',
        scheduledTime: now.subtract(const Duration(minutes: 30)),
        venue: 'Làng Thể Thao Tuyên Sơn',
        status: MatchStatus.inProgress,
        homeScore: 2,
        awayScore: 2,
        isConfirmed: false,
      ),
      TournamentMatch(
        id: 'match_03',
        tournamentId: tournamentId,
        round: 2,
        roundName: 'Vòng 2',
        homeTeamId: 'team_sao_vang',
        homeTeamName: 'FC Sao Vàng',
        awayTeamId: 'team_song_han',
        awayTeamName: 'FC Sông Hàn Đà Nẵng',
        scheduledTime: now.add(const Duration(days: 1, hours: 2)),
        venue: 'Sân bóng Gia Định',
        status: MatchStatus.scheduled,
        isConfirmed: false,
      ),
      TournamentMatch(
        id: 'match_04',
        tournamentId: tournamentId,
        round: 2,
        roundName: 'Vòng 2',
        homeTeamId: 'team_pho_nui',
        homeTeamName: 'FC Phố Núi',
        awayTeamId: 'team_con_loc_do',
        awayTeamName: 'FC Cơn Lốc Đỏ',
        scheduledTime: now.add(const Duration(days: 2, hours: 3)),
        venue: 'Sân vận động Mỹ Đình',
        status: MatchStatus.scheduled,
        isConfirmed: false,
      ),
    ];
  }

  /// Bảng xếp hạng mẫu (chỉ dùng cho giải đấu demo)
  static List<StandingsRow> getSampleStandings(String tournamentId) {
    return const [
      StandingsRow(
        teamId: 'team_sao_vang',
        teamName: 'FC Sao Vàng',
        played: 1,
        won: 1,
        drawn: 0,
        lost: 0,
        goalsFor: 3,
        goalsAgainst: 1,
        goalDifference: 2,
        points: 3,
        rank: 1,
      ),
      StandingsRow(
        teamId: 'team_song_han',
        teamName: 'FC Sông Hàn Đà Nẵng',
        played: 1,
        won: 0,
        drawn: 1,
        lost: 0,
        goalsFor: 2,
        goalsAgainst: 2,
        goalDifference: 0,
        points: 1,
        rank: 2,
      ),
      StandingsRow(
        teamId: 'team_pho_nui',
        teamName: 'FC Phố Núi',
        played: 1,
        won: 0,
        drawn: 1,
        lost: 0,
        goalsFor: 2,
        goalsAgainst: 2,
        goalDifference: 0,
        points: 1,
        rank: 3,
      ),
      StandingsRow(
        teamId: 'team_con_loc_do',
        teamName: 'FC Cơn Lốc Đỏ',
        played: 1,
        won: 0,
        drawn: 0,
        lost: 1,
        goalsFor: 1,
        goalsAgainst: 3,
        goalDifference: -2,
        points: 0,
        rank: 4,
      ),
    ];
  }
}

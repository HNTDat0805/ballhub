import '../models/match.dart';
import '../models/standings_row.dart';
import '../models/tournament_team.dart';

/// Bộ tính toán bảng xếp hạng giải đấu (Standings Calculator).
///
/// Hoạt động như một hàm thuần túy (Pure Function), tính toán hoàn toàn xác định
/// dựa trên các trận đấu đã có kết quả chính thức:
/// - Thắng: 3 điểm, Hòa: 1 điểm, Thua: 0 điểm.
/// - Tiêu chí xếp hạng ưu tiên:
///   1. Tổng điểm (Points)
///   2. Hiệu số bàn thắng - thua (Goal Difference)
///   3. Tổng số bàn thắng ghi được (Goals For)
///   4. Thành tích đối đầu trực tiếp (Head-to-Head) giữa các đội bằng điểm
///   5. Tên đội theo thứ tự bảng chữ cái (Alphabetical)
class StandingsCalculator {
  /// Tính toán bảng xếp hạng giải đấu từ danh sách đội bóng và các trận đấu chính thức.
  static List<StandingsRow> compute({
    required List<TournamentTeam> teams,
    required List<TournamentMatch> matches,
  }) {
    // 1. Khởi tạo bảng thống kê cho từng đội bóng đã duyệt
    final stats = <String, _MutableTeamStats>{};
    for (final team in teams) {
      stats[team.teamId] = _MutableTeamStats(
        teamId: team.teamId,
        teamName: team.teamName,
        logoUrl: team.logoUrl,
      );
    }

    // 2. Tích lũy kết quả từ những trận đã có kết quả chính thức (official confirmed)
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

    // 3. Chuyển thành danh sách và sắp xếp theo quy chuẩn phân hạng bóng đá chính thức (FIFA/V-League)
    final list = stats.values.toList();

    list.sort((a, b) {
      // Tiêu chí 1: Tổng điểm (Points) - đội nhiều điểm hơn xếp trên
      final ptsCompare = b.points.compareTo(a.points);
      if (ptsCompare != 0) return ptsCompare;

      // Tiêu chí 2: Hiệu số bàn thắng - bàn thua (Goal Difference)
      final gdCompare = b.goalDifference.compareTo(a.goalDifference);
      if (gdCompare != 0) return gdCompare;

      // Tiêu chí 3: Tổng số bàn thắng ghi được (Goals For)
      final gfCompare = b.goalsFor.compareTo(a.goalsFor);
      if (gfCompare != 0) return gfCompare;

      // Tiêu chí 4: Thành tích đối đầu trực tiếp (Head-to-Head) giữa 2 đội bằng điểm
      final h2hCompare = _compareHeadToHead(
        a.teamId,
        b.teamId,
        confirmedMatches,
      );
      if (h2hCompare != 0) return h2hCompare;

      // Tiêu chí dự phòng cuối cùng: Xếp theo thứ tự bảng chữ cái tên đội
      return a.teamName.compareTo(b.teamName);
    });

    // 4. Gán số thứ tự hạng (Rank bắt đầu từ 1)
    final standings = <StandingsRow>[];
    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      standings.add(
        StandingsRow(
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
        ),
      );
    }

    return standings;
  }

  /// So sánh thành tích đối đầu trực tiếp giữa 2 đội bóng có cùng điểm số.
  /// Đội nào giành nhiều điểm hơn trong các trận đối đầu trực tiếp sẽ được xếp trên.
  static int _compareHeadToHead(
    String teamA,
    String teamB,
    List<TournamentMatch> matches,
  ) {
    int pointsA = 0;
    int pointsB = 0;

    // 1. Duyệt qua tất cả trận đấu và lọc các trận đối đầu trực tiếp giữa Team A và Team B
    for (final m in matches) {
      if ((m.homeTeamId == teamA && m.awayTeamId == teamB) ||
          (m.homeTeamId == teamB && m.awayTeamId == teamA)) {
        final scoreA = (m.homeTeamId == teamA) ? m.homeScore! : m.awayScore!;
        final scoreB = (m.homeTeamId == teamB) ? m.homeScore! : m.awayScore!;

        // 2. Tính điểm đối đầu (Thắng: 3đ, Hòa: 1đ, Thua: 0đ)
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

    // 3. Trả về so sánh giảm dần theo điểm đối đầu
    return pointsB.compareTo(pointsA);
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

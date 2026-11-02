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
    // 1. Kiểm tra nếu số đội ít hơn 2 thì không thể sinh lịch thi đấu
    if (approvedTeams.length < 2) {
      return existingMatches;
    }

    // 2. Lọc các trận đấu đã có kết quả chính thức để bảo vệ không bị ghi đè mất tỷ số
    final confirmedMatches = existingMatches
        .where((m) => m.isOfficialResult)
        .toList();
    final hasExistingConfirmed = confirmedMatches.isNotEmpty;

    // 3. Điều phối thuật toán sinh lịch theo thể thức đăng ký của giải đấu
    List<TournamentMatch> newMatches;
    switch (tournament.format) {
      case TournamentFormat.roundRobinSingle:
        // Vòng tròn 1 lượt: mỗi đội gặp nhau đúng 1 lần
        newMatches = _generateRoundRobin(
          tournament: tournament,
          teams: approvedTeams,
          isDouble: false,
          venue: defaultVenue,
        );
        break;
      case TournamentFormat.roundRobinDouble:
        // Vòng tròn 2 lượt: thi đấu cả lượt đi và lượt về (sân nhà - sân khách)
        newMatches = _generateRoundRobin(
          tournament: tournament,
          teams: approvedTeams,
          isDouble: true,
          venue: defaultVenue,
        );
        break;
      case TournamentFormat.knockout:
        // Loại trực tiếp (Knockout): thua là bị loại
        newMatches = _generateKnockout(
          tournament: tournament,
          teams: approvedTeams,
          venue: defaultVenue,
        );
        break;
    }

    // 4. Cơ chế hợp nhất an toàn (Safe Merge): giữ nguyên các trận đấu đã hoàn thành kết quả
    if (hasExistingConfirmed) {
      final merged = <TournamentMatch>[];
      for (final generated in newMatches) {
        // Tìm xem trận đấu này đã có kết quả trước đó chưa
        final existing = existingMatches.firstWhere(
          (e) =>
              (e.homeTeamId == generated.homeTeamId &&
                  e.awayTeamId == generated.awayTeamId) ||
              (e.round == generated.round &&
                  e.homeTeamId == generated.homeTeamId &&
                  e.awayTeamId == generated.awayTeamId),
          orElse: () => generated,
        );
        merged.add(existing); // Giữ lại bản ghi cũ hoặc dùng bản ghi mới
      }
      return merged;
    }

    return newMatches; // Trả về danh sách trận đấu mới hoàn toàn
  }

  /// Thuật toán Berger xoay vòng tròn (Circle Method) tiêu chuẩn quốc tế.
  /// Xử lý trơn tru cả số lượng đội chẵn và lẻ (tự động thêm slot nghỉ BYE không sinh trận ảo).
  static List<TournamentMatch> _generateRoundRobin({
    required Tournament tournament,
    required List<TournamentTeam> teams,
    required bool isDouble,
    required String venue,
  }) {
    final matches = <TournamentMatch>[];
    final teamList = List<TournamentTeam?>.from(teams);

    // 1. Nếu số đội lẻ, thêm 1 slot null làm đội nghỉ lượt (BYE)
    final isOdd = teamList.length % 2 != 0;
    if (isOdd) {
      teamList.add(null);
    }

    // 2. Tính toán các hằng số vòng đấu
    final n = teamList.length; // Tổng số vị trí trong vòng tròn
    final totalRounds = n - 1; // Số vòng đấu của 1 lượt
    final matchesPerRound = n ~/ 2; // Số cặp đấu trong mỗi vòng

    // Thiết lập giờ bắt đầu thi đấu từ 8h sáng ngày khai mạc
    DateTime matchDateTime = tournament.startDate.copyWith(hour: 8, minute: 0);

    // 3. Sinh các cặp đấu cho Lượt đi (First Leg)
    for (int round = 0; round < totalRounds; round++) {
      final roundNumber = round + 1;
      final roundName = 'Vòng $roundNumber';

      for (int matchIdx = 0; matchIdx < matchesPerRound; matchIdx++) {
        final team1 = teamList[matchIdx];
        final team2 = teamList[n - 1 - matchIdx];

        // Nếu một trong hai đội là null, nghĩa là đội còn lại được nghỉ ở vòng này
        if (team1 == null || team2 == null) {
          continue;
        }

        // Đổi xen kẽ sân nhà / sân khách theo từng vòng để đảm bảo tính công bằng
        final homeTeam = (round % 2 == 0) ? team1 : team2;
        final awayTeam = (round % 2 == 0) ? team2 : team1;

        // Mã định danh trận đấu duy nhất
        final matchId =
            '${tournament.id}_r${roundNumber}_m${matchIdx + 1}_${homeTeam.id}_${awayTeam.id}';

        // Xếp lịch thi đấu: mỗi trận cách nhau 2 tiếng trong ngày thi đấu của vòng
        final scheduledTime = matchDateTime.add(
          Duration(days: round, hours: matchIdx * 2),
        );

        matches.add(
          TournamentMatch(
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
          ),
        );
      }

      // Xoay vòng theo thuật toán Berger: cố định vị trí teamList[0], xoay chuyển các đội còn lại
      final last = teamList.removeLast();
      teamList.insert(1, last);
    }

    // 4. Sinh các cặp đấu cho Lượt về (Second Leg) nếu là thể thức vòng tròn 2 lượt
    if (isDouble) {
      final firstLegCount = matches.length;
      final returnStartDay =
          totalRounds + 2; // Lượt về bắt đầu sau lượt đi nghỉ 2 ngày

      for (int i = 0; i < firstLegCount; i++) {
        final original = matches[i];
        final returnRoundNumber = original.round + totalRounds;
        final returnRoundName = 'Vòng $returnRoundNumber (Lượt về)';
        final returnScheduledTime = original.scheduledTime.add(
          Duration(days: returnStartDay),
        );
        // Đảo ngược sân nhà và sân khách cho lượt về
        final returnMatchId =
            '${tournament.id}_r${returnRoundNumber}_return_${original.awayTeamId}_${original.homeTeamId}';

        matches.add(
          TournamentMatch(
            id: returnMatchId,
            tournamentId: tournament.id,
            round: returnRoundNumber,
            roundName: returnRoundName,
            homeTeamId: original
                .awayTeamId, // Đổi đội khách lượt đi thành đội nhà lượt về
            homeTeamName: original.awayTeamName,
            awayTeamId: original
                .homeTeamId, // Đổi đội nhà lượt đi thành đội khách lượt về
            awayTeamName: original.homeTeamName,
            scheduledTime: returnScheduledTime,
            venue: venue,
            status: MatchStatus.scheduled,
          ),
        );
      }
    }

    return matches; // Trả về toàn bộ danh sách các trận đấu vòng tròn
  }

  /// Sinh các cặp đấu cho vòng mở màn của thể thức Loại trực tiếp (Single Elimination Knockout).
  static List<TournamentMatch> _generateKnockout({
    required Tournament tournament,
    required List<TournamentTeam> teams,
    required String venue,
  }) {
    final matches = <TournamentMatch>[];
    final teamCount = teams.length;

    // 1. Xác định quy mô nhánh đấu là lũy thừa của 2 gần nhất (2, 4, 8, 16...)
    int bracketSize = 2;
    while (bracketSize < teamCount) {
      bracketSize *= 2;
    }

    // 2. Xác định tên vòng đấu dựa vào kích thước nhánh
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

    // 3. Ghép cặp đối đầu đối xứng (đội đầu bảng gặp đội cuối bảng)
    for (int i = 0; i < teamCount ~/ 2; i++) {
      final homeTeam = teams[i];
      final awayTeam = teams[teamCount - 1 - i];
      final matchId =
          '${tournament.id}_ko1_m${i + 1}_${homeTeam.id}_${awayTeam.id}';
      final scheduledTime = matchDateTime.add(Duration(hours: i * 2));

      matches.add(
        TournamentMatch(
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
        ),
      );
    }

    return matches; // Trả về danh sách trận đấu knockout vòng 1
  }
}

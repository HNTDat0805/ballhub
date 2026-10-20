import '../domain/models/match.dart';
import '../domain/models/match_audit.dart';
import '../domain/models/standings_row.dart';
import '../domain/models/tournament.dart';
import '../domain/models/tournament_team.dart';

/// Hợp đồng giao tiếp (Repository Interface) cho phân hệ quản lý giải đấu Ballhub.
///
/// Tuân thủ nguyên tắc Dependency Inversion (D trong SOLID):
/// - Tầng Presentation chỉ phụ thuộc vào trừu tượng [TournamentRepository].
/// - Tầng Data triển khai thực tế thông qua [ApiTournamentRepository] (gọi REST API).
abstract class TournamentRepository {
  /// Theo dõi danh sách giải đấu theo thời gian thực hoặc qua luồng cập nhật
  Stream<List<Tournament>> watchTournaments();

  /// Lấy thông tin chi tiết một giải đấu theo mã ID
  Future<Tournament?> getTournament(String tournamentId);

  /// Tạo mới một giải đấu
  Future<void> createTournament(Tournament tournament);

  /// Cập nhật thông tin cấu hình giải đấu
  Future<void> updateTournament(Tournament tournament);

  /// Xóa giải đấu và các dữ liệu liên quan
  Future<void> deleteTournament(String tournamentId);

  /// Theo dõi danh sách các đội đăng ký tham gia giải đấu
  Stream<List<TournamentTeam>> watchTeams(String tournamentId);

  /// Đăng ký đội bóng mới tham gia giải
  Future<void> registerTeam(TournamentTeam team);

  /// Phê duyệt hoặc từ chối đội bóng đăng ký
  Future<void> updateTeamStatus(
    String tournamentId,
    String teamRegistrationId,
    RegistrationStatus status, {
    String? note,
    String? reviewedBy,
  });

  /// Theo dõi danh sách lịch thi đấu các trận của giải
  Stream<List<TournamentMatch>> watchMatches(String tournamentId);

  /// Lưu danh sách các trận đấu
  Future<void> saveMatches(String tournamentId, List<TournamentMatch> matches);

  /// Yêu cầu Backend tự động sinh lịch thi đấu theo thể thức
  Future<void> generateSchedule(String tournamentId, {String venue = 'Sân vận động chính'});

  /// Cập nhật kết quả trận đấu, ghi log audit và tự động tính lại bảng xếp hạng
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

  /// Theo dõi bảng xếp hạng giải đấu
  Stream<List<StandingsRow>> watchStandings(String tournamentId);

  /// Yêu cầu tính toán lại và lưu bảng xếp hạng
  Future<void> recalculateAndSaveStandings(String tournamentId);

  /// Theo dõi lịch sử kiểm toán thay đổi tỷ số trận đấu
  Stream<List<MatchAudit>> watchMatchAuditLogs(String tournamentId);
}

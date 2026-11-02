import 'package:flutter/foundation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../services/province_service.dart';
import '../../data/tournament_repository.dart';
import '../../domain/models/match.dart';
import '../../domain/models/standings_row.dart';
import '../../domain/models/tournament.dart';
import '../../domain/models/tournament_team.dart';

/// Quản lý trạng thái giao diện (Presentation State Controller) của phân hệ giải đấu.
///
/// Chịu trách nhiệm:
/// 1. Quản lý bộ lọc tìm kiếm (search query), bộ lọc trạng thái (status filter).
/// 2. Quản lý trạng thái đang tải (isLoading) và thông báo lỗi (errorMessage).
/// 3. Gọi các hành vi nghiệp vụ thông qua [TournamentRepository] và cập nhật UI qua `notifyListeners()`.
class TournamentController extends ChangeNotifier {
  final TournamentRepository repository;

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  TournamentStatus? _selectedStatusFilter;
  String? _selectedCityFilter;
  TournamentFormat? _selectedFormatFilter;

  TournamentController({required this.repository});

  /// Trạng thái đang thực thi tác vụ mạng hoặc bất đồng bộ
  bool get isLoading => _isLoading;

  /// Thông báo lỗi gần nhất cần hiển thị lên giao diện (nếu có)
  String? get errorMessage => _errorMessage;

  /// Từ khóa tìm kiếm giải đấu theo tên hoặc địa điểm
  String get searchQuery => _searchQuery;

  /// Bộ lọc trạng thái giải đấu đang được chọn
  TournamentStatus? get selectedStatusFilter => _selectedStatusFilter;

  /// Bộ lọc thành phố / địa điểm
  String? get selectedCityFilter => _selectedCityFilter;

  /// Bộ lọc thể thức thi đấu
  TournamentFormat? get selectedFormatFilter => _selectedFormatFilter;

  /// Đặt từ khóa tìm kiếm giải đấu
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Đặt bộ lọc trạng thái giải đấu
  void setStatusFilter(TournamentStatus? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  /// Đặt bộ lọc thành phố / địa phương
  void setCityFilter(String? city) {
    _selectedCityFilter = city;
    notifyListeners();
  }

  /// Đặt bộ lọc thể thức thi đấu
  void setFormatFilter(TournamentFormat? format) {
    _selectedFormatFilter = format;
    notifyListeners();
  }

  /// Xóa toàn bộ bộ lọc về mặc định
  void resetFilters() {
    _searchQuery = '';
    _selectedStatusFilter = null;
    _selectedCityFilter = null;
    _selectedFormatFilter = null;
    notifyListeners();
  }

  /// Xóa thông báo lỗi hiện tại
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Lắng nghe luồng danh sách giải đấu theo thời gian thực và áp dụng bộ lọc client-side (từ khóa, trạng thái, địa điểm, thể thức)
  Stream<List<Tournament>> watchTournaments() {
    return repository.watchTournaments().map((list) {
      return list.where((t) {
        // 1. Kiểm tra từ khóa tìm kiếm theo tên giải hoặc địa chỉ
        final matchesQuery =
            _searchQuery.isEmpty ||
            t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.location.toLowerCase().contains(_searchQuery.toLowerCase());

        // 2. Kiểm tra bộ lọc trạng thái (mở đăng ký, đang diễn ra, v.v.)
        final matchesStatus =
            _selectedStatusFilter == null || t.status == _selectedStatusFilter;

        // 3. Kiểm tra bộ lọc địa điểm tỉnh/thành phố (hỗ trợ không dấu tiếng Việt và tìm kiếm theo quận/huyện)
        bool matchesCity = true;
        if (_selectedCityFilter != null && _selectedCityFilter!.isNotEmpty) {
          final filterNorm = ProvinceService.removeAccents(
            _selectedCityFilter!.toLowerCase(),
          );
          final locNorm = ProvinceService.removeAccents(
            t.location.toLowerCase(),
          );
          matchesCity =
              locNorm.contains(filterNorm) || filterNorm.contains(locNorm);
          if (!matchesCity) {
            final districts = ProvinceService.getDistricts(
              _selectedCityFilter!,
            );
            matchesCity = districts.any((d) {
              final dNorm = ProvinceService.removeAccents(d.toLowerCase());
              return locNorm.contains(dNorm) || dNorm.contains(locNorm);
            });
          }
        }

        // 4. Kiểm tra bộ lọc thể thức thi đấu
        final matchesFormat =
            _selectedFormatFilter == null || t.format == _selectedFormatFilter;

        return matchesQuery && matchesStatus && matchesCity && matchesFormat;
      }).toList();
    });
  }

  /// Lắng nghe danh sách các đội bóng đăng ký tham gia giải đấu theo tournamentId
  Stream<List<TournamentTeam>> watchTeams(String tournamentId) {
    return repository.watchTeams(tournamentId);
  }

  /// Lắng nghe danh sách lịch thi đấu các trận của giải theo tournamentId
  Stream<List<TournamentMatch>> watchMatches(String tournamentId) {
    return repository.watchMatches(tournamentId);
  }

  /// Lắng nghe bảng xếp hạng của giải đấu theo tournamentId
  Stream<List<StandingsRow>> watchStandings(String tournamentId) {
    return repository.watchStandings(tournamentId);
  }

  /// Chuyển đổi mã lỗi hệ thống hoặc ApiException thành thông báo tiếng Việt dễ hiểu
  String _formatError(dynamic e) {
    if (e is ApiException) return e.message;
    final str = e.toString().replaceFirst('Exception: ', '');
    if (str.contains('is not a subtype of type')) {
      return 'Lỗi đồng bộ dữ liệu. Vui lòng thử lại hoặc khởi động lại ứng dụng.';
    }
    return str;
  }

  /// Tạo một giải đấu bóng đá mới
  Future<bool> createTournament(Tournament tournament) async {
    // 1. Kích hoạt loading và xóa lỗi cũ
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 2. Gọi repository thực thi tạo giải đấu
    try {
      await repository.createTournament(tournament);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể tạo giải đấu: ${_formatError(e)}';
      return false;
    } finally {
      // 3. Tắt trạng thái loading và báo UI cập nhật
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật thông tin chi tiết giải đấu
  Future<bool> updateTournament(Tournament tournament) async {
    // 1. Kích hoạt loading và xóa lỗi cũ
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 2. Gửi yêu cầu cập nhật tới repository
    try {
      await repository.updateTournament(tournament);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật giải đấu: ${_formatError(e)}';
      return false;
    } finally {
      // 3. Tắt trạng thái loading
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa giải đấu bóng đá khỏi hệ thống
  Future<bool> deleteTournament(String tournamentId) async {
    // 1. Kích hoạt loading và xóa lỗi cũ
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 2. Gọi lệnh xóa từ repository
    try {
      await repository.deleteTournament(tournamentId);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa giải đấu: ${_formatError(e)}';
      return false;
    } finally {
      // 3. Tắt trạng thái loading
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đăng ký đội bóng tham gia vào giải đấu
  Future<bool> registerTeam(TournamentTeam team) async {
    // 1. Kích hoạt loading và xóa lỗi cũ
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 2. Gửi đơn đăng ký qua repository
    try {
      await repository.registerTeam(team);
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      return false;
    } finally {
      // 3. Kết thúc loading
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Duyệt hoặc từ chối đơn đăng ký tham gia giải của một đội bóng
  Future<bool> updateTeamStatus(
    String tournamentId,
    String teamRegistrationId,
    RegistrationStatus status, {
    String? note,
    String? reviewedBy,
  }) async {
    // 1. Kích hoạt loading và xóa lỗi cũ
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 2. Cập nhật trạng thái duyệt đội (approved/rejected)
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
      _errorMessage = 'Không thể cập nhật trạng thái đội: ${_formatError(e)}';
      return false;
    } finally {
      // 3. Tắt trạng thái loading
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo lịch thi đấu tự động cho giải đấu dựa trên danh sách đội đã được duyệt
  Future<bool> generateSchedule({
    required Tournament tournament,
    required List<TournamentTeam> approvedTeams,
    required List<TournamentMatch> existingMatches,
    String venue = 'Sân vận động chính',
  }) async {
    // 1. Bật loading thông báo đang tính toán lịch
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 2. Gọi repository để sinh lịch thi đấu
    try {
      await repository.generateSchedule(tournament.id, venue: venue);
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi tạo lịch thi đấu: ${_formatError(e)}';
      return false;
    } finally {
      // 3. Tắt trạng thái loading
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật và xác nhận kết quả tỷ số trận đấu bóng đá
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
    // 1. Kích hoạt loading
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 2. Gửi kết quả tỷ số lên repository
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
      _errorMessage = 'Lỗi cập nhật tỷ số: ${_formatError(e)}';
      return false;
    } finally {
      // 3. Tắt trạng thái loading
      _isLoading = false;
      notifyListeners();
    }
  }
}

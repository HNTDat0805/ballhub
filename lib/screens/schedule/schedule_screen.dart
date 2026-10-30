import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/tournament/data/api_tournament_repository.dart';
import '../../features/tournament/data/tournament_repository.dart';
import '../../features/tournament/domain/models/match.dart';
import '../../features/tournament/domain/models/tournament.dart';
import '../../features/tournament/presentation/controllers/tournament_controller.dart';
import '../../features/tournament/presentation/screens/tournament_detail_screen.dart';

/// Màn hình Lịch thi đấu & Trung tâm kết quả (Page 11 - figma.pdf)
///
/// Bố cục chuẩn Figma Material 3 kết nối 100% Database:
/// - Header: `← Lịch thi đấu` + Icon bộ lọc
/// - Filter: `Tất cả trận`, `Đang diễn ra`, `Sắp tới`, `Đã xong`
/// - Chọn tháng thực tế theo thời gian hệ thống
/// - Danh sách các trận đấu thực tế từ các giải đấu trong Database
class ScheduleScreen extends StatefulWidget {
  final TournamentRepository? tournamentRepository;

  const ScheduleScreen({super.key, this.tournamentRepository});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final TournamentRepository _repository;
  int _selectedFilter = 0; // 0 = Tất cả, 1 = Sắp diễn ra, 2 = Đang diễn ra, 3 = Đã kết thúc
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _repository = widget.tournamentRepository ?? ApiTournamentRepository();
    _currentMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final monthStr = 'Tháng ${_currentMonth.month}, ${_currentMonth.year}';

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Lịch thi đấu'),
      ),
      body: Column(
        children: [
          // Filter Chips & Month Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Hàng chips bộ lọc
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(0, 'Tất cả trận'),
                      const SizedBox(width: 8),
                      _filterChip(1, 'Sắp diễn ra'),
                      const SizedBox(width: 8),
                      _filterChip(2, 'Đang thi đấu'),
                      const SizedBox(width: 8),
                      _filterChip(3, 'Đã kết thúc'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Tháng hiện tại
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          monthStr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20, color: AppTheme.textSecondary),
                      onPressed: () => setState(() {}),
                      tooltip: 'Làm mới',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),

          // Danh sách trận đấu từ Database
          Expanded(
            child: StreamBuilder<List<Tournament>>(
              stream: _repository.watchTournaments(),
              builder: (context, tourSnap) {
                if (tourSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
                  );
                }

                final tournaments = tourSnap.data ?? [];
                if (tournaments.isEmpty) {
                  return _buildEmptyState('Chưa có giải đấu hoặc lịch thi đấu nào.');
                }

                // Lấy các trận đấu từ giải đấu đầu tiên hoặc giải đang chạy
                final activeTour = tournaments.firstWhere(
                  (t) => t.status == TournamentStatus.inProgress,
                  orElse: () => tournaments.first,
                );

                return StreamBuilder<List<TournamentMatch>>(
                  stream: _repository.watchMatches(activeTour.id),
                  builder: (context, matchSnap) {
                    if (matchSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
                      );
                    }

                    var matches = matchSnap.data ?? [];

                    // Áp dụng bộ lọc
                    if (_selectedFilter == 1) {
                      matches = matches.where((m) => m.status == MatchStatus.scheduled).toList();
                    } else if (_selectedFilter == 2) {
                      matches = matches.where((m) => m.status == MatchStatus.inProgress).toList();
                    } else if (_selectedFilter == 3) {
                      matches = matches.where((m) => m.status == MatchStatus.finished).toList();
                    }

                    if (matches.isEmpty) {
                      return _buildEmptyState('Không có trận đấu nào trong danh mục này.');
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final m = matches[index];
                        return _buildDynamicMatchCard(m, activeTour);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 56,
              color: AppTheme.textMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final active = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryLightGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppTheme.primaryDarkGreen : AppTheme.borderColor,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? AppTheme.primaryDarkGreen : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicMatchCard(TournamentMatch match, Tournament tournament) {
    final home = match.homeTeamName.isNotEmpty ? match.homeTeamName : 'Đội nhà';
    final away = match.awayTeamName.isNotEmpty ? match.awayTeamName : 'Đội khách';
    final homeInitial = home.isNotEmpty ? home.substring(0, 1).toUpperCase() : 'A';
    final awayInitial = away.isNotEmpty ? away.substring(0, 1).toUpperCase() : 'B';

    final isLive = match.status == MatchStatus.inProgress;
    final isDone = match.status == MatchStatus.finished;

    final dt = match.scheduledTime;
    final dateStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} · ${dt.day}/${dt.month}/${dt.year}';

    Widget statusBadge;
    if (isLive) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 3, backgroundColor: Colors.white),
            SizedBox(width: 4),
            Text(
              'LIVE Đang đấu',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      );
    } else if (isDone) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Đã kết thúc',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
        ),
      );
    } else {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryLightGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 12, color: AppTheme.primaryDarkGreen),
            SizedBox(width: 4),
            Text(
              'Sắp diễn ra',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryDarkGreen),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? Colors.red.shade300 : AppTheme.borderColor,
          width: isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TournamentDetailScreen(
                tournamentId: tournament.id,
                controller: TournamentController(repository: _repository),
              ),
            ),
          );
        },
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                statusBadge,
                Text(
                  'Vòng ${match.round} · ${tournament.name}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Đội 1 - Tỷ số/Giờ - Đội 2
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryLightGreen,
                        child: Text(
                          homeInitial,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDarkGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          home,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Giữa: Tỷ số hoặc Giờ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    isLive || isDone
                        ? '${match.homeScore ?? 0}  -  ${match.awayScore ?? 0}'
                        : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isLive ? Colors.red : AppTheme.textPrimary,
                    ),
                  ),
                ),

                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          away,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Text(
                          awayInitial,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.borderColor),
            const SizedBox(height: 10),

            // Ngày giờ & Sân
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                Text(
                  'Chi tiết →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

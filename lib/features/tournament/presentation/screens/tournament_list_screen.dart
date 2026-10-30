import 'package:flutter/material.dart';
import '../../../../core/auth/auth_context.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tournament_repository.dart';
import '../../domain/models/tournament.dart';
import '../controllers/tournament_controller.dart';
import 'create_edit_tournament_screen.dart';
import 'tournament_detail_screen.dart';

/// Màn hình danh sách giải đấu bóng đá (Page 5 - figma.pdf)
///
/// Bố cục:
/// - Header: "Giải đấu" + Icon filter
/// - Search bar: "🔍 Tìm tên giải đấu"
/// - Filter chips: `Tất cả ⌄` (active), `7 người ⌄`, `Khu vực ⌄`
/// - Hàng tiêu đề phụ: "3 giải đấu tại TP.HCM" + Nút `+ Tạo giải` (pill xanh)
/// - Danh sách thẻ giải đấu:
///   1. Sài Gòn League 2026 (Đang diễn ra - Vòng 3 sắp diễn ra →)
///   2. Cúp Thủ Đức mở rộng (Đang nhận đội - Còn 2 suất)
///   3. Bình Thạnh Cup 2026 (Đã kết thúc - Xem kết quả →)
class TournamentListScreen extends StatefulWidget {
  final TournamentController controller;
  final TournamentRepository repository;

  const TournamentListScreen({
    super.key,
    required this.controller,
    required this.repository,
  });

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0; // 0 = Tất cả, 1 = 7 người, 2 = Khu vực

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEditTournamentScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return ListenableBuilder(
      listenable: Listenable.merge([controller, AuthContext.instance]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.surfaceColor,
          appBar: AppBar(
            title: const Text('Giải đấu'),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () {},
                tooltip: 'Bộ lọc nâng cao',
              ),
            ],
          ),
          body: Column(
            children: [
              // Thanh tìm kiếm
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm tên giải đấu',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              controller.setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => controller.setSearchQuery(val),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _filterChip(0, 'Tất cả ⌄'),
                    const SizedBox(width: 8),
                    _filterChip(1, '7 người ⌄'),
                    const SizedBox(width: 8),
                    _filterChip(2, 'Khu vực ⌄'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Hàng số lượng giải & Nút "+ Tạo giải"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Giải đấu bóng đá',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openCreateScreen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryDarkGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.add, size: 16, color: Colors.white),
                      label: const Text(
                        'Tạo giải',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Danh sách giải đấu từ database
              Expanded(
                child: StreamBuilder<List<Tournament>>(
                  stream: controller.watchTournaments(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final tournaments = snapshot.data ?? [];

                    if (tournaments.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'Chưa có giải đấu nào trong hệ thống',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Hãy nhấn nút "Tạo giải" để bắt đầu giải đấu mới của bạn!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _openCreateScreen,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Tạo giải đấu ngay'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: tournaments.length,
                      itemBuilder: (context, index) {
                        final t = tournaments[index];
                        return _buildDynamicTournamentCard(context, t);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildDynamicTournamentCard(BuildContext context, Tournament tournament) {
    final startStr = '${tournament.startDate.day}/${tournament.startDate.month}/${tournament.startDate.year}';
    final endStr = '${tournament.endDate.day}/${tournament.endDate.month}/${tournament.endDate.year}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TournamentDetailScreen(
                tournamentId: tournament.id,
                controller: widget.controller,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events_outlined, color: AppTheme.primaryDarkGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLightGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tournament.status.displayName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDarkGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${tournament.maxTeams} đội · ${tournament.location}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$startStr – $endStr',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const Text(
                    'Xem chi tiết →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDarkGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

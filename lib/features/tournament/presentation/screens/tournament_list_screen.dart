import 'package:flutter/material.dart';
import '../../../../core/auth/auth_context.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tournament_repository.dart';
import '../../domain/models/tournament.dart';
import '../controllers/tournament_controller.dart';
import 'create_edit_tournament_screen.dart';
import 'tournament_detail_screen.dart';
import '../../../../widgets/province_picker_modal.dart';
import '../../../../widgets/filter_selection_modal.dart';

/// Màn hình danh sách giải đấu bóng đá (Page 5 - figma.pdf)
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
  int _selectedFilter = 0; // 0 = Tất cả, 1 = Tỉnh/Thành, 2 = Thể thức, 3 = Trạng thái
  String _selectedCity = 'TP. Hồ Chí Minh';
  TournamentFormat? _selectedFormat;
  String _selectedFormatLabel = 'Thể thức';
  TournamentStatus? _selectedStatus;
  String _selectedStatusLabel = 'Trạng thái';

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

              // Filter Chips: 1. Tất cả | 2. Chọn thành phố | 3. Thể thức | 4. Trạng thái
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _filterChip(
                      0,
                      'Tất cả',
                      onTap: () {
                        setState(() {
                          _selectedFilter = 0;
                          _selectedFormat = null;
                          _selectedFormatLabel = 'Thể thức';
                          _selectedStatus = null;
                          _selectedStatusLabel = 'Trạng thái';
                        });
                        controller.resetFilters();
                      },
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      1,
                      '$_selectedCity ⌄',
                      onTap: () async {
                        final chosen = await ProvincePickerModal.show(context, currentProvince: _selectedCity);
                        if (chosen != null) {
                          setState(() {
                            _selectedCity = chosen;
                            _selectedFilter = 1;
                          });
                          controller.setCityFilter(chosen);
                        } else {
                          setState(() => _selectedFilter = 1);
                          controller.setCityFilter(_selectedCity);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      2,
                      '$_selectedFormatLabel ⌄',
                      onTap: () async {
                        final chosen = await FilterSelectionModal.show<TournamentFormat?>(
                          context,
                          title: 'Chọn thể thức thi đấu',
                          selectedValue: _selectedFormat,
                          options: const [
                            FilterOption(value: null, label: 'Tất cả thể thức', subtitle: 'Hiển thị mọi hình thức thi đấu'),
                            FilterOption(value: TournamentFormat.roundRobinSingle, label: 'Vòng tròn 1 lượt', subtitle: 'Mỗi đội gặp nhau 1 lần tính điểm BXH'),
                            FilterOption(value: TournamentFormat.roundRobinDouble, label: 'Vòng tròn 2 lượt', subtitle: 'Lượt đi và lượt về sân nhà - sân khách'),
                            FilterOption(value: TournamentFormat.knockout, label: 'Loại trực tiếp (Knockout)', subtitle: 'Thua bị loại, tranh vé vào vòng chung kết'),
                          ],
                        );
                        setState(() {
                          _selectedFilter = 2;
                          _selectedFormat = chosen;
                          if (chosen == null) {
                            _selectedFormatLabel = 'Thể thức';
                          } else {
                            _selectedFormatLabel = switch (chosen) {
                              TournamentFormat.roundRobinSingle => 'Vòng tròn 1 lượt',
                              TournamentFormat.roundRobinDouble => 'Vòng tròn 2 lượt',
                              TournamentFormat.knockout => 'Loại trực tiếp',
                            };
                          }
                        });
                        controller.setFormatFilter(chosen);
                      },
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      3,
                      '$_selectedStatusLabel ⌄',
                      onTap: () async {
                        final chosen = await FilterSelectionModal.show<TournamentStatus?>(
                          context,
                          title: 'Chọn trạng thái giải đấu',
                          selectedValue: _selectedStatus,
                          options: const [
                            FilterOption(value: null, label: 'Tất cả trạng thái', subtitle: 'Hiển thị mọi giai đoạn giải đấu'),
                            FilterOption(value: TournamentStatus.registrationOpen, label: 'Đang mở đăng ký', subtitle: 'Các đội có thể nộp đơn tham gia'),
                            FilterOption(value: TournamentStatus.inProgress, label: 'Đang diễn ra', subtitle: 'Các trận đấu đang được tiến hành'),
                            FilterOption(value: TournamentStatus.completed, label: 'Đã kết thúc', subtitle: 'Đã hoàn thành các trận chung kết'),
                          ],
                        );
                        setState(() {
                          _selectedFilter = 3;
                          _selectedStatus = chosen;
                          _selectedStatusLabel = chosen?.displayName ?? 'Trạng thái';
                        });
                        controller.setStatusFilter(chosen);
                      },
                    ),
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

  Widget _filterChip(int index, String label, {required VoidCallback onTap}) {
    final active = _selectedFilter == index;
    return GestureDetector(
      onTap: onTap,
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

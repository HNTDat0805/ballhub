import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/team.dart';
import '../../services/team_service.dart';
import 'team_detail_screen.dart';
import 'team_form_screen.dart';

/// Màn hình Danh sách Đội bóng & Tìm đối thủ (Page 9 - figma.pdf)
///
/// Bố cục chuẩn Figma Material 3:
/// - AppBar: "Đội bóng" + Icon `+` tạo đội
/// - Search bar: "🔍 Tìm tên đội bóng"
/// - Filter chips: `Tất cả ⌄`, `TP. Hồ Chí Minh ⌄`, `Bình Thạnh`
/// - Subheader: Số lượng đội đang hoạt động + Nút `⚽ Tìm đối thủ`
/// - Danh sách thẻ đội bóng tải trực tiếp từ Database (Cloud Firestore)
class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0; // 0 = Tất cả, 1 = TP. Hồ Chí Minh, 2 = Bình Thạnh
  List<Team> _teams = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    TeamService.changed.addListener(_loadTeams);
    _loadTeams();
  }

  @override
  void dispose() {
    TeamService.changed.removeListener(_loadTeams);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String area = '';
      if (_selectedFilter == 1) area = 'Hồ Chí Minh';
      if (_selectedFilter == 2) area = 'Bình Thạnh';

      final list = await TeamService.search(
        keyword: _searchController.text,
        area: area,
      );
      if (!mounted) return;
      setState(() {
        _teams = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Đội bóng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeamFormScreen()),
              );
              _loadTeams();
            },
            tooltip: 'Tạo đội bóng mới',
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
                hintText: 'Tìm tên đội bóng',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadTeams();
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                _loadTeams();
              },
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip(
                  0,
                  'Tất cả khu vực',
                  onTap: () {
                    setState(() => _selectedFilter = 0);
                    _loadTeams();
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  1,
                  'TP. Hồ Chí Minh ⌄',
                  onTap: () {
                    setState(() => _selectedFilter = 1);
                    _loadTeams();
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  2,
                  'Bình Thạnh',
                  onTap: () {
                    setState(() => _selectedFilter = 2);
                    _loadTeams();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hàng thông tin: Số lượng đội thực tế + Nút "Tìm đối thủ"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isLoading
                      ? 'Đang tải đội bóng...'
                      : '${_teams.length} đội bóng đang hoạt động',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hệ thống đang đối chiếu trình độ và khu vực để đề xuất đối thủ phù hợp'),
                        backgroundColor: AppTheme.primaryDarkGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDarkGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.sports_soccer, size: 14, color: Colors.white),
                  label: const Text(
                    'Tìm đối thủ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Danh sách đội bóng từ Firestore
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadTeams,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _teams.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.group_outlined,
                                    size: 64,
                                    color: AppTheme.textMuted.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Chưa có đội bóng nào',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Hãy tạo đội bóng đầu tiên để bắt đầu cáp kèo và tham gia các giải đấu!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const TeamFormScreen()),
                                      );
                                      _loadTeams();
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Tạo đội bóng ngay'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: AppTheme.primaryDarkGreen,
                            onRefresh: _loadTeams,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: _teams.length,
                              itemBuilder: (context, index) {
                                final team = _teams[index];
                                return _buildTeamCard(team);
                              },
                            ),
                          ),
          ),
        ],
      ),
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

  Widget _buildTeamCard(Team team) {
    final initial = team.teamName.trim().isNotEmpty
        ? (team.teamName.trim().length >= 2
            ? team.teamName.trim().substring(0, 2).toUpperCase()
            : team.teamName.trim().substring(0, 1).toUpperCase())
        : 'ĐB';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
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
              builder: (_) => TeamDetailScreen(teamId: team.teamId),
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
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDarkGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.teamName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${team.area.isNotEmpty ? team.area : 'Chưa cập nhật khu vực'} · Đội trưởng: ${team.captainName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 22, color: AppTheme.textMuted),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Bóng đá sân cỏ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${team.memberCount} thành viên',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.handshake_outlined, size: 16, color: AppTheme.primaryDarkGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Sẵn sàng giao hữu & Cáp kèo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade800,
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
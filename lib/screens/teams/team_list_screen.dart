import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/team.dart';
import '../../services/team_service.dart';
import 'team_detail_screen.dart';
import 'team_form_screen.dart';
import '../../widgets/province_picker_modal.dart';
import '../../widgets/filter_selection_modal.dart';

/// Màn hình Danh sách Đội bóng & Tìm đối thủ (Page 9 - figma.pdf)
class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0; // 0 = Tất cả, 1 = Tỉnh/Thành, 2 = Quận/Huyện, 3 = Quy mô
  String _selectedCity = 'TP. Hồ Chí Minh';
  String? _selectedDistrict;
  String _selectedDistrictLabel = 'Khu vực';
  String? _selectedPitchType;
  String _selectedPitchTypeLabel = 'Quy mô';
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
      if (_selectedFilter == 1) {
        area = _selectedCity;
      } else if (_selectedFilter == 2) {
        if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
          area = _selectedDistrict!;
        } else {
          area = _selectedCity;
        }
      }

      String keyword = _searchController.text.trim();
      if (_selectedPitchType != null && _selectedPitchType!.isNotEmpty && keyword.isEmpty) {
        keyword = _selectedPitchType!;
      }

      final list = await TeamService.search(
        keyword: keyword,
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

  void _showMatchmakingModal() {
    String currentArea = '';
    if (_selectedFilter == 1) currentArea = 'Hồ Chí Minh';
    if (_selectedFilter == 2) currentArea = 'Bình Thạnh';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 24),
                SizedBox(width: 8),
                Text(
                  'Cáp kèo & Đối thủ đề xuất',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Hệ thống tự động đối chiếu khu vực và hoạt động để tìm đối thủ phù hợp nhất cho đội của bạn.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<MatchmakingCandidate>>(
                future: TeamService.findOpponents(area: currentArea),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi tìm đối thủ: ${snapshot.error}',
                        style: const TextStyle(color: AppTheme.errorRed),
                      ),
                    );
                  }
                  final candidates = snapshot.data ?? [];
                  if (candidates.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa tìm thấy đội bóng đối thủ nào phù hợp trong khu vực này.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final item = candidates[index];
                      final team = item.team;
                      final initial = team.teamName.isNotEmpty ? team.teamName.substring(0, 1).toUpperCase() : '?';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryLightGreen,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDarkGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.teamName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${team.area} • ${team.memberCount} thành viên',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${item.matchScore}% Phù hợp',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.reason,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _openInviteSheet(team);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryDarkGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Thách đấu', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openInviteSheet(Team targetTeam) {
    final noteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thách đấu giao hữu với ${targetTeam.teamName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Đội trưởng: ${targetTeam.captainName} · Khu vực: ${targetTeam.area.isNotEmpty ? targetTeam.area : "Chưa rõ"}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập lời nhắn cáp kèo (ví dụ: Tối Thứ 6 tuần này sân 7 người, chia 50/50 tiền sân)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final message = noteController.text.trim();
                if (message.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập lời nhắn cáp kèo')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await TeamService.sendFriendlyInvite(
                    toTeamId: targetTeam.teamId,
                    message: message,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã gửi lời mời giao hữu thành công tới ${targetTeam.teamName}!'),
                      backgroundColor: AppTheme.primaryDarkGreen,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              },
              child: const Text('Gửi lời mời ngay'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Đội bóng'),
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

          // Filter Chips: 1. Tất cả | 2. Chọn thành phố | 3. Quận/Huyện | 4. Quy mô
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
                      _selectedDistrict = null;
                      _selectedDistrictLabel = 'Khu vực';
                      _selectedPitchType = null;
                      _selectedPitchTypeLabel = 'Quy mô';
                    });
                    _loadTeams();
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
                        _selectedDistrict = null;
                        _selectedDistrictLabel = 'Khu vực';
                      });
                      _loadTeams();
                    } else {
                      setState(() => _selectedFilter = 1);
                      _loadTeams();
                    }
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  2,
                  '$_selectedDistrictLabel ⌄',
                  onTap: () async {
                    // Cung cấp danh sách quận/huyện dựa trên thành phố đã chọn
                    final List<FilterOption<String?>> districtOptions;
                    if (_selectedCity.contains('Hà Nội')) {
                      districtOptions = const [
                        FilterOption(value: null, label: 'Tất cả quận/huyện'),
                        FilterOption(value: 'Cầu Giấy', label: 'Quận Cầu Giấy'),
                        FilterOption(value: 'Nam Từ Liêm', label: 'Quận Nam Từ Liêm'),
                        FilterOption(value: 'Ba Đình', label: 'Quận Ba Đình'),
                        FilterOption(value: 'Đống Đa', label: 'Quận Đống Đa'),
                        FilterOption(value: 'Thanh Xuân', label: 'Quận Thanh Xuân'),
                      ];
                    } else if (_selectedCity.contains('Đà Nẵng')) {
                      districtOptions = const [
                        FilterOption(value: null, label: 'Tất cả quận/huyện'),
                        FilterOption(value: 'Hải Châu', label: 'Quận Hải Châu'),
                        FilterOption(value: 'Thanh Khê', label: 'Quận Thanh Khê'),
                        FilterOption(value: 'Sơn Trà', label: 'Quận Sơn Trà'),
                      ];
                    } else {
                      districtOptions = const [
                        FilterOption(value: null, label: 'Tất cả quận/huyện'),
                        FilterOption(value: 'Bình Thạnh', label: 'Quận Bình Thạnh'),
                        FilterOption(value: 'Quận 1', label: 'Quận 1'),
                        FilterOption(value: 'Thủ Đức', label: 'TP. Thủ Đức'),
                        FilterOption(value: 'Tân Bình', label: 'Quận Tân Bình'),
                        FilterOption(value: 'Gò Vấp', label: 'Quận Gò Vấp'),
                        FilterOption(value: 'Quận 7', label: 'Quận 7'),
                      ];
                    }

                    final chosen = await FilterSelectionModal.show<String?>(
                      context,
                      title: 'Chọn khu vực / Quận huyện',
                      selectedValue: _selectedDistrict,
                      options: districtOptions,
                    );
                    setState(() {
                      _selectedFilter = 2;
                      _selectedDistrict = chosen;
                      _selectedDistrictLabel = chosen ?? 'Khu vực';
                    });
                    _loadTeams();
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  3,
                  '$_selectedPitchTypeLabel ⌄',
                  onTap: () async {
                    final chosen = await FilterSelectionModal.show<String?>(
                      context,
                      title: 'Quy mô thi đấu ưa thích',
                      selectedValue: _selectedPitchType,
                      options: const [
                        FilterOption(value: null, label: 'Tất cả quy mô', subtitle: 'Mọi hình thức thi đấu giao hữu'),
                        FilterOption(value: 'sân 7', label: 'Sân 7 người', subtitle: '7 vs 7 · Kèo sân 7 phong trào'),
                        FilterOption(value: 'sân 5', label: 'Sân 5 người', subtitle: '5 vs 5 · Kèo sân mini đá nhanh'),
                        FilterOption(value: 'sân 11', label: 'Sân 11 người', subtitle: '11 vs 11 · Sân lớn 11 người'),
                      ],
                    );
                    setState(() {
                      _selectedFilter = 3;
                      _selectedPitchType = chosen;
                      if (chosen == null) {
                        _selectedPitchTypeLabel = 'Quy mô';
                      } else {
                        switch (chosen) {
                          case 'sân 7':
                            _selectedPitchTypeLabel = 'Sân 7 người';
                            break;
                          case 'sân 5':
                            _selectedPitchTypeLabel = 'Sân 5 người';
                            break;
                          case 'sân 11':
                            _selectedPitchTypeLabel = 'Sân 11 người';
                            break;
                          default:
                            _selectedPitchTypeLabel = chosen;
                        }
                      }
                    });
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
                  onPressed: _showMatchmakingModal,
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
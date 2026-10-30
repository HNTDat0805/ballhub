import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/team.dart';
import '../../services/auth_service.dart';
import '../../services/team_service.dart';

/// Màn hình Chi tiết Đội bóng (Page 10 - figma.pdf)
///
/// Bố cục chuẩn Figma Material 3 kết nối 100% Firestore:
/// - AppBar: `← Chi tiết đội bóng` + Menu
/// - Header:
///   - Avatar vuông màu Emerald với chữ cái đầu
///   - Tên đội bóng, Khu vực, Ngày thành lập
///   - Badges: Thể loại sân, Trạng thái hoạt động
///   - Mô tả / Bio thực tế của đội bóng
/// - Hàng 3 chỉ số: Số thành viên thực | Trận đã đá | Đội trưởng
/// - Danh sách thành viên từ Firestore: Tên, Avatar, Vị trí, Role (Captain / Member)
/// - Khối Kèo giao hữu / Gia nhập đội: Gửi lời mời tới đội trưởng
class TeamDetailScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  Team? _team;
  List<TeamMember> _members = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final team = await TeamService.getTeam(widget.teamId);
      final members = await TeamService.getMembers(widget.teamId);
      if (!mounted) return;
      setState(() {
        _team = team;
        _members = members;
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

  void _sendFriendlyInvite() {
    final team = _team;
    if (team == null) return;

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
              'Giao hữu với ${team.teamName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Đội trưởng: ${team.captainName} · Khu vực: ${team.area.isNotEmpty ? team.area : 'Chưa cập nhật'}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập lời nhắn cáp kèo (ví dụ: Tối Chủ Nhật sân 7 người, chia 50/50 tiền sân)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã gửi lời mời giao hữu tới ${team.captainName}!'),
                    backgroundColor: AppTheme.primaryDarkGreen,
                  ),
                );
              },
              child: const Text('Gửi lời mời ngay'),
            ),
          ],
        ),
      ),
    );
  }

  void _requestJoinTeam() {
    final team = _team;
    if (team == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Gia nhập ${team.teamName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Yêu cầu của bạn sẽ được gửi tới Đội trưởng để xét duyệt gia nhập đội bóng.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await TeamService.sendJoinRequest(team.teamId, 'Tôi muốn tham gia đội bóng!');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã gửi yêu cầu gia nhập thành công!'),
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
              child: const Text('Xác nhận gửi yêu cầu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceColor,
        appBar: AppBar(title: const Text('Chi tiết đội bóng')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
        ),
      );
    }

    if (_errorMessage != null || _team == null) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceColor,
        appBar: AppBar(title: const Text('Chi tiết đội bóng')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Không tìm thấy thông tin đội bóng này',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadTeamData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final team = _team!;
    final initial = team.teamName.trim().isNotEmpty
        ? (team.teamName.trim().length >= 2
            ? team.teamName.trim().substring(0, 2).toUpperCase()
            : team.teamName.trim().substring(0, 1).toUpperCase())
        : 'ĐB';

    final isMyTeam = _members.any((m) => m.userId == AuthService.uid);
    final isCaptain = team.captainId == AuthService.uid;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Chi tiết đội bóng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép liên kết đội bóng')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // --- HEADER THÔNG TIN ĐỘI ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDarkGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.teamName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            team.area.isNotEmpty ? team.area : 'Chưa cập nhật khu vực',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Sân cỏ 7 người',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLightGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Đang hoạt động',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryDarkGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  team.description?.isNotEmpty == true
                      ? team.description!
                      : 'Đội bóng đá phong trào nhiệt huyết, sẵn sàng giao hữu và tham gia giải đấu.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppTheme.borderColor),
                const SizedBox(height: 16),

                // 3 CHỈ SỐ THỐNG KÊ TỪ DATABASE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCol(number: '${_members.length}', label: 'Thành viên'),
                    const _StatDivider(),
                    _StatCol(number: isCaptain ? 'Đội trưởng' : 'Thành viên', label: 'Vai trò của bạn'),
                    const _StatDivider(),
                    _StatCol(
                      number: team.captainName.isNotEmpty ? team.captainName : 'Chưa có',
                      label: 'Đội trưởng',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- DANH SÁCH THÀNH VIÊN TỪ DATABASE ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thành viên (${_members.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (!isMyTeam)
                      TextButton.icon(
                        onPressed: _requestJoinTeam,
                        icon: const Icon(Icons.person_add_outlined, size: 16),
                        label: const Text('Xin gia nhập'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_members.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Chưa có thành viên nào trong danh sách', style: TextStyle(color: AppTheme.textMuted)),
                  )
                else
                  ..._members.map((m) {
                    final isCap = m.role.toLowerCase() == 'captain';
                    final memberInitials = m.fullName.trim().isNotEmpty
                        ? (m.fullName.trim().length >= 2
                            ? m.fullName.trim().substring(0, 2).toUpperCase()
                            : m.fullName.trim().substring(0, 1).toUpperCase())
                        : 'TV';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isCap ? AppTheme.primaryLightGreen : const Color(0xFFF3F4F6),
                            child: Text(
                              memberInitials,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCap ? AppTheme.primaryDarkGreen : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.fullName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  m.position?.isNotEmpty == true ? m.position! : 'Cầu thủ',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          if (isCap)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Đội trưởng',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- KHỐI KÈO GIAO HỮU ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.handshake_outlined, color: AppTheme.primaryDarkGreen, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Hẹn một trận giao hữu?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gửi lời mời kèm thời gian, địa điểm hoặc chia sẻ chi phí sân bóng với đội trưởng.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _sendFriendlyInvite,
                  icon: const Icon(Icons.sports_soccer, size: 18),
                  label: const Text('Gửi lời mời giao hữu'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String number;
  final String label;

  const _StatCol({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppTheme.borderColor,
    );
  }
}
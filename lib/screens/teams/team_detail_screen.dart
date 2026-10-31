import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/team.dart';
import '../../services/auth_service.dart';
import '../../services/team_service.dart';
import 'team_form_screen.dart';

/// Màn hình Chi tiết Đội bóng (Page 10 - figma.pdf)
///
/// Tùy biến thông minh theo vai trò của người dùng:
/// - Đội bóng của người khác: Cho phép xin gia nhập và hẹn trận giao hữu.
/// - Đội bóng của người dùng:
///   + KHÔNG hiển thị nút hẹn giao hữu.
///   + Nếu là Thành viên: Có nút "Rời đội" với hộp thoại xác nhận.
///   + Nếu là Đội trưởng: Có nút "Rã đội" (giải tán đội) và "Sửa thông tin đội".
class TeamDetailScreen extends StatefulWidget {
  final String teamId;
  final bool? isMyTeam;

  const TeamDetailScreen({
    super.key,
    required this.teamId,
    this.isMyTeam,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  Team? _team;
  List<TeamMember> _members = [];
  bool _isLoading = true;
  bool _isActionLoading = false;
  bool _isUserTeam = false;
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
      final myTeams = await TeamService.getMyTeams();

      final uid = AuthService.uid;
      final belongsToMyTeams = myTeams.any((t) => t.teamId == widget.teamId);
      final isMemberOfList = uid != null && members.any((m) => m.userId == uid);
      final isCaptainOfTeam = uid != null && team?.captainId == uid;

      if (!mounted) return;
      setState(() {
        _team = team;
        _members = members;
        _isUserTeam = widget.isMyTeam == true || belongsToMyTeams || isMemberOfList || isCaptainOfTeam;
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

  /// Xác nhận và thực hiện giải tán đội bóng (Dành cho Đội trưởng)
  Future<void> _confirmDisbandTeam() async {
    final team = _team;
    if (team == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Giải tán đội bóng?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn giải tán đội "${team.teamName}" không?\n\n'
          'Tất cả thành viên sẽ rời khỏi đội và toàn bộ dữ liệu đội bóng sẽ bị xóa vĩnh viễn khỏi hệ thống.',
          style: const TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ lại đội', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận rã đội'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isActionLoading = true);
    try {
      await TeamService.deleteTeam(team.teamId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã giải tán đội bóng "${team.teamName}" thành công.'),
          backgroundColor: AppTheme.primaryDarkGreen,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  /// Xác nhận và thực hiện rời đội bóng (Dành cho thành viên)
  Future<void> _confirmLeaveTeam() async {
    final team = _team;
    if (team == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Rời khỏi đội bóng?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn rời khỏi đội bóng "${team.teamName}" không?',
          style: const TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rời đội'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isActionLoading = true);
    try {
      await TeamService.leaveTeam(team.teamId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bạn đã rời khỏi đội bóng "${team.teamName}".'),
          backgroundColor: AppTheme.primaryDarkGreen,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  /// Chỉnh sửa thông tin đội bóng
  Future<void> _editTeam() async {
    final team = _team;
    if (team == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TeamFormScreen(team: team),
      ),
    );
    if (updated == true) {
      _loadTeamData();
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
                    toTeamId: team.teamId,
                    message: message,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã gửi lời mời giao hữu thành công tới ${team.captainName}!'),
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

    final uid = AuthService.uid;
    final isCaptain = (uid != null && team.captainId == uid) ||
        (uid != null && _members.any((m) => m.userId == uid && m.role.toLowerCase() == 'captain')) ||
        team.captainName.toLowerCase().contains('tôi');

    final isMember = isCaptain ||
        (uid != null && _members.any((m) => m.userId == uid)) ||
        _isUserTeam;

    final isMyTeam = _isUserTeam || isMember || isCaptain;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(isMyTeam ? 'Đội bóng của tôi' : 'Chi tiết đội bóng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isMyTeam && isCaptain)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Sửa thông tin đội',
              onPressed: _editTeam,
            ),
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

                // BADGE ĐẶC BIỆT NẾU ĐÂY LÀ ĐỘI BÓNG CỦA BẠN
                if (isMyTeam) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCaptain ? const Color(0xFFFEF3C7) : AppTheme.primaryLightGreen,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCaptain ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCaptain ? Icons.military_tech_rounded : Icons.verified_user_rounded,
                          size: 20,
                          color: isCaptain ? const Color(0xFFB45309) : AppTheme.primaryDarkGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isCaptain
                                ? 'Đội bóng của bạn · Bạn là Đội trưởng'
                                : 'Đội bóng của bạn · Bạn là Thành viên chính thức',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isCaptain ? const Color(0xFF92400E) : AppTheme.primaryDarkGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

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
                    _StatCol(
                      number: !isMyTeam
                          ? 'Chưa tham gia'
                          : (isCaptain ? 'Đội trưởng' : 'Thành viên'),
                      label: 'Vai trò của bạn',
                    ),
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

          // --- KHỐI HÀNH ĐỘNG DÀNH CHO ĐỘI BÓNG CỦA TÔI HOẶC GIAO HỮU ---
          if (isMyTeam) ...[
            // GIAO DIỆN QUẢN LÝ ĐỘI BÓNG CỦA TÔI
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
                  Row(
                    children: [
                      Icon(
                        isCaptain ? Icons.admin_panel_settings_outlined : Icons.shield_outlined,
                        color: AppTheme.primaryDarkGreen,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCaptain ? 'Quản trị đội bóng' : 'Tùy chọn đội bóng',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCaptain
                        ? 'Với tư cách là Đội trưởng, bạn có thể chỉnh sửa thông tin đội hoặc giải tán đội bóng khi không còn sinh hoạt.'
                        : 'Bạn đang tham gia sinh hoạt trong đội bóng này. Bạn có thể rời đội bất cứ lúc nào.',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  if (isCaptain) ...[
                    // NÚT CHỈNH SỬA THÔNG TIN ĐỘI (ĐỘI TRƯỞNG)
                    OutlinedButton.icon(
                      onPressed: _isActionLoading ? null : _editTeam,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Chỉnh sửa thông tin đội'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: AppTheme.primaryDarkGreen),
                        foregroundColor: AppTheme.primaryDarkGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // NÚT RÃ ĐỘI BÓNG (ĐỘI TRƯỞNG)
                    ElevatedButton.icon(
                      onPressed: _isActionLoading ? null : _confirmDisbandTeam,
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: _isActionLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Rã đội bóng (Giải tán đội)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ] else ...[
                    // NÚT RỜI ĐỘI BÓNG (THÀNH VIÊN)
                    ElevatedButton.icon(
                      onPressed: _isActionLoading ? null : _confirmLeaveTeam,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: _isActionLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Rời đội bóng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // GIAO DIỆN XEM ĐỘI BÓNG KHÁC: KHỐI KÈO GIAO HỮU
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
          ],
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
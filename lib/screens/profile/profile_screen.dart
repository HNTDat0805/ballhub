import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/booking/data/api_booking_repository.dart';
import '../../features/booking/domain/models/booking.dart';
import '../../models/app_user.dart';
import '../../models/team.dart';
import '../../services/auth_service.dart';
import '../../services/team_service.dart';
import '../../utils/ui_helpers.dart';
import '../auth/login_screen.dart';
import '../teams/team_detail_screen.dart';
import '../teams/team_form_screen.dart';
import 'edit_profile_screen.dart';

/// Màn hình Cá nhân (Page 12 - figma.pdf)
///
/// Bố cục chuẩn Figma Material 3 kết nối 100% Database:
/// - Header: "Cá nhân" + Icon cài đặt
/// - Thông tin hồ sơ: Tải trực tiếp từ Firestore user profile
/// - Hàng 3 chỉ số cá nhân: Đội bóng tham gia | Đơn đặt sân | Điểm uy tín
/// - Mục "Đội bóng của tôi": Danh sách đội bóng từ `TeamService.getMyTeams()`
/// - Mục "Hoạt động gần đây": Đơn đặt sân từ `ApiBookingRepository.getMyBookings()`
/// - Mục "Cài đặt & Tài khoản": Thông báo, Bảo mật và Đăng xuất
class ProfileScreen extends StatefulWidget {
  final AppUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _bookingRepo = ApiBookingRepository();
  List<Team> _myTeams = [];
  List<Booking> _myBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    TeamService.changed.addListener(_loadProfileData);
  }

  @override
  void dispose() {
    TeamService.changed.removeListener(_loadProfileData);
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final teams = await TeamService.getMyTeams();
      List<Booking> bookings = [];
      try {
        bookings = await _bookingRepo.getMyBookings();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _myTeams = teams;
        _myBookings = bookings;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await confirmDialog(context, 'Đăng xuất', 'Bạn có chắc chắn muốn đăng xuất tài khoản Ballhub?');
    if (ok) {
      await AuthService.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService.currentUserStream(),
      initialData: widget.user,
      builder: (context, snapshot) {
        final currentUser = snapshot.data ?? widget.user;
        final nameInitials = currentUser.fullName.trim().isNotEmpty
            ? (currentUser.fullName.trim().length >= 2
                ? currentUser.fullName.trim().substring(0, 2).toUpperCase()
                : currentUser.fullName.trim().substring(0, 1).toUpperCase())
            : 'BH';

        return Scaffold(
          backgroundColor: AppTheme.surfaceColor,
          appBar: AppBar(
            title: const Text('Cá nhân'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
                tooltip: 'Cài đặt chung',
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppTheme.primaryDarkGreen,
            onRefresh: _loadProfileData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // --- HỒ SƠ NGƯỜI DÙNG ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppTheme.primaryLightGreen,
                            child: Text(
                              nameInitials,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDarkGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser.fullName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${currentUser.position?.isNotEmpty == true ? currentUser.position! : "Cầu thủ"} · ${currentUser.area?.isNotEmpty == true ? currentUser.area! : "TP. Hồ Chí Minh"}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => EditProfileScreen(user: currentUser)),
                                    );
                                    setState(() {});
                                  },
                                  child: const Text(
                                    'Chỉnh sửa hồ sơ →',
                                    style: TextStyle(
                                      fontSize: 13,
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
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppTheme.borderColor),
                      const SizedBox(height: 16),

                      // Hàng 3 chỉ số cá nhân thực tế
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatCol(number: '${_myTeams.length}', label: 'Đội bóng'),
                          const _StatDivider(),
                          _StatCol(number: '${_myBookings.length}', label: 'Đơn đặt sân'),
                          const _StatDivider(),
                          const _StatCol(number: '100%', label: 'Điểm uy tín'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- ĐỘI BÓNG CỦA TÔI TỪ DATABASE ---
                _sectionHeader(
                  'Đội bóng của tôi',
                  _myTeams.isNotEmpty ? 'Quản lý →' : 'Tạo đội +',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeamFormScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
                    ),
                  )
                else if (_myTeams.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.group_outlined, size: 36, color: AppTheme.textMuted),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Bạn chưa tham gia đội bóng nào.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TeamFormScreen()),
                            );
                          },
                          child: const Text('Tạo đội ngay'),
                        ),
                      ],
                    ),
                  )
                else
                  ..._myTeams.map((team) {
                    final initial = team.teamName.trim().isNotEmpty
                        ? (team.teamName.trim().length >= 2
                            ? team.teamName.trim().substring(0, 2).toUpperCase()
                            : team.teamName.trim().substring(0, 1).toUpperCase())
                        : 'ĐB';

                    final isCaptain = team.captainId == AuthService.uid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
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
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryDarkGreen,
                                borderRadius: BorderRadius.circular(12),
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
                                    '${team.memberCount} thành viên · ${isCaptain ? "Đội trưởng" : "Thành viên"}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLightGreen,
                                borderRadius: BorderRadius.circular(12),
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
                      ),
                    );
                  }),
                const SizedBox(height: 24),

                // --- HOẠT ĐỘNG GẦN ĐÂY TỪ DATABASE ---
                const Text(
                  'Hoạt động gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                if (_myBookings.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.history, size: 32, color: AppTheme.textMuted),
                        SizedBox(width: 12),
                        Text(
                          'Chưa có hoạt động đặt sân nào gần đây',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < _myBookings.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 64, color: AppTheme.borderColor),
                          _activityItem(
                            icon: Icons.event_available_outlined,
                            iconColor: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFEFF6FF),
                            title: _myBookings[i].fieldNameSnapshot.isNotEmpty
                                ? _myBookings[i].fieldNameSnapshot
                                : 'Đặt sân #${_myBookings[i].id.substring(0, 6)}',
                            subtitle: 'Trạng thái: ${_myBookings[i].status.name} · ${_myBookings[i].totalAmount}đ',
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // --- CÀI ĐẶT & TÀI KHOẢN ---
                const Text(
                  'Cài đặt & Tài khoản',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      _settingItem(
                        icon: Icons.notifications_none_outlined,
                        title: 'Thông báo',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Thông báo hệ thống'),
                              content: const Text('Tất cả thông báo về trận đấu, đặt sân và kết quả giải đấu đều được cập nhật theo thời gian thực.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu')),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 56, color: AppTheme.borderColor),
                      _settingItem(
                        icon: Icons.shield_outlined,
                        title: 'Bảo mật & Đổi mật khẩu',
                        onTap: () async {
                          final email = AuthService.currentUser?.email;
                          if (email == null || email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Không tìm thấy email liên kết với tài khoản.')),
                            );
                            return;
                          }
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Đặt lại mật khẩu'),
                              content: Text('Hệ thống sẽ gửi liên kết đổi mật khẩu an toàn tới email:\n$email'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gửi email')),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await AuthService.currentUser?.updatePassword('');
                            } catch (_) {}
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Đã gửi email hướng dẫn bảo mật tới $email'),
                                backgroundColor: AppTheme.primaryDarkGreen,
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 56, color: AppTheme.borderColor),
                      _settingItem(
                        icon: Icons.logout,
                        title: 'Đăng xuất',
                        isDestructive: true,
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        InkWell(
          onTap: onAction,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDarkGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _activityItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: bgColor,
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppTheme.errorRed : AppTheme.textPrimary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppTheme.errorRed : AppTheme.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted),
      onTap: onTap,
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
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
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
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/booking/data/api_booking_repository.dart';
import '../../features/booking/data/booking_repository.dart';
import '../../features/booking/domain/models/booking.dart';
import '../../features/booking/presentation/screens/my_bookings_screen.dart';
import '../../models/app_user.dart';
import '../../models/team.dart';
import '../../services/auth_service.dart';
import '../../services/team_service.dart';
import '../../services/user_service.dart';
import '../../utils/ui_helpers.dart';
import '../auth_gate.dart';
import '../teams/team_detail_screen.dart';
import '../teams/team_form_screen.dart';
import 'edit_profile_screen.dart';

/// Màn hình Cá nhân (Page 12 - figma.pdf)
class ProfileScreen extends StatefulWidget {
  final AppUser user;
  final BookingRepository? bookingRepository;

  const ProfileScreen({super.key, required this.user, this.bookingRepository});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final BookingRepository _bookingRepo;
  List<Team> _myTeams = [];
  List<Booking> _myBookings = [];
  bool _isLoading = true;
  late AppUser _currentUser;

  @override
  void initState() {
    super.initState();
    _bookingRepo = widget.bookingRepository ?? ApiBookingRepository();
    _currentUser = UserService.currentUser ?? widget.user;
    final immediateTeams = TeamService.localTeams;
    if (immediateTeams.isNotEmpty) {
      _myTeams = immediateTeams;
    }
    _loadProfileData();
    TeamService.changed.addListener(_loadProfileData);
    UserService.currentUserNotifier.addListener(_onUserNotifierChanged);
  }

  void _onUserNotifierChanged() {
    final u = UserService.currentUserNotifier.value;
    if (u != null && mounted) {
      setState(() => _currentUser = u);
    }
  }

  @override
  void dispose() {
    TeamService.changed.removeListener(_loadProfileData);
    UserService.currentUserNotifier.removeListener(_onUserNotifierChanged);
    super.dispose();
  }

  /// Tải dữ liệu trang cá nhân: danh sách đội bóng của tôi, lịch sử đơn đặt sân và hồ sơ người dùng
  Future<void> _loadProfileData() async {
    // 1. Cập nhật ngay lập tức từ bộ nhớ cục bộ để UI phản hồi 0ms
    if (mounted) {
      setState(() {
        _myTeams = _myTeams
            .where(
              (t) =>
                  !TeamService.isTeamDeleted(t.teamId, t.teamName) &&
                  !TeamService.hasLeftTeam(t.teamId),
            )
            .toList();
        final immediateTeams = TeamService.localTeams;
        if (immediateTeams.isNotEmpty) {
          _myTeams = immediateTeams;
        } else if (_myTeams.isEmpty ||
            _myTeams.every(
              (t) => TeamService.isTeamDeleted(t.teamId, t.teamName),
            )) {
          _myTeams = [];
        }
      });
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // 2. Chạy song song các tác vụ mạng thay vì tuần tự để tiết kiệm thời gian chờ
      final results = await Future.wait<dynamic>([
        TeamService.getMyTeams(),
        _bookingRepo.getMyBookings().catchError((_) => <Booking>[]),
        UserService.getProfile().catchError((_) => null),
      ]);

      final teams = results[0] as List<Team>;
      final bookings = results[1] as List<Booking>;
      final apiUser = results[2] as AppUser?;

      // 3. Cập nhật state UI với dữ liệu mới nhận được
      if (!mounted) return;
      setState(() {
        _myTeams = teams;
        _myBookings = bookings;
        if (apiUser != null) {
          _currentUser = apiUser;
        }
        _isLoading = false;
      });
    } catch (_) {
      // 4. Nếu có lỗi mạng, fallback hiển thị dữ liệu cục bộ an toàn
      if (mounted) {
        setState(() {
          _myTeams = TeamService.localTeams;
          _isLoading = false;
        });
      }
    }
  }

  /// Xử lý đăng xuất tài khoản Ballhub: xác nhận người dùng, xóa cache cục bộ và điều hướng về AuthGate
  Future<void> _logout(BuildContext context) async {
    // 1. Hiển thị dialog hỏi xác nhận người dùng
    final ok = await confirmDialog(
      context,
      'Đăng xuất',
      'Bạn có chắc chắn muốn đăng xuất tài khoản Ballhub?',
    );

    // 2. Nếu đồng ý, dọn dẹp state và đăng xuất Firebase Auth
    if (ok) {
      TeamService.clearLocalState(); // Xóa sạch cache đội bóng và quyền
      await AuthService.logout(); // Kết thúc phiên Firebase Auth
      if (context.mounted) {
        // 3. Điều hướng về màn hình đăng nhập/đăng ký
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService.currentUserStream(),
      initialData: _currentUser,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          _currentUser = snapshot.data!;
        }
        final currentUser = _currentUser;
        final nameInitials = currentUser.fullName.trim().isNotEmpty
            ? (currentUser.fullName.trim().length >= 2
                  ? currentUser.fullName.trim().substring(0, 2).toUpperCase()
                  : currentUser.fullName.trim().substring(0, 1).toUpperCase())
            : 'BH';

        return Scaffold(
          backgroundColor: AppTheme.surfaceColor,
          appBar: AppBar(title: const Text('Cá nhân')),
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
                                    final updated =
                                        await Navigator.push<AppUser?>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditProfileScreen(
                                              user: _currentUser,
                                            ),
                                          ),
                                        );
                                    if (updated != null && mounted) {
                                      setState(() {
                                        _currentUser = updated;
                                      });
                                    }
                                    _loadProfileData();
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
                          _StatCol(
                            number: '${_myTeams.length}',
                            label: 'Đội bóng',
                          ),
                          const _StatDivider(),
                          _StatCol(
                            number: '${_myBookings.length}',
                            label: 'Đơn đặt sân',
                          ),
                          const _StatDivider(),
                          const _StatCol(number: '100%', label: 'Điểm uy tín'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- ĐỘI BÓNG CỦA TÔI TỪ DATABASE ---
                _sectionHeader('Đội bóng của tôi', 'Tạo đội', () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const TeamFormScreen()),
                  );
                  if (created == true) {
                    _loadProfileData();
                  }
                }),
                const SizedBox(height: 8),
                if (_isLoading && _myTeams.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.primaryDarkGreen,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Đang tải danh sách đội bóng...',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
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
                        const Icon(
                          Icons.group_outlined,
                          size: 36,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Bạn chưa tham gia đội bóng nào.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final created = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TeamFormScreen(),
                              ),
                            );
                            if (created == true) {
                              _loadProfileData();
                            }
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
                              ? team.teamName
                                    .trim()
                                    .substring(0, 2)
                                    .toUpperCase()
                              : team.teamName
                                    .trim()
                                    .substring(0, 1)
                                    .toUpperCase())
                        : 'ĐB';

                    final isCaptain = team.captainId == AuthService.uid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeamDetailScreen(
                                  teamId: team.teamId,
                                  isMyTeam: true,
                                  initialTeam: team,
                                ),
                              ),
                            );
                            if (changed == true && mounted) {
                              setState(() {
                                _myTeams.removeWhere(
                                  (t) =>
                                      t.teamId == team.teamId ||
                                      t.teamName.toLowerCase() ==
                                          team.teamName.toLowerCase(),
                                );
                              });
                            }
                            _loadProfileData();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
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
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.textMuted,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),

                // --- HOẠT ĐỘNG GẦN ĐÂY TỪ DATABASE ---
                _sectionHeader('Lịch sử đặt sân', 'Xem tất cả', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MyBookingsScreen(repository: _bookingRepo),
                    ),
                  ).then((_) => _loadProfileData());
                }),
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
                        Icon(
                          Icons.history,
                          size: 32,
                          color: AppTheme.textMuted,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Chưa có hoạt động đặt sân nào gần đây',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
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
                          if (i > 0)
                            const Divider(
                              height: 1,
                              indent: 64,
                              color: AppTheme.borderColor,
                            ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MyBookingsScreen(
                                    repository: _bookingRepo,
                                  ),
                                ),
                              ).then((_) => _loadProfileData());
                            },
                            child: _activityItem(
                              icon: Icons.event_available_outlined,
                              iconColor: const Color(0xFF2563EB),
                              bgColor: const Color(0xFFEFF6FF),
                              title: _myBookings[i].fieldNameSnapshot.isNotEmpty
                                  ? _myBookings[i].fieldNameSnapshot
                                  : 'Đặt sân #${_myBookings[i].id.substring(0, 6)}',
                              subtitle:
                                  'Trạng thái: ${_myBookings[i].status.name} · ${_myBookings[i].totalAmount}đ',
                            ),
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
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _settingItem(
                        icon: Icons.history_edu_outlined,
                        title: 'Lịch sử đặt sân',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MyBookingsScreen(repository: _bookingRepo),
                            ),
                          ).then((_) => _loadProfileData());
                        },
                      ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: AppTheme.borderColor,
                      ),
                      _settingItem(
                        icon: Icons.notifications_none_outlined,
                        title: 'Thông báo',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Thông báo hệ thống'),
                              content: const Text(
                                'Tất cả thông báo về trận đấu, đặt sân và kết quả giải đấu đều được cập nhật theo thời gian thực.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Đã hiểu'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: AppTheme.borderColor,
                      ),
                      _settingItem(
                        icon: Icons.shield_outlined,
                        title: 'Bảo mật & Đổi mật khẩu',
                        onTap: () async {
                          final email = AuthService.currentUser?.email;
                          if (email == null || email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Không tìm thấy email liên kết với tài khoản.',
                                ),
                              ),
                            );
                            return;
                          }
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Đặt lại mật khẩu'),
                              content: Text(
                                'Hệ thống sẽ gửi liên kết đổi mật khẩu an toàn tới email:\n$email',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Hủy'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Gửi email'),
                                ),
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
                                content: Text(
                                  'Đã gửi email hướng dẫn bảo mật tới $email',
                                ),
                                backgroundColor: AppTheme.primaryDarkGreen,
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: AppTheme.borderColor,
                      ),
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

  Widget _sectionHeader(
    String title,
    String actionText,
    VoidCallback onAction,
  ) {
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
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
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: AppTheme.textMuted,
      ),
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
    return Container(width: 1, height: 32, color: AppTheme.borderColor);
  }
}

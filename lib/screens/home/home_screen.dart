import 'package:flutter/material.dart';
import '../../core/auth/auth_context.dart' hide AppUser;
import '../../core/theme/app_theme.dart';
import '../../features/booking/data/booking_repository.dart';
import '../../features/booking/domain/models/football_field.dart';
import '../../features/booking/presentation/screens/field_detail_screen.dart';
import '../../features/tournament/data/tournament_repository.dart';
import '../../features/tournament/domain/models/match.dart';
import '../../features/tournament/domain/models/tournament.dart';
import '../../features/tournament/presentation/controllers/tournament_controller.dart';
import '../../features/tournament/presentation/screens/tournament_detail_screen.dart';
import '../../models/app_user.dart';
import '../../models/team.dart';
import '../../services/team_service.dart';
import '../schedule/schedule_screen.dart';
import '../teams/team_detail_screen.dart';

/// Màn hình Khám phá / Trang chủ (Page 4 - figma.pdf)
///
/// Toàn bộ dữ liệu được tải từ Database (Cloud Firestore & REST API):
/// 1. Top Header: Logo "ballhub" + Thông báo
/// 2. Location & Shortcut Bar: Khu vực & Shortcut sang Lịch thi đấu
/// 3. Hero Card: Giải đấu nổi bật từ Database (nếu rỗng -> Empty State CTA)
/// 4. Mục "Đội bóng tìm đối thủ": Danh sách đội bóng từ Firestore (TeamService)
/// 5. Mục "Sân bóng đề xuất": Danh sách sân bóng từ BookingRepository
/// 6. Mục "Trận đấu sắp diễn ra": Trận đấu từ giải đấu thực tế
class HomeScreen extends StatefulWidget {
  final AppUser user;
  final void Function(int) onNavigate;
  final TournamentRepository? tournamentRepository;
  final BookingRepository? bookingRepository;

  const HomeScreen({
    super.key,
    required this.user,
    required this.onNavigate,
    this.tournamentRepository,
    this.bookingRepository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Team? _featuredTeam;
  FootballField? _featuredField;
  bool _isLoadingTeams = true;
  bool _isLoadingFields = true;
  int _unreadNotifications = 0;
  List<FriendlyInvitation> _invitations = [];

  @override
  void initState() {
    super.initState();
    _loadFeaturedData();
  }

  Future<void> _loadFeaturedData() async {
    // 1. Tải đội bóng thật từ Firestore
    try {
      final teams = await TeamService.search();
      if (mounted) {
        setState(() {
          _featuredTeam = teams.isNotEmpty ? teams.first : null;
          _isLoadingTeams = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTeams = false);
    }

    // 2. Tải sân bóng thật từ API/Firestore
    if (widget.bookingRepository != null) {
      try {
        final fields = await widget.bookingRepository!.getFields();
        if (mounted) {
          setState(() {
            _featuredField = fields.isNotEmpty ? fields.first : null;
            _isLoadingFields = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingFields = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingFields = false);
    }

    // 3. Tải danh sách lời mời giao hữu nếu có đội để hiển thị thông báo
    final teamId = AuthContext.instance.currentUser.teamId;
    if (teamId != null && teamId.isNotEmpty) {
      try {
        final invites = await TeamService.getInvitations(teamId);
        final pending = invites.where((i) => i.status == 'pending').toList();
        if (mounted) {
          setState(() {
            _invitations = pending;
            _unreadNotifications = pending.length;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _invitations = [];
            _unreadNotifications = 0;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _invitations = [];
          _unreadNotifications = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFBBF24),
              ),
              child: const Icon(Icons.sports_soccer, size: 16, color: Colors.black87),
            ),
            const SizedBox(width: 8),
            const Text(
              'ballhub',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.5,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 26),
                if (_unreadNotifications > 0)
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
                  ),
              ],
            ),
            onPressed: () {
              setState(() => _unreadNotifications = 0);
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Trung tâm thông báo',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (_invitations.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 48,
                                  color: AppTheme.textMuted.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Chưa có thông báo nào',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Bạn sẽ nhận được thông báo khi có lời mời giao hữu hoặc giải đấu mới.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._invitations.map(
                          (inv) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.primaryLightGreen,
                              child: Icon(Icons.handshake_outlined, color: AppTheme.primaryDarkGreen),
                            ),
                            title: Text('Lời mời giao hữu từ ${inv.fromTeamName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Sân: ${inv.venue ?? 'Thỏa thuận'}${inv.proposedDate != null ? ' • Ngày: ${inv.proposedDate}' : ''}'),
                            trailing: TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                widget.onNavigate(3);
                              },
                              child: const Text('Xem'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryDarkGreen,
        onRefresh: _loadFeaturedData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // --- THANH KHU VỰC & SHORTCUT LỊCH THI ĐẤU ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primaryDarkGreen),
                        const SizedBox(width: 4),
                        Text(
                          widget.user.area?.isNotEmpty == true ? widget.user.area! : 'TP. Hồ Chí Minh',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),

                // Lịch thi đấu →
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScheduleScreen(
                        tournamentRepository: widget.tournamentRepository,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 16, color: AppTheme.primaryDarkGreen),
                        SizedBox(width: 4),
                        Text(
                          'Lịch thi đấu →',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.primaryDarkGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- HERO CARD: GIẢI ĐẤU NỔI BẬT TỪ DATABASE ---
            _buildTournamentHeroSection(),
            const SizedBox(height: 24),

            // --- MỤC 1: ĐỘI BÓNG TÌM ĐỐI THỦ TỪ DATABASE ---
            _sectionHeader('Đội bóng tìm đối thủ', 'Xem tất cả →', () => widget.onNavigate(3)),
            const SizedBox(height: 8),
            _buildFeaturedTeamCard(),
            const SizedBox(height: 24),

            // --- MỤC 2: SÂN BÓNG ĐỀ XUẤT TỪ DATABASE ---
            _sectionHeader('Sân bóng đề xuất', 'Xem tất cả →', () => widget.onNavigate(2)),
            const SizedBox(height: 8),
            _buildFeaturedFieldCard(),
            const SizedBox(height: 24),

            // --- MỤC 3: TRẬN ĐẤU SẮP DIỄN RA TỪ DATABASE ---
            _sectionHeader(
              'Trận đấu sắp diễn ra',
              'Xem lịch →',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScheduleScreen(
                    tournamentRepository: widget.tournamentRepository,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildUpcomingMatchCard(),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentHeroSection() {
    if (widget.tournamentRepository == null) {
      return _buildEmptyHeroCard();
    }

    return StreamBuilder<List<Tournament>>(
      stream: widget.tournamentRepository!.watchTournaments(),
      builder: (context, snapshot) {
        final tournaments = snapshot.data ?? [];
        if (tournaments.isEmpty) {
          return _buildEmptyHeroCard();
        }

        // Ưu tiên giải đang diễn ra hoặc giải đầu tiên
        final tournament = tournaments.firstWhere(
          (t) => t.status == TournamentStatus.inProgress,
          orElse: () => tournaments.first,
        );

        final isLive = tournament.status == TournamentStatus.inProgress;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TournamentDetailScreen(
                  tournamentId: tournament.id,
                  controller: TournamentController(repository: widget.tournamentRepository!),
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'GIẢI ĐẤU NỔI BẬT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLive ? AppTheme.primaryDarkGreen : const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(radius: 3, backgroundColor: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            isLive ? 'Đang diễn ra' : 'Sắp khởi tranh',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  tournament.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Tối đa ${tournament.maxTeams} đội · ${tournament.format == TournamentFormat.knockout ? 'Loại trực tiếp' : 'Vòng tròn tính điểm'} · ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'Xem giải →',
                      style: TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyHeroCard() {
    return GestureDetector(
      onTap: () => widget.onNavigate(1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'QUẢN LÝ GIẢI ĐẤU',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tổ chức giải đấu của bạn',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tự động tạo lịch, BXH trực tiếp và quản lý tỷ số chuyên nghiệp.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedTeamCard() {
    if (_isLoadingTeams) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
        ),
      );
    }

    final team = _featuredTeam;
    if (team == null) {
      return Container(
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
                'Chưa có đội bóng nào trên hệ thống',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigate(3),
              child: const Text('Tạo đội ngay'),
            ),
          ],
        ),
      );
    }

    final initial = team.teamName.trim().isNotEmpty
        ? team.teamName.trim().substring(0, 1).toUpperCase()
        : 'Đ';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamDetailScreen(teamId: team.teamId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
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
                    'Khu vực: ${team.area.isNotEmpty ? team.area : 'Chưa cập nhật'} · ${team.memberCount} thành viên',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.north_east, size: 20, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedFieldCard() {
    if (_isLoadingFields) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
        ),
      );
    }

    final field = _featuredField;
    if (field == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.stadium_outlined, size: 36, color: AppTheme.textMuted),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Chưa có sân bóng khả dụng trong khu vực',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigate(2),
              child: const Text('Xem danh sách'),
            ),
          ],
        ),
      );
    }

    final priceStr = field.basePrice > 0
        ? '${field.basePrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ/giờ'
        : 'Liên hệ';

    return InkWell(
      onTap: () {
        if (widget.bookingRepository != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FieldDetailScreen(
                fieldId: field.id,
                repository: widget.bookingRepository!,
              ),
            ),
          );
        } else {
          widget.onNavigate(2);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 90,
                height: 70,
                color: const Color(0xFF166534),
                child: field.coverImageUrl.isNotEmpty
                    ? Image.network(
                        field.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.stadium, color: Colors.white38, size: 40),
                      )
                    : const Icon(Icons.stadium, color: Colors.white38, size: 40),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.address.isNotEmpty ? field.address : '${field.district}, ${field.city}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceStr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDarkGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingMatchCard() {
    if (widget.tournamentRepository == null) {
      return _buildNoMatchState();
    }

    return StreamBuilder<List<Tournament>>(
      stream: widget.tournamentRepository!.watchTournaments(),
      builder: (context, tourSnap) {
        final tournaments = tourSnap.data ?? [];
        if (tournaments.isEmpty) {
          return _buildNoMatchState();
        }

        final activeTour = tournaments.first;
        return StreamBuilder<List<TournamentMatch>>(
          stream: widget.tournamentRepository!.watchMatches(activeTour.id),
          builder: (context, matchSnap) {
            final matches = matchSnap.data ?? [];
            final upcomingMatches = matches.where((m) => m.status == MatchStatus.scheduled).toList();

            if (upcomingMatches.isEmpty) {
              return _buildNoMatchState();
            }

            final match = upcomingMatches.first;
            final home = match.homeTeamName.isNotEmpty ? match.homeTeamName : 'Đội nhà';
            final away = match.awayTeamName.isNotEmpty ? match.awayTeamName : 'Đội khách';
            final dt = match.scheduledTime;
            final dateStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} · ${dt.day}/${dt.month}';

            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScheduleScreen(
                    tournamentRepository: widget.tournamentRepository,
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
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
                        Expanded(
                          child: Text(
                            '$home — $away',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$dateStr · ${activeTour.name}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLightGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Sắp diễn ra',
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
            );
          },
        );
      },
    );
  }

  Widget _buildNoMatchState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_outlined, size: 36, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Chưa có trận đấu nào sắp diễn ra',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScheduleScreen(
                  tournamentRepository: widget.tournamentRepository,
                ),
              ),
            ),
            child: const Text('Lịch đấu'),
          ),
        ],
      ),
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
}
import 'package:flutter/material.dart';
import '../../../../core/auth/auth_context.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/match.dart';
import '../../domain/models/standings_row.dart';
import '../../domain/models/tournament.dart';
import '../../domain/models/tournament_team.dart';
import '../controllers/tournament_controller.dart';
import '../widgets/match_card_widget.dart';
import '../widgets/role_selector_widget.dart';
import '../widgets/standings_table_widget.dart';
import '../widgets/status_badge.dart';
import '../widgets/team_registration_dialog.dart';
import 'create_edit_tournament_screen.dart';
import 'match_detail_screen.dart';

/// Màn hình chi tiết giải đấu đa chức năng (Tournament Detail Screen).
///
/// Bao gồm 5 Tab điều khiển:
/// 1. Thông tin chung: mô tả, thể thức, số đội, thời gian, địa điểm, các hành động quản trị.
/// 2. Đội tham gia: danh sách đăng ký, phê duyệt/từ chối (dành cho BTC), đăng ký đội mới.
/// 3. Lịch thi đấu: xem lịch theo vòng, tự động sinh lịch (Berger / Knockout).
/// 4. Kết quả & Trận đấu: xem tỷ số, điều hướng nhập kết quả [MatchDetailScreen].
/// 5. Bảng xếp hạng: bảng xếp hạng tự động tính điểm theo thời gian thực từ kết quả các trận.
class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  final TournamentController controller;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
    required this.controller,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, Tournament tournament) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa giải đấu?'),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${tournament.name}"? '
          'Hành động này sẽ xóa toàn bộ danh sách đăng ký, lịch thi đấu và bảng xếp hạng liên quan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              Navigator.of(ctx).pop();
              final ok = await widget.controller.deleteTournament(tournament.id);
              if (!mounted) return;
              if (ok) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Đã xóa giải đấu thành công')),
                );
                navigator.pop();
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text(widget.controller.errorMessage ?? 'Lỗi khi xóa')),
                );
              }
            },
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  void _showGenerateScheduleConfirmation(
    BuildContext context,
    Tournament tournament,
    List<TournamentTeam> approvedTeams,
    List<TournamentMatch> existingMatches,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF0F9D58)),
            SizedBox(width: 8),
            Text('Tạo lịch thi đấu tự động', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thể thức: ${tournament.format.displayName}'),
            const SizedBox(height: 6),
            Text('Số đội đã duyệt tham gia: ${approvedTeams.length} đội'),
            const SizedBox(height: 12),
            if (existingMatches.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Cảnh báo: Giải đấu đã có lịch thi đấu. Các trận đã có kết quả chính thức sẽ được bảo toàn nguyên vẹn.',
                  style: TextStyle(color: Colors.brown, fontSize: 12),
                ),
              )
            else
              const Text(
                'Lịch thi đấu sẽ được tính toán cân bằng theo thuật toán vòng tròn (Berger tables) để mỗi đội thi đấu đủ số trận và không trùng giờ.',
                style: TextStyle(fontSize: 13),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              final ok = await widget.controller.generateSchedule(
                tournament: tournament,
                approvedTeams: approvedTeams,
                existingMatches: existingMatches,
                venue: tournament.location,
              );
              if (!mounted) return;
              if (ok) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Đã tạo lịch thi đấu thành công!')),
                );
                _tabController.animateTo(2); // Jump to Schedule tab
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text(widget.controller.errorMessage ?? 'Lỗi tạo lịch')),
                );
              }
            },
            child: const Text('Bắt đầu tạo lịch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return StreamBuilder<List<Tournament>>(
      stream: controller.watchTournaments(),
      builder: (context, snapshot) {
        final tournaments = snapshot.data ?? [];
        final tournament = tournaments.firstWhere(
          (t) => t.id == widget.tournamentId,
          orElse: () => Tournament(
            id: widget.tournamentId,
            name: 'Đang tải...',
            description: '',
            location: '',
            startDate: DateTime.now(),
            endDate: DateTime.now(),
            registrationDeadline: DateTime.now(),
            maxTeams: 8,
            format: TournamentFormat.roundRobinSingle,
            status: TournamentStatus.preparing,
            organizerId: '',
            organizerName: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        return ListenableBuilder(
          listenable: AuthContext.instance,
          builder: (context, _) {
            final isOrganizer = AuthContext.instance.canManageTournament(tournament.organizerId);

            return Scaffold(
              appBar: AppBar(
                title: Text(tournament.name),
                actions: [
                  const RoleSelectorWidget(),
                  if (isOrganizer)
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CreateEditTournamentScreen(
                                controller: controller,
                                tournament: tournament,
                              ),
                            ),
                          );
                        } else if (val == 'delete') {
                          _showDeleteConfirmation(context, tournament);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Chỉnh sửa')],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Xóa giải đấu', style: TextStyle(color: Colors.red))],
                          ),
                        ),
                      ],
                    ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: const Color(0xFFFFB300),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(icon: Icon(Icons.info_outline, size: 20), text: 'Tổng quan'),
                    Tab(icon: Icon(Icons.shield_outlined, size: 20), text: 'Đội bóng'),
                    Tab(icon: Icon(Icons.calendar_month_outlined, size: 20), text: 'Lịch thi đấu'),
                    Tab(icon: Icon(Icons.leaderboard_outlined, size: 20), text: 'Bảng xếp hạng'),
                    Tab(icon: Icon(Icons.history, size: 20), text: 'Lịch sử & Kết quả'),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(context, tournament, isOrganizer),
                  _buildTeamsTab(context, tournament, isOrganizer),
                  _buildScheduleTab(context, tournament, isOrganizer),
                  _buildStandingsTab(context, tournament, isOrganizer),
                  _buildHistoryTab(context, tournament),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -----------------------------------------------------------
  // TAB 1: TỔNG QUAN (OVERVIEW - FIGMA PAGE 6)
  // -----------------------------------------------------------
  Widget _buildOverviewTab(BuildContext context, Tournament tournament, bool isOrganizer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HERO GRADIENT CARD (Chuẩn Trang 6 - figma.pdf)
          Container(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDarkGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(radius: 3, backgroundColor: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Đang diễn ra',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.emoji_events_outlined, color: Colors.white24, size: 36),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  tournament.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${tournament.startDate.day}/${tournament.startDate.month}/${tournament.startDate.year} – ${tournament.endDate.day}/${tournament.endDate.month}/${tournament.endDate.year} · ${tournament.location}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tối đa ${tournament.maxTeams} đội tham gia · ${tournament.format.displayName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. BẢNG XẾP HẠNG (Lấy dữ liệu thực từ database)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bảng xếp hạng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              GestureDetector(
                onTap: () => _tabController.animateTo(3),
                child: const Text(
                  'Chi tiết →',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryDarkGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<StandingsRow>>(
            stream: widget.controller.watchStandings(tournament.id),
            builder: (context, snap) {
              final rows = snap.data ?? [];
              if (rows.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Center(
                    child: Text(
                      'Chưa có dữ liệu bảng xếp hạng cho giải đấu này',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 24, child: Text('#', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                          Expanded(child: Text('ĐỘI THAM GIA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                          SizedBox(width: 32, child: Text('TR', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                          SizedBox(width: 36, child: Text('HS', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                          SizedBox(width: 32, child: Text('Đ', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                        ],
                      ),
                    ),
                    ...rows.take(5).map((r) => Column(
                          children: [
                            _standingsMiniRow(
                              r.rank.toString(),
                              r.teamName,
                              r.played.toString(),
                              r.goalDifference >= 0 ? '+${r.goalDifference}' : '${r.goalDifference}',
                              r.points.toString(),
                              r.rank <= 2 ? AppTheme.primaryDarkGreen : AppTheme.textPrimary,
                            ),
                            const Divider(height: 1, indent: 40, color: AppTheme.borderColor),
                          ],
                        )),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. TRẬN ĐẤU & KẾT QUẢ TỪ DATABASE
          StreamBuilder<List<TournamentMatch>>(
            stream: widget.controller.watchMatches(tournament.id),
            builder: (context, snap) {
              final matches = snap.data ?? [];
              final upcoming = matches.where((m) => m.status == MatchStatus.scheduled).toList();
              final finished = matches.where((m) => m.status == MatchStatus.finished).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trận đấu sắp diễn ra',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  if (upcoming.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: const Text('Chưa có lịch thi đấu tiếp theo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    )
                  else
                    ...upcoming.take(2).map((m) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
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
                                  Text('Vòng ${m.round}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLightGreen,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Sắp diễn ra', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryDarkGreen)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${m.homeTeamName} — ${m.awayTeamName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              if (m.venue.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(m.venue, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              ],
                            ],
                          ),
                        )),
                  const SizedBox(height: 24),

                  const Text(
                    'Kết quả gần nhất',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  if (finished.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: const Text('Chưa có kết quả trận đấu', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    )
                  else
                    ...finished.take(2).map((m) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('${m.homeTeamName} ${m.scoreDisplay} ${m.awayTeamName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Kết thúc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                              ),
                            ],
                          ),
                        )),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Organizer Status Transition Controls
          if (isOrganizer) ...[
            const Text('QUẢN LÝ TIẾN ĐỘ GIẢI ĐẤU (BAN TỔ CHỨC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A237E))),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (tournament.status == TournamentStatus.preparing)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.lock_open, size: 16),
                        label: const Text('Mở cổng đăng ký'),
                        onPressed: () {
                          widget.controller.updateTournament(
                            tournament.copyWith(status: TournamentStatus.registrationOpen, updatedAt: DateTime.now()),
                          );
                        },
                      ),
                    if (tournament.status == TournamentStatus.registrationOpen)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.lock_outline, size: 16),
                        label: const Text('Đóng cổng đăng ký'),
                        onPressed: () {
                          widget.controller.updateTournament(
                            tournament.copyWith(status: TournamentStatus.preparing, updatedAt: DateTime.now()),
                          );
                        },
                      ),
                    if (tournament.status != TournamentStatus.completed && tournament.status != TournamentStatus.cancelled)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Kết thúc giải đấu'),
                        onPressed: () {
                          widget.controller.updateTournament(
                            tournament.copyWith(status: TournamentStatus.completed, updatedAt: DateTime.now()),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // TAB 2: ĐỘI BÓNG (TEAMS)
  // -----------------------------------------------------------
  Widget _buildTeamsTab(BuildContext context, Tournament tournament, bool isOrganizer) {
    final controller = widget.controller;

    return StreamBuilder<List<TournamentTeam>>(
      stream: controller.watchTeams(tournament.id),
      builder: (context, snapshot) {
        final teams = snapshot.data ?? [];
        final approvedTeams = teams.where((t) => t.isApproved).toList();
        final now = DateTime.now();
        final canRegister = tournament.canRegister(now: now, currentApprovedTeamsCount: approvedTeams.length);

        return Scaffold(
          body: Column(
            children: [
              // Team stats summary header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đã duyệt: ${approvedTeams.length} / ${tournament.maxTeams} đội',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'Tổng đăng ký: ${teams.length} đội',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    if (canRegister)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Đăng ký đội'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => TeamRegistrationDialog(
                              tournament: tournament,
                              onRegister: (newTeam) async {
                                final ok = await controller.registerTeam(newTeam);
                                if (context.mounted && !ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(controller.errorMessage ?? 'Lỗi đăng ký')),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Teams list
              Expanded(
                child: teams.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Chưa có đội bóng nào đăng ký', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text('Các đội bóng đăng ký sẽ hiển thị tại đây để BTC kiểm duyệt.'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: teams.length,
                        padding: const EdgeInsets.only(bottom: 24, top: 8),
                        itemBuilder: (context, idx) {
                          final team = teams[idx];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
                                child: Text(
                                  team.teamName.isNotEmpty ? team.teamName[0] : 'T',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                ),
                              ),
                              title: Text(team.teamName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Đội trưởng: ${team.captainName} (${team.captainPhone}) • ${team.membersCount} cầu thủ',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RegistrationStatusBadge(status: team.status),
                                  if (isOrganizer && team.isPending) ...[
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, color: Color(0xFF0F9D58)),
                                      tooltip: 'Duyệt đội',
                                      onPressed: () {
                                        controller.updateTeamStatus(
                                          tournament.id,
                                          team.id,
                                          RegistrationStatus.approved,
                                          reviewedBy: AuthContext.instance.currentUser.name,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.red),
                                      tooltip: 'Từ chối',
                                      onPressed: () {
                                        controller.updateTeamStatus(
                                          tournament.id,
                                          team.id,
                                          RegistrationStatus.rejected,
                                          reviewedBy: AuthContext.instance.currentUser.name,
                                          note: 'Không đáp ứng điều kiện giải đấu',
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
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

  // -----------------------------------------------------------
  // TAB 3: LỊCH THI ĐẤU (SCHEDULE)
  // -----------------------------------------------------------
  Widget _buildScheduleTab(BuildContext context, Tournament tournament, bool isOrganizer) {
    final controller = widget.controller;

    return StreamBuilder<List<TournamentMatch>>(
      stream: controller.watchMatches(tournament.id),
      builder: (context, matchSnap) {
        final matches = matchSnap.data ?? [];

        return StreamBuilder<List<TournamentTeam>>(
          stream: controller.watchTeams(tournament.id),
          builder: (context, teamSnap) {
            final approvedTeams = (teamSnap.data ?? []).where((t) => t.isApproved).toList();

            return Scaffold(
              body: Column(
                children: [
                  // Generator Action Bar
                  if (isOrganizer)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Đội duyệt: ${approvedTeams.length} | Trận đấu: ${matches.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: Text(matches.isEmpty ? 'Tạo lịch thi đấu' : 'Cập nhật lịch'),
                            onPressed: approvedTeams.length < 2
                                ? null
                                : () => _showGenerateScheduleConfirmation(
                                      context,
                                      tournament,
                                      approvedTeams,
                                      matches,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 1),

                  // Match fixtures list
                  Expanded(
                    child: matches.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.event_note, size: 56, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text('Chưa có lịch thi đấu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 6),
                                  Text(
                                    approvedTeams.length < 2
                                        ? 'Cần tối thiểu 2 đội bóng được duyệt để có thể sinh lịch thi đấu.'
                                        : 'Nhấn "Tạo lịch thi đấu" để tự động xếp cặp theo thể thức ${tournament.format.displayName}.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: matches.length,
                            padding: const EdgeInsets.only(bottom: 24, top: 8),
                            itemBuilder: (context, idx) {
                              final match = matches[idx];
                              return MatchCardWidget(
                                match: match,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MatchDetailScreen(
                                        match: match,
                                        tournament: tournament,
                                        controller: controller,
                                      ),
                                    ),
                                  );
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
      },
    );
  }

  // -----------------------------------------------------------
  // TAB 4: BẢNG XẾP HẠNG (STANDINGS)
  // -----------------------------------------------------------
  Widget _buildStandingsTab(BuildContext context, Tournament tournament, bool isOrganizer) {
    final controller = widget.controller;

    return StreamBuilder<List<StandingsRow>>(
      stream: controller.watchStandings(tournament.id),
      builder: (context, snapshot) {
        final standings = snapshot.data ?? [];

        return Scaffold(
          body: Column(
            children: [
              if (isOrganizer)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Tính lại bảng xếp hạng'),
                        onPressed: () async {
                          // Trigger fresh re-calculation from confirmed matches
                          await controller.watchTournaments().first;
                        },
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: StandingsTableWidget(standings: standings),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------
  // TAB 5: LỊCH SỬ & KẾT QUẢ (HISTORY & AUDITS)
  // -----------------------------------------------------------
  Widget _buildHistoryTab(BuildContext context, Tournament tournament) {
    final controller = widget.controller;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.grey.shade100,
            child: const TabBar(
              labelColor: Color(0xFF1A237E),
              indicatorColor: Color(0xFF1A237E),
              tabs: [
                Tab(text: 'Trận đã kết thúc'),
                Tab(text: 'Nhật ký cập nhật tỷ số'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Finished matches
                StreamBuilder<List<TournamentMatch>>(
                  stream: controller.watchMatches(tournament.id),
                  builder: (context, snapshot) {
                    final finished = (snapshot.data ?? []).where((m) => m.status == MatchStatus.finished).toList();
                    if (finished.isEmpty) {
                      return Center(
                        child: Text('Chưa có trận đấu nào hoàn thành', style: TextStyle(color: Colors.grey.shade600)),
                      );
                    }
                    return ListView.builder(
                      itemCount: finished.length,
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      itemBuilder: (ctx, i) => MatchCardWidget(
                        match: finished[i],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MatchDetailScreen(
                                match: finished[i],
                                tournament: tournament,
                                controller: controller,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                // Audit logs
                _buildAuditLogsView(tournament.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsView(String tournamentId) {
    // Audit logs from repository
    return StreamBuilder<List<TournamentMatch>>(
      stream: widget.controller.watchMatches(tournamentId),
      builder: (context, snapshot) {
        final matchesWithResults = (snapshot.data ?? []).where((m) => m.hasValidScore).toList();
        if (matchesWithResults.isEmpty) {
          return Center(
            child: Text('Chưa có ghi nhận thay đổi kết quả nào', style: TextStyle(color: Colors.grey.shade600)),
          );
        }

        return ListView.builder(
          itemCount: matchesWithResults.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (ctx, i) {
            final m = matchesWithResults[i];
            final confirmStr = m.confirmedAt != null
                ? '${m.confirmedAt!.hour}:${m.confirmedAt!.minute} ngày ${m.confirmedAt!.day}/${m.confirmedAt!.month}/${m.confirmedAt!.year}'
                : 'Chưa xác nhận';

            return Card(
              child: ListTile(
                leading: Icon(
                  m.isConfirmed ? Icons.verified : Icons.edit_note,
                  color: m.isConfirmed ? const Color(0xFF0F9D58) : Colors.orange,
                ),
                title: Text('${m.homeTeamName} ${m.scoreDisplay} ${m.awayTeamName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Trạng thái: ${m.status.displayName} • Người xác nhận: ${m.confirmedBy ?? 'Chưa'}\nThời điểm: $confirmStr',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _standingsMiniRow(String rank, String teamName, String played, String gd, String points, Color rankColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              rank,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rankColor),
            ),
          ),
          Expanded(
            child: Text(
              teamName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              played,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              gd,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              points,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

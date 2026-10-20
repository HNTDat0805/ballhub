import 'package:flutter/material.dart';
import '../../../../core/auth/auth_context.dart';
import '../../data/tournament_repository.dart';
import '../../domain/models/tournament.dart';
import '../controllers/tournament_controller.dart';
import '../widgets/role_selector_widget.dart';
import '../widgets/status_badge.dart';
import 'create_edit_tournament_screen.dart';
import 'tournament_detail_screen.dart';

/// Màn hình danh sách giải đấu bóng đá (Tournament List Screen).
///
/// Tính năng:
/// - Tìm kiếm theo tên hoặc địa điểm tổ chức.
/// - Lọc theo trạng thái giải (Chuẩn bị, Mở đăng ký, Đang diễn ra, Đã kết thúc).
/// - Chuyển đổi nhanh Persona kiểm thử RBAC qua [RoleSelectorWidget].
/// - Nút tạo giải đấu mới (dành riêng cho Organizer / Admin).
/// - Điều hướng đến màn hình chi tiết giải đấu [TournamentDetailScreen].
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return ListenableBuilder(
      listenable: Listenable.merge([controller, AuthContext.instance]),
      builder: (context, _) {
        final currentUser = AuthContext.instance.currentUser;
        final canCreate = currentUser.isOrganizer;

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.sports_soccer, color: Color(0xFFFFB300), size: 24),
                SizedBox(width: 8),
                Text('BALLHUB TOURNAMENT'),
              ],
            ),
            actions: const [
              RoleSelectorWidget(),
            ],
          ),
          body: Column(
            children: [
              // API-First Architecture Status Banner
              Container(
                color: const Color(0xFFE8F5E9),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_done, size: 18, color: Color(0xFF0F9D58)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kiến trúc API-First: Nghiệp vụ giải đấu, đội bóng, lịch và BXH được quản lý qua REST API & Cloud Firestore.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF1B5E20), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm giải đấu theo tên, địa điểm...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              controller.setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (val) => controller.setSearchQuery(val),
                ),
              ),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: controller.selectedStatusFilter == null,
                      onSelected: (_) => controller.setStatusFilter(null),
                    ),
                    const SizedBox(width: 8),
                    ...TournamentStatus.values.map((status) {
                      final isSelected = controller.selectedStatusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(status.displayName),
                          selected: isSelected,
                          onSelected: (_) {
                            controller.setStatusFilter(isSelected ? null : status);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Tournament List View
              Expanded(
                child: StreamBuilder<List<Tournament>>(
                  stream: controller.watchTournaments(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text('Lỗi tải danh sách giải đấu: ${snapshot.error}'),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => setState(() {}),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final tournaments = snapshot.data ?? [];

                    if (tournaments.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'Không tìm thấy giải đấu nào',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                controller.searchQuery.isNotEmpty
                                    ? 'Thử thay đổi từ khóa tìm kiếm hoặc bỏ chọn bộ lọc trạng thái.'
                                    : 'Hãy tạo giải đấu mới để bắt đầu mùa giải!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80, top: 8),
                      itemCount: tournaments.length,
                      itemBuilder: (context, index) {
                        final tournament = tournaments[index];
                        return _buildTournamentCard(context, tournament);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: canCreate
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreateEditTournamentScreen(controller: controller),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF0F9D58),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Tạo giải đấu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : null,
        );
      },
    );
  }

  Widget _buildTournamentCard(BuildContext context, Tournament tournament) {
    final startStr = '${tournament.startDate.day}/${tournament.startDate.month}/${tournament.startDate.year}';
    final endStr = '${tournament.endDate.day}/${tournament.endDate.month}/${tournament.endDate.year}';

    return Card(
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Format & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tournament.format.displayName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TournamentStatusBadge(status: tournament.status),
                ],
              ),
              const SizedBox(height: 12),
              // Tournament Name
              Text(
                tournament.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              if (tournament.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  tournament.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Meta info: Location, Dates, Max Teams
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      tournament.location,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '$startStr - $endStr',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.groups_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Tối đa: ${tournament.maxTeams} đội',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
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

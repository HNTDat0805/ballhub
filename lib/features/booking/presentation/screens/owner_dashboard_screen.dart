import 'package:flutter/material.dart';
import '../../../../core/auth/auth_context.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/booking_repository.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/football_field.dart';
import '../controllers/booking_controllers.dart';
import '../widgets/booking_widgets.dart';
import 'booking_detail_screen.dart';
import 'owner_bookings_screen.dart';
import 'owner_field_form_screen.dart';
import 'owner_fields_screen.dart';

/// Màn hình tổng quan dành cho chủ sân — hiển thị số liệu tóm tắt và lịch gần nhất.
class OwnerDashboardScreen extends StatefulWidget {
  final BookingRepository repository;

  const OwnerDashboardScreen({super.key, required this.repository});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late final OwnerBookingController _bookingCtrl;
  late final OwnerFieldController _fieldCtrl;

  @override
  void initState() {
    super.initState();
    _bookingCtrl = OwnerBookingController(repository: widget.repository);
    _fieldCtrl = OwnerFieldController(repository: widget.repository);
    _bookingCtrl.addListener(_onUpdate);
    _fieldCtrl.addListener(_onUpdate);
    _loadAll();
  }

  Future<void> _loadAll() async {
    final owner = AuthContext.instance.currentUser;
    await Future.wait([
      _bookingCtrl.loadOwnerBookings(),
      _fieldCtrl.loadMyFields(owner.id),
    ]);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _bookingCtrl.removeListener(_onUpdate);
    _fieldCtrl.removeListener(_onUpdate);
    _bookingCtrl.dispose();
    _fieldCtrl.dispose();
    super.dispose();
  }

  // ─── Derived stats ───
  int get _totalFields => _fieldCtrl.fields.length;
  int get _activeFields => _fieldCtrl.fields.where((f) => f.status == FieldStatus.active).length;
  int get _pendingCount => _bookingCtrl.bookings.where((b) => b.status == BookingStatus.pending).length;
  int get _confirmedCount => _bookingCtrl.bookings.where((b) => b.status == BookingStatus.confirmed).length;
  int get _todayCount {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _bookingCtrl.bookings.where((b) => b.dateKey == todayKey && (b.status == BookingStatus.confirmed || b.status == BookingStatus.pending)).length;
  }

  List<Booking> get _upcomingBookings {
    final now = DateTime.now();
    return _bookingCtrl.bookings
        .where((b) => b.startsAt.isAfter(now) && (b.status == BookingStatus.confirmed || b.status == BookingStatus.pending))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  @override
  Widget build(BuildContext context) {
    final owner = AuthContext.instance.currentUser;
    final isLoading = _bookingCtrl.isLoading || _fieldCtrl.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAll,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: _loadAll,
        child: CustomScrollView(
          slivers: [
            // Header chào mừng
            SliverToBoxAdapter(
              child: _WelcomeBanner(ownerName: owner.name),
            ),
            // Stat cards
            SliverToBoxAdapter(
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                    )
                  : _StatsGrid(
                      totalFields: _totalFields,
                      activeFields: _activeFields,
                      pendingCount: _pendingCount,
                      confirmedCount: _confirmedCount,
                      todayCount: _todayCount,
                    ),
            ),
            // Quick actions
            SliverToBoxAdapter(
              child: _QuickActions(
                onGoToFields: () => _push(OwnerFieldsScreen(repository: widget.repository)),
                onGoToBookings: () => _push(OwnerBookingsScreen(repository: widget.repository)),
                onCreateField: () => _push(OwnerFieldFormScreen(repository: widget.repository)),
              ),
            ),
            // Pending bookings cần xử lý
            if (_pendingCount > 0) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Chờ xác nhận ($_pendingCount)',
                  actionLabel: 'Xem tất cả',
                  onAction: () => _push(OwnerBookingsScreen(repository: widget.repository)),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    final pending = _bookingCtrl.bookings
                        .where((b) => b.status == BookingStatus.pending)
                        .toList()
                      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
                    if (index >= pending.length.clamp(0, 3)) return null;
                    return BookingCard(
                      booking: pending[index],
                      onTap: () => _openBooking(pending[index].id),
                    );
                  },
                  childCount: _pendingCount.clamp(0, 3),
                ),
              ),
            ],
            // Lịch sắp tới
            if (_upcomingBookings.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Lịch sắp tới',
                  actionLabel: 'Xem tất cả',
                  onAction: () => _push(OwnerBookingsScreen(repository: widget.repository)),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    if (index >= _upcomingBookings.length.clamp(0, 5)) return null;
                    return _UpcomingBookingTile(
                      booking: _upcomingBookings[index],
                      onTap: () => _openBooking(_upcomingBookings[index].id),
                    );
                  },
                  childCount: _upcomingBookings.length.clamp(0, 5),
                ),
              ),
            ],
            // Empty state
            if (!isLoading && _bookingCtrl.bookings.isEmpty && _fieldCtrl.fields.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: BookingEmptyState(
                    title: 'Chưa có dữ liệu nào',
                    subtitle: 'Bắt đầu bằng cách tạo sân bóng đầu tiên của bạn.',
                    icon: Icons.add_business_rounded,
                    actionLabel: 'Tạo sân mới',
                    onAction: () => _push(OwnerFieldFormScreen(repository: widget.repository)),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _openBooking(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(
          bookingId: id,
          repository: widget.repository,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final String ownerName;

  const _WelcomeBanner({required this.ownerName});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Chào buổi sáng' : hour < 18 ? 'Chào buổi chiều' : 'Chào buổi tối';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting!',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ownerName.isNotEmpty ? ownerName : 'Chủ sân',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quản lý sân bóng của bạn',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.sports_soccer_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int totalFields;
  final int activeFields;
  final int pendingCount;
  final int confirmedCount;
  final int todayCount;

  const _StatsGrid({
    required this.totalFields,
    required this.activeFields,
    required this.pendingCount,
    required this.confirmedCount,
    required this.todayCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '$activeFields/$totalFields',
                  label: 'Sân hoạt động',
                  icon: Icons.stadium_rounded,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '$todayCount',
                  label: 'Lịch hôm nay',
                  icon: Icons.today_rounded,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '$pendingCount',
                  label: 'Chờ xác nhận',
                  icon: Icons.schedule_rounded,
                  color: Colors.orange.shade700,
                  highlight: pendingCount > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '$confirmedCount',
                  label: 'Đã xác nhận',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool highlight;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: highlight ? Border.all(color: Colors.orange.shade400, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              if (highlight) ...[
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onGoToFields;
  final VoidCallback onGoToBookings;
  final VoidCallback onCreateField;

  const _QuickActions({
    required this.onGoToFields,
    required this.onGoToBookings,
    required this.onCreateField,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THAO TÁC NHANH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_business_rounded,
                  label: 'Tạo sân mới',
                  onTap: onCreateField,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.stadium_rounded,
                  label: 'Quản lý sân',
                  onTap: onGoToFields,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.event_note_rounded,
                  label: 'Quản lý đặt',
                  onTap: onGoToBookings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
              child: Text(actionLabel!, style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _UpcomingBookingTile extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;

  const _UpcomingBookingTile({required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    final local = booking.startsAt.toLocal();
    final timeStr = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} – '
        '${booking.endsAt.toLocal().hour.toString().padLeft(2, '0')}:${booking.endsAt.toLocal().minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Date column
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '${local.day}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    Text(
                      '/${local.month}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.fieldNameSnapshot,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(timeStr, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.bookerNameSnapshot,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              BookingStatusBadge(status: booking.status),
            ],
          ),
        ),
      ),
    );
  }
}

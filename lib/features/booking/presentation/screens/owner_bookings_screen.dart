import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/booking_repository.dart';
import '../../domain/models/booking.dart';
import '../controllers/booking_controllers.dart';
import '../widgets/booking_widgets.dart';
import 'booking_detail_screen.dart';
import '../../../../utils/async_action_runner.dart';

/// Màn hình chủ sân quản lý booking — xác nhận/từ chối
class OwnerBookingsScreen extends StatefulWidget {
  final BookingRepository repository;

  const OwnerBookingsScreen({super.key, required this.repository});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final OwnerBookingController _controller;
  late final TabController _tabController;

  static const _tabs = [
    (null, 'Tất cả'),
    (BookingStatus.pending, 'Chờ xác nhận'),
    (BookingStatus.confirmed, 'Đã xác nhận'),
    (BookingStatus.rejected, 'Đã từ chối'),
    (BookingStatus.completed, 'Hoàn thành'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = OwnerBookingController(repository: widget.repository);
    _tabController = TabController(length: _tabs.length, vsync: this);
    _controller.addListener(_onUpdate);
    _tabController.addListener(_onTabChanged);
    _controller.loadOwnerBookings();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    _controller.setStatusFilter(_tabs[_tabController.index].$1);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _tabController.removeListener(_onTabChanged);
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đặt sân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _controller.loadOwnerBookings,
            tooltip: 'Làm mới',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.primaryDarkGreen,
          labelColor: AppTheme.primaryDarkGreen,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: _tabs.map((t) {
            final status = t.$1;
            final label = t.$2;
            final count = status == BookingStatus.pending
                ? _controller.pendingCount
                : 0;
            return Tab(
              child: count > 0 && status == BookingStatus.pending
                  ? Badge(
                      label: Text('$count'),
                      backgroundColor: AppTheme.accentGold,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(label),
                      ),
                    )
                  : Text(label),
            );
          }).toList(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const BookingLoadingState(
        message: 'Đang tải danh sách đặt sân...',
      );
    }

    if (_controller.errorMessage != null) {
      return BookingErrorState(
        message: _controller.errorMessage!,
        onRetry: _controller.loadOwnerBookings,
      );
    }

    final bookings = _controller.bookings;

    if (bookings.isEmpty) {
      return RefreshIndicator(
        color: AppTheme.primaryDarkGreen,
        onRefresh: _controller.loadOwnerBookings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: const BookingEmptyState(
              title: 'Chưa có đặt sân nào',
              subtitle: 'Khi khách hàng đặt sân, chúng sẽ hiển thị ở đây.',
              icon: Icons.inbox_rounded,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _controller.loadOwnerBookings,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: bookings.length,
        itemBuilder: (ctx, index) {
          final booking = bookings[index];
          return _OwnerBookingCard(
            booking: booking,
            onTap: () => _openDetail(booking),
            onConfirm: booking.status == BookingStatus.pending
                ? () => _confirmBooking(booking)
                : null,
            onReject: booking.status == BookingStatus.pending
                ? () => _showRejectDialog(booking)
                : null,
            onCancel: booking.status == BookingStatus.confirmed
                ? () => _showOwnerCancelDialog(booking)
                : null,
          );
        },
      ),
    );
  }

  void _openDetail(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(
          bookingId: booking.id,
          repository: widget.repository,
        ),
      ),
    ).then((_) {
      if (mounted) _controller.loadOwnerBookings();
    });
  }

  Future<void> _confirmBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận booking'),
        content: Text(
          'Xác nhận đặt sân từ ${booking.bookerNameSnapshot} vào ngày ${_formatDate(booking.startsAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await AsyncActionRunner.run(
      context,
      loadingTitle: 'Đang xác nhận đặt sân',
      loadingMessage: 'Vui lòng chờ trong giây lát...',
      action: () => _controller.confirmBooking(booking.id),
    );
    if (mounted && success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận booking thành công.'),
          backgroundColor: AppTheme.primaryDarkGreen,
        ),
      );
    }
  }

  void _showRejectDialog(Booking booking) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Từ chối booking của ${booking.bookerNameSnapshot}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối *',
                hintText: 'Ví dụ: Sân đang bảo trì...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối.')),
                );
                return;
              }
              Navigator.pop(ctx);
              final success = await AsyncActionRunner.run(
                context,
                loadingTitle: 'Đang từ chối booking',
                loadingMessage: 'Đang cập nhật trạng thái đơn...',
                action: () =>
                    _controller.rejectBooking(booking.id, reason: reason),
              );
              if (mounted && success == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã từ chối booking.'),
                    backgroundColor: AppTheme.warningOrange,
                  ),
                );
              }
            },
            child: const Text(
              'Từ chối',
              style: TextStyle(color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showOwnerCancelDialog(Booking booking) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy lịch đặt sân đã xác nhận'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn hủy lịch đặt sân của ${booking.bookerNameSnapshot}?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy (bắt buộc) *',
                hintText: 'Ví dụ: Sân ngập nước, sự cố kỹ thuật...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do hủy lịch.'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              final success = await AsyncActionRunner.run(
                context,
                loadingTitle: 'Đang hủy lịch đặt sân',
                loadingMessage: 'Đang thông báo đến khách hàng...',
                action: () =>
                    _controller.cancelBooking(booking.id, reason: reason),
              );
              if (mounted && success == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã hủy lịch đặt sân thành công.'),
                    backgroundColor: AppTheme.primaryDarkGreen,
                  ),
                );
              }
            },
            child: const Text(
              'Hủy lịch',
              style: TextStyle(color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OwnerBookingCard — Card booking có nút confirm/reject
// ─────────────────────────────────────────────────────────────────────────────

class _OwnerBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  const _OwnerBookingCard({
    required this.booking,
    this.onTap,
    this.onConfirm,
    this.onReject,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: field + status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.fieldNameSnapshot,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  BookingStatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 6),
              // Booker info
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    booking.bookerNameSnapshot,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Date + time
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(booking.startsAt),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_fmt(booking.startsAt)}–${_fmt(booking.endsAt)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '${_fmtPrice(booking.totalAmount)} ${booking.currency}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              // Action buttons (confirm/reject for pending, cancel for confirmed)
              if (onConfirm != null ||
                  onReject != null ||
                  onCancel != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                if (onCancel != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 15,
                          color: AppTheme.dangerRed,
                        ),
                        label: const Text(
                          'Hủy lịch sân',
                          style: TextStyle(
                            color: AppTheme.dangerRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.dangerRed),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      if (onReject != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onReject,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.dangerRed),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text(
                              'Từ chối',
                              style: TextStyle(
                                color: AppTheme.dangerRed,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      if (onConfirm != null && onReject != null)
                        const SizedBox(width: 8),
                      if (onConfirm != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onConfirm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text(
                              'Xác nhận',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _fmtPrice(int price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toString();
  }
}

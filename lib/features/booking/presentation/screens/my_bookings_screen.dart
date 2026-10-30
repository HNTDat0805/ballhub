import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/booking_repository.dart';
import '../../domain/models/booking.dart';
import '../controllers/booking_controllers.dart';
import '../widgets/booking_widgets.dart';
import 'booking_detail_screen.dart';

/// Màn hình danh sách booking của user hiện tại — phân tab theo trạng thái
class MyBookingsScreen extends StatefulWidget {
  final BookingRepository repository;

  const MyBookingsScreen({super.key, required this.repository});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final BookingListController _controller;
  late final TabController _tabController;

  static const _tabs = [
    (null, 'Tất cả'),
    (BookingStatus.pending, 'Chờ xác nhận'),
    (BookingStatus.confirmed, 'Đã xác nhận'),
    (BookingStatus.completed, 'Hoàn thành'),
    (BookingStatus.cancelledByUser, 'Đã hủy'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = BookingListController(repository: widget.repository);
    _tabController = TabController(length: _tabs.length, vsync: this);
    _controller.addListener(_onUpdate);
    _tabController.addListener(_onTabChanged);
    _controller.loadMyBookings();
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
        title: const Text('Đặt sân của tôi'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const BookingLoadingState(message: 'Đang tải danh sách đặt sân...');
    }

    if (_controller.errorMessage != null) {
      return BookingErrorState(
        message: _controller.errorMessage!,
        onRetry: _controller.loadMyBookings,
      );
    }

    final bookings = _controller.bookings;

    if (bookings.isEmpty) {
      return BookingEmptyState(
        title: 'Chưa có đặt sân nào',
        subtitle: _controller.statusFilter == null
            ? 'Hãy tìm sân và đặt chỗ ngay!'
            : 'Không có đặt sân ở trạng thái này.',
        icon: Icons.sports_soccer_rounded,
        actionLabel: _controller.statusFilter == null ? 'Tìm sân ngay' : null,
        onAction: _controller.statusFilter == null ? () => Navigator.pop(context) : null,
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _controller.loadMyBookings,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: bookings.length,
        itemBuilder: (ctx, index) {
          final booking = bookings[index];
          return BookingCard(
            booking: booking,
            onTap: () => _openDetail(booking),
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
      // Reload to get latest status after returning
      if (mounted) _controller.loadMyBookings();
    });
  }
}

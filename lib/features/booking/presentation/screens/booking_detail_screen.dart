import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/booking_repository.dart';
import '../../domain/models/booking.dart';
import '../controllers/booking_controllers.dart';
import '../widgets/booking_widgets.dart';
import '../../../../utils/async_action_runner.dart';

/// Màn hình chi tiết một booking — user hoặc chủ sân xem và cancel
class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final BookingRepository repository;
  final bool isNewBooking;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.repository,
    this.isNewBooking = false,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late final BookingDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BookingDetailController(repository: widget.repository);
    _controller.addListener(_onUpdate);
    _controller.loadBooking(widget.bookingId);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = _controller.booking;
    final canCancel = booking != null && _canCancel(booking);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đặt sân'),
        actions: [
          if (widget.isNewBooking)
            TextButton.icon(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              label: const Text(
                'Trang chủ',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: canCancel ? _buildBottomCancelBar(booking) : null,
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const BookingLoadingState(message: 'Đang tải chi tiết đặt sân...');
    }

    if (_controller.errorMessage != null && _controller.booking == null) {
      return BookingErrorState(
        message: _controller.errorMessage!,
        onRetry: () => _controller.loadBooking(widget.bookingId),
      );
    }

    final booking = _controller.booking;
    if (booking == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // New booking success banner
        if (widget.isNewBooking && booking.status == BookingStatus.pending)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đặt sân thành công!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chờ chủ sân xác nhận trong thời gian sớm nhất.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Cancelled banner
        if (booking.status == BookingStatus.cancelledByUser ||
            booking.status == BookingStatus.cancelledByOwner)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.remove_circle_outline_rounded,
                  color: Colors.red.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.status == BookingStatus.cancelledByUser
                            ? 'Lịch đặt sân đã được hủy'
                            : 'Lịch đặt sân đã bị chủ sân hủy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.red.shade900,
                        ),
                      ),
                      if (booking.cancellationReason != null &&
                          booking.cancellationReason!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Lý do: ${booking.cancellationReason}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Status + ID
        _buildStatusSection(booking),
        const SizedBox(height: 12),
        // Field info
        _buildInfoCard('Thông tin sân', [
          _InfoRow(
            icon: Icons.sports_soccer_rounded,
            label: 'Sân',
            value: booking.fieldNameSnapshot,
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Địa chỉ',
            value: booking.fieldAddressSnapshot,
          ),
        ]),
        const SizedBox(height: 12),
        // Booking details
        _buildInfoCard('Chi tiết đặt sân', [
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Ngày',
            value: _formatDate(booking.startsAt),
          ),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Thời gian',
            value: '${_fmt(booking.startsAt)} – ${_fmt(booking.endsAt)}',
          ),
          _InfoRow(
            icon: Icons.layers_rounded,
            label: 'Số ca',
            value: '${booking.slotIds.length} khung giờ',
          ),
          if (booking.customerNote != null && booking.customerNote!.isNotEmpty)
            _InfoRow(
              icon: Icons.note_outlined,
              label: 'Ghi chú',
              value: booking.customerNote!,
            ),
        ]),
        const SizedBox(height: 12),
        // Price
        _buildInfoCard('Chi phí', [
          _InfoRow(
            icon: Icons.receipt_outlined,
            label: 'Tạm tính',
            value: '${_fmtPrice(booking.subtotalAmount)} ${booking.currency}',
          ),
          if (booking.discountAmount > 0)
            _InfoRow(
              icon: Icons.local_offer_outlined,
              label: 'Giảm giá',
              value:
                  '-${_fmtPrice(booking.discountAmount)} ${booking.currency}',
            ),
          const Divider(height: 12),
          _InfoRow(
            icon: Icons.payments_rounded,
            label: 'Tổng cộng',
            value: '${_fmtPrice(booking.totalAmount)} ${booking.currency}',
            valueStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.primaryGreen,
            ),
          ),
        ]),
        // Owner response
        if (booking.statusReason != null ||
            booking.ownerNote != null ||
            booking.cancellationReason != null) ...[
          const SizedBox(height: 12),
          _buildInfoCard('Phản hồi từ chủ sân', [
            if (booking.statusReason != null)
              _InfoRow(
                icon: Icons.message_outlined,
                label: 'Lý do',
                value: booking.statusReason!,
              ),
            if (booking.ownerNote != null)
              _InfoRow(
                icon: Icons.note_outlined,
                label: 'Ghi chú',
                value: booking.ownerNote!,
              ),
            if (booking.cancellationReason != null)
              _InfoRow(
                icon: Icons.cancel_outlined,
                label: 'Lý do hủy',
                value: booking.cancellationReason!,
              ),
          ]),
        ],
        const SizedBox(height: 12),
        // Timeline
        _buildTimeline(booking),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatusSection(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trạng thái đặt sân',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                BookingStatusBadge(status: booking.status),
              ],
            ),
          ),
          Text(
            'ID: ${booking.id.substring(booking.id.length > 8 ? booking.id.length - 8 : 0)}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Booking booking) {
    final events = <(DateTime?, String, IconData)>[
      (booking.createdAt, 'Tạo đặt sân', Icons.add_circle_outline_rounded),
      if (booking.confirmedAt != null)
        (
          booking.confirmedAt,
          'Chủ sân xác nhận',
          Icons.check_circle_outline_rounded,
        ),
      if (booking.rejectedAt != null)
        (booking.rejectedAt, 'Chủ sân từ chối', Icons.cancel_outlined),
      if (booking.cancelledAt != null)
        (booking.cancelledAt, 'Đã hủy', Icons.remove_circle_outline_rounded),
      if (booking.completedAt != null)
        (booking.completedAt, 'Hoàn thành', Icons.sports_soccer_rounded),
    ];

    return _buildInfoCard(
      'Lịch sử',
      events.map((e) {
        final (dt, label, icon) = e;
        return _InfoRow(
          icon: icon,
          label: dt != null ? _formatDateTime(dt) : '--',
          value: label,
        );
      }).toList(),
    );
  }

  bool _canCancel(Booking booking) {
    return booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.confirmed;
  }

  Widget _buildBottomCancelBar(Booking booking) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, -3),
            blurRadius: 8,
          ),
        ],
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _controller.isCancelling
              ? null
              : () => _showCancelDialog(booking),
          icon: _controller.isCancelling
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.cancel_outlined, color: Colors.white),
          label: Text(
            _controller.isCancelling ? 'Đang hủy...' : 'Hủy đặt sân',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.dangerRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(Booking booking) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy đặt sân'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn hủy lịch đặt sân tại "${booking.fieldNameSnapshot}"?',
            ),
            const SizedBox(height: 8),
            Text(
              'Trạng thái hiện tại: ${booking.status == BookingStatus.pending ? "Chờ xác nhận" : "Đã xác nhận"}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy (không bắt buộc)',
                hintText: 'Nhập lý do...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);
              final success = await AsyncActionRunner.run(
                context,
                loadingTitle: 'Đang hủy đặt sân',
                loadingMessage: 'Vui lòng chờ trong giây lát...',
                action: () => _controller.cancelBooking(reason: reason),
              );
              if (mounted && success == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã hủy đặt sân thành công.'),
                    backgroundColor: AppTheme.primaryDarkGreen,
                  ),
                );
              }
            },
            child: const Text(
              'Hủy đặt sân',
              style: TextStyle(color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month} ${_fmt(local)}';
  }

  String _fmtPrice(int price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toString();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style:
                      valueStyle ??
                      const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

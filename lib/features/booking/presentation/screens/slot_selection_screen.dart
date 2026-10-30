import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/booking_repository.dart';
import '../../domain/models/field_slot.dart';
import '../../domain/models/football_field.dart';
import '../controllers/booking_controllers.dart';
import 'booking_detail_screen.dart';

/// Màn hình xác nhận đặt sân — hiển thị summary và cho nhập ghi chú
class SlotSelectionScreen extends StatefulWidget {
  final FootballField field;
  final List<FieldSlot> selectedSlots;
  final int totalAmount;
  final String currency;
  final BookingRepository repository;

  const SlotSelectionScreen({
    super.key,
    required this.field,
    required this.selectedSlots,
    required this.totalAmount,
    required this.currency,
    required this.repository,
  });

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  late final CreateBookingController _controller;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = CreateBookingController(repository: widget.repository);
    _controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const weekDays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
    return '${weekDays[local.weekday - 1]}, ${local.day}/${local.month}/${local.year}';
  }

  String _fmtPrice(int price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toString();
  }

  @override
  Widget build(BuildContext context) {
    final slots = widget.selectedSlots;
    final firstSlot = slots.first;
    final lastSlot = slots.last;
    final totalMinutes = slots.fold(0, (sum, s) => sum + s.durationMinutes);

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đặt sân')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Field info card
          _SummaryCard(
            title: 'Thông tin sân',
            children: [
              _SummaryRow(
                icon: Icons.sports_soccer_rounded,
                label: 'Sân',
                value: widget.field.name,
                valueStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              _SummaryRow(
                icon: Icons.location_on_outlined,
                label: 'Địa chỉ',
                value: widget.field.address,
              ),
              _SummaryRow(
                icon: Icons.people_rounded,
                label: 'Loại sân',
                value: widget.field.fieldType,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Booking details card
          _SummaryCard(
            title: 'Chi tiết đặt sân',
            children: [
              _SummaryRow(
                icon: Icons.calendar_today_outlined,
                label: 'Ngày',
                value: _formatDate(firstSlot.startsAt),
              ),
              _SummaryRow(
                icon: Icons.access_time_rounded,
                label: 'Khung giờ',
                value: '${_fmt(firstSlot.startsAt)} – ${_fmt(lastSlot.endsAt)}',
                valueStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              _SummaryRow(
                icon: Icons.hourglass_empty_rounded,
                label: 'Thời lượng',
                value: '${totalMinutes ~/ 60} giờ${totalMinutes % 60 > 0 ? ' ${totalMinutes % 60} phút' : ''}',
              ),
              _SummaryRow(
                icon: Icons.layers_rounded,
                label: 'Số ca',
                value: '${slots.length} khung giờ',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Price breakdown
          _SummaryCard(
            title: 'Chi phí',
            children: [
              ...slots.map(
                (s) => _SummaryRow(
                  icon: Icons.timer_outlined,
                  label: '${_fmt(s.startsAt)}–${_fmt(s.endsAt)}',
                  value: '${_fmtPrice(s.basePrice)} ${s.currency}',
                ),
              ),
              const Divider(height: 16),
              _SummaryRow(
                icon: Icons.payments_rounded,
                label: 'Tổng cộng',
                value: '${_fmtPrice(widget.totalAmount)} ${widget.currency}',
                valueStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Note
          _SummaryCard(
            title: 'Ghi chú (không bắt buộc)',
            children: [
              TextField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Nhập ghi chú cho chủ sân...',
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Policy note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Booking sẽ ở trạng thái "Chờ xác nhận" cho đến khi chủ sân phê duyệt. '
                    'Không thanh toán trước, chỉ thanh toán khi xác nhận tại sân.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Error message
          if (_controller.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.dangerRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _controller.errorMessage!,
                      style: const TextStyle(color: AppTheme.dangerRed, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _controller.isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _controller.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Xác nhận đặt sân', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final slotIds = widget.selectedSlots.map((s) => s.id).toList();
    final success = await _controller.submit(
      fieldId: widget.field.id,
      slotIds: slotIds,
      customerNote: _noteController.text.trim(),
    );

    if (!mounted) return;

    if (success && _controller.createdBooking != null) {
      // Navigate to booking detail
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BookingDetailScreen(
            bookingId: _controller.createdBooking!.id,
            repository: widget.repository,
            isNewBooking: true,
          ),
        ),
        (route) => route.isFirst,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared summary widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SummaryCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
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
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

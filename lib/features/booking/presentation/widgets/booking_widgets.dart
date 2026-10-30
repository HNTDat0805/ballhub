import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/field_slot.dart';
import '../../domain/models/football_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BookingStatusBadge — Huy hiệu trạng thái booking
// ─────────────────────────────────────────────────────────────────────────────

class BookingStatusBadge extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label, icon) = switch (status) {
      BookingStatus.pending => (
          Colors.amber.shade50,
          Colors.amber.shade900,
          'Chờ xác nhận',
          Icons.schedule_rounded,
        ),
      BookingStatus.confirmed => (
          Colors.green.shade50,
          Colors.green.shade800,
          'Đã xác nhận',
          Icons.check_circle_rounded,
        ),
      BookingStatus.rejected => (
          Colors.red.shade50,
          Colors.red.shade800,
          'Bị từ chối',
          Icons.cancel_rounded,
        ),
      BookingStatus.cancelledByUser => (
          Colors.grey.shade100,
          Colors.grey.shade700,
          'Đã hủy',
          Icons.remove_circle_rounded,
        ),
      BookingStatus.cancelledByOwner => (
          Colors.orange.shade50,
          Colors.orange.shade900,
          'Chủ sân hủy',
          Icons.block_rounded,
        ),
      BookingStatus.completed => (
          Colors.blue.shade50,
          Colors.blue.shade800,
          'Hoàn thành',
          Icons.sports_soccer_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FieldStatusBadge — Huy hiệu trạng thái sân
// ─────────────────────────────────────────────────────────────────────────────

class FieldStatusBadge extends StatelessWidget {
  final FieldStatus status;

  const FieldStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      FieldStatus.active => (Colors.green.shade50, Colors.green.shade800, 'Đang hoạt động'),
      FieldStatus.inactive => (Colors.grey.shade100, Colors.grey.shade700, 'Tạm ngừng'),
      FieldStatus.draft => (Colors.blue.shade50, Colors.blue.shade800, 'Nháp'),
      FieldStatus.maintenance => (Colors.orange.shade50, Colors.orange.shade900, 'Bảo trì'),
      FieldStatus.archived => (Colors.red.shade50, Colors.red.shade800, 'Đã ẩn'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FieldCard — Thẻ hiển thị thông tin sân trong danh sách
// ─────────────────────────────────────────────────────────────────────────────

class FieldCard extends StatelessWidget {
  final FootballField field;
  final VoidCallback? onTap;

  const FieldCard({super.key, required this.field, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            _FieldCoverImage(imageUrl: field.coverImageUrl, fieldType: field.fieldType),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          field.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FieldStatusBadge(status: field.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Address
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${field.district.isNotEmpty ? '${field.district}, ' : ''}${field.city}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price + amenities
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_formatPrice(field.basePrice)} ${field.currency}/giờ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FieldTypeChip(fieldType: field.fieldType),
                    ],
                  ),
                  if (field.amenities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _AmenitiesRow(amenities: field.amenities),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(int price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toString();
  }
}

class _FieldCoverImage extends StatelessWidget {
  final String imageUrl;
  final String fieldType;

  const _FieldCoverImage({required this.imageUrl, required this.fieldType});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => _placeholder(),
                )
              : _placeholder(),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 48, color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
          const SizedBox(height: 4),
          Text(
            fieldType,
            style: TextStyle(
              color: AppTheme.primaryGreen.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldTypeChip extends StatelessWidget {
  final String fieldType;

  const _FieldTypeChip({required this.fieldType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        fieldType,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.darkNavy,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AmenitiesRow extends StatelessWidget {
  final List<String> amenities;

  const _AmenitiesRow({required this.amenities});

  static const _amenityIcons = <String, IconData>{
    'wifi': Icons.wifi_rounded,
    'parking': Icons.local_parking_rounded,
    'shower': Icons.shower_rounded,
    'lighting': Icons.light_mode_rounded,
    'locker': Icons.lock_rounded,
    'canteen': Icons.restaurant_rounded,
    'tribune': Icons.stadium_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final displayAmenities = amenities.take(4).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: displayAmenities.map((a) {
        final icon = _amenityIcons[a.toLowerCase()] ?? Icons.check_circle_outline_rounded;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.textSecondary),
            const SizedBox(width: 3),
            Text(a, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TimeSlotTile — Thẻ hiển thị một khung giờ trong danh sách slot
// ─────────────────────────────────────────────────────────────────────────────

/// UI state mở rộng cho slot (không lưu DB)
enum SlotUiState { available, selected, held, booked, blocked, disabled }

class TimeSlotTile extends StatelessWidget {
  final FieldSlot slot;
  final bool isSelected;
  final VoidCallback? onTap;

  const TimeSlotTile({
    super.key,
    required this.slot,
    this.isSelected = false,
    this.onTap,
  });

  SlotUiState get _uiState {
    if (isSelected) return SlotUiState.selected;
    return switch (slot.status) {
      FieldSlotStatus.available => SlotUiState.available,
      FieldSlotStatus.held => SlotUiState.held,
      FieldSlotStatus.booked => SlotUiState.booked,
      FieldSlotStatus.blocked => SlotUiState.blocked,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = _uiState;
    final (bg, border, textColor, label, labelColor, canTap) = _stateVisuals(state);

    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            // Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_fmt(slot.startsAt)} – ${_fmt(slot.endsAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${slot.durationMinutes} phút',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Price
            if (state == SlotUiState.available || state == SlotUiState.selected)
              Text(
                _formatPrice(slot.basePrice, slot.currency),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: state == SlotUiState.selected ? AppTheme.primaryGreen : AppTheme.textPrimary,
                ),
              ),
            const SizedBox(width: 10),
            // State badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: labelColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, Color, String, Color, bool) _stateVisuals(SlotUiState state) {
    return switch (state) {
      SlotUiState.available => (
          Colors.white,
          const Color(0xFFE0E0E0),
          AppTheme.textPrimary,
          'Trống',
          AppTheme.primaryGreen,
          true,
        ),
      SlotUiState.selected => (
          AppTheme.primaryGreen.withValues(alpha: 0.08),
          AppTheme.primaryGreen,
          AppTheme.primaryGreen,
          'Đã chọn',
          AppTheme.primaryGreen,
          true,
        ),
      SlotUiState.held => (
          Colors.amber.shade50,
          Colors.amber.shade200,
          Colors.amber.shade900,
          'Đang giữ',
          Colors.amber.shade900,
          false,
        ),
      SlotUiState.booked => (
          Colors.red.shade50,
          Colors.red.shade200,
          Colors.red.shade900,
          'Đã đặt',
          Colors.red.shade800,
          false,
        ),
      SlotUiState.blocked => (
          Colors.grey.shade100,
          Colors.grey.shade300,
          Colors.grey.shade600,
          'Không khả dụng',
          Colors.grey.shade600,
          false,
        ),
      SlotUiState.disabled => (
          Colors.grey.shade50,
          Colors.grey.shade200,
          Colors.grey.shade400,
          'Vô hiệu',
          Colors.grey.shade400,
          false,
        ),
    };
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(int price, String currency) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return '$price $currency';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BookingCard — Thẻ hiển thị tóm tắt một booking
// ─────────────────────────────────────────────────────────────────────────────

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;

  const BookingCard({super.key, required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: field name + status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.fieldNameSnapshot,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  BookingStatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 8),
              // Address
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.fieldAddressSnapshot,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Date + time
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(booking.startsAt),
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${_fmt(booking.startsAt)} – ${_fmt(booking.endsAt)}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Price
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatPrice(booking.totalAmount)} ${booking.currency}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 20),
                ],
              ),
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

  String _formatPrice(int price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LoadingState, EmptyState, ErrorState — reusable states
// ─────────────────────────────────────────────────────────────────────────────

class BookingLoadingState extends StatelessWidget {
  final String? message;

  const BookingLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryGreen),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class BookingEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const BookingEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.sports_soccer_rounded,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class BookingErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const BookingErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppTheme.dangerRed),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PriceSelectionBar — thanh tổng kết slot đã chọn ở cuối màn hình
// ─────────────────────────────────────────────────────────────────────────────

class PriceSelectionBar extends StatelessWidget {
  final int totalAmount;
  final String currency;
  final int slotCount;
  final int totalMinutes;
  final VoidCallback? onContinue;
  final bool isEnabled;

  const PriceSelectionBar({
    super.key,
    required this.totalAmount,
    required this.currency,
    required this.slotCount,
    required this.totalMinutes,
    this.onContinue,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$slotCount khung giờ • ${totalMinutes ~/ 60}h${totalMinutes % 60 > 0 ? '${totalMinutes % 60}p' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmt(totalAmount)} $currency',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: isEnabled ? onContinue : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: const Text('Tiếp tục đặt sân'),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(int price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toString();
  }
}

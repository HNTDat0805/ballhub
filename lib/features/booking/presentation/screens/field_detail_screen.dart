import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/booking_repository.dart';
import '../../domain/models/field_slot.dart';
import '../../domain/models/football_field.dart';

/// Màn hình Chi tiết Sân bóng & Chọn lịch đặt sân (Page 8 - figma.pdf)
///
/// Bố cục chuẩn Figma Material 3:
/// - AppBar: `← Chi tiết sân` + Icon yêu thích 🤍
/// - Hero Image: Ảnh sân thực tế từ Database / Fallback gradient
/// - Thông tin: Tên sân, Đánh giá, Địa chỉ thực tế
/// - Tiện ích: Đèn LED, Giữ xe, Phòng tắm (lấy từ field.amenities)
/// - Chọn lịch trống:
///   - Horizontal Date Picker: 7 ngày tiếp theo tính từ thời điểm hiện tại
///   - Chú thích: `□ Còn trống` | `✓ Đang chọn` | `▧ Đã đặt`
///   - Ma trận khung giờ (Slot Matrix): Dữ liệu lấy từ API/Database
/// - Bottom Sticky Booking Bar:
///   - Giá, mô tả khung giờ chọn, chính sách hủy 24h, Nút `→ Đặt sân`
class FieldDetailScreen extends StatefulWidget {
  final String fieldId;
  final BookingRepository repository;

  const FieldDetailScreen({
    super.key,
    required this.fieldId,
    required this.repository,
  });

  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  FootballField? _field;
  List<FieldSlot> _slots = [];
  bool _isLoadingField = true;
  bool _isLoadingSlots = false;
  String? _errorMessage;
  bool _isSubmitting = false;

  int _selectedDayIndex = 0;
  String? _selectedSlotId;
  bool _isFavorite = false;

  late final List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _days = List.generate(7, (i) => DateTime(now.year, now.month, now.day + i));
    _loadField();
  }

  String _formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  String _formatMoney(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadField() async {
    setState(() {
      _isLoadingField = true;
      _errorMessage = null;
    });

    try {
      final f = await widget.repository.getFieldById(widget.fieldId);
      if (!mounted) return;
      setState(() {
        _field = f;
        _isLoadingField = false;
      });
      _loadSlotsForDay(_selectedDayIndex);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingField = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadSlotsForDay(int dayIndex) async {
    final dateKey = _formatDateKey(_days[dayIndex]);
    setState(() {
      _isLoadingSlots = true;
      _selectedSlotId = null;
    });

    try {
      final slots = await widget.repository.getFieldSlots(
        widget.fieldId,
        dateKey: dateKey,
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _isLoadingSlots = false;
        // Tự động chọn slot còn trống đầu tiên nếu có
        final available = slots.where((s) => s.status == FieldSlotStatus.available);
        if (available.isNotEmpty) {
          _selectedSlotId = available.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _slots = [];
        _isLoadingSlots = false;
      });
    }
  }

  FieldSlot? get _selectedSlot {
    if (_selectedSlotId == null) return null;
    final found = _slots.where((s) => s.id == _selectedSlotId);
    return found.isNotEmpty ? found.first : null;
  }

  Future<void> _onBookPressed() async {
    final slot = _selectedSlot;
    if (slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một khung giờ còn trống')),
      );
      return;
    }

    final field = _field;
    if (field == null) return;

    final selectedDate = _days[_selectedDayIndex];
    final dateStr = '${_weekdayLabel(selectedDate.weekday)}, ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    final timeStr = '${_formatTime(slot.startsAt)} – ${_formatTime(slot.endsAt)}';
    final priceStr = _formatMoney(slot.basePrice > 0 ? slot.basePrice : field.basePrice);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Xác nhận đặt ${field.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Khung giờ: $timeStr ($dateStr)\nLoại sân: ${field.fieldType.isNotEmpty ? field.fieldType : 'Sân tiêu chuẩn'}\nĐịa chỉ: ${field.address.isNotEmpty ? field.address : '${field.district}, ${field.city}'}\nTổng thanh toán: $priceStr',
              style: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận giữ chỗ ngay'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.repository.createBooking(
        fieldId: field.id,
        slotIds: [slot.id],
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt sân thành công! Bạn có thể xem lịch trong mục Cá nhân.'),
          backgroundColor: AppTheme.primaryDarkGreen,
        ),
      );
      _loadSlotsForDay(_selectedDayIndex);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingField) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Chi tiết sân')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
        ),
      );
    }

    if (_errorMessage != null || _field == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Chi tiết sân')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Không tìm thấy thông tin sân bóng',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadField,
                  child: const Text('Tải lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final field = _field!;
    final selectedSlot = _selectedSlot;
    final slotPrice = selectedSlot != null && selectedSlot.basePrice > 0
        ? selectedSlot.basePrice
        : field.basePrice;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(field.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : AppTheme.textPrimary,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Cover Image
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF15803D), Color(0xFF166534)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: field.coverImageUrl.isNotEmpty
                      ? Image.network(
                          field.coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Center(
                            child: Icon(Icons.stadium, size: 80, color: Colors.white24),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.stadium, size: 80, color: Colors.white24),
                        ),
                ),

                // Thông tin sân
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên & Đánh giá
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              field.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star, size: 16, color: AppTheme.accentGold),
                                SizedBox(width: 4),
                                Text(
                                  '4.8',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Địa chỉ
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              field.address.isNotEmpty
                                  ? field.address
                                  : '${field.district}, ${field.city}',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Hàng tiện ích thực tế
                      if (field.amenities.isNotEmpty)
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: field.amenities.map((a) {
                            return _AmenityPill(
                              icon: _mapAmenityIcon(a),
                              label: a,
                            );
                          }).toList(),
                        )
                      else
                        const Row(
                          children: [
                            _AmenityPill(icon: Icons.lightbulb_outline, label: 'Đèn chiếu sáng'),
                            SizedBox(width: 12),
                            _AmenityPill(icon: Icons.directions_car_outlined, label: 'Chỗ gửi xe'),
                            SizedBox(width: 12),
                            _AmenityPill(icon: Icons.sports_soccer, label: 'Bóng & Áo bib'),
                          ],
                        ),
                      const SizedBox(height: 24),
                      const Divider(height: 1, color: AppTheme.borderColor),
                      const SizedBox(height: 16),

                      // Header Chọn lịch trống
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Chọn lịch trống',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            field.fieldType.isNotEmpty ? field.fieldType : 'Sân tiêu chuẩn',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Horizontal Date Picker (7 ngày thực)
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _days.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final date = _days[i];
                            final active = _selectedDayIndex == i;
                            final dayLabel = _weekdayLabel(date.weekday);
                            final dateLabel = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedDayIndex = i);
                                _loadSlotsForDay(i);
                              },
                              child: Container(
                                width: 58,
                                decoration: BoxDecoration(
                                  color: active ? AppTheme.primaryDarkGreen : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: active ? AppTheme.primaryDarkGreen : AppTheme.borderColor,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dayLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: active ? Colors.white70 : AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateLabel,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: active ? Colors.white : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Chú thích Status Legend
                      const Row(
                        children: [
                          _LegendItem(color: Colors.white, borderColor: AppTheme.borderColor, label: 'Còn trống'),
                          SizedBox(width: 16),
                          _LegendItem(
                            color: AppTheme.primaryLightGreen,
                            borderColor: AppTheme.primaryDarkGreen,
                            label: 'Đang chọn',
                            hasCheck: true,
                          ),
                          SizedBox(width: 16),
                          _LegendItem(color: Color(0xFFF3F4F6), borderColor: Color(0xFFE5E7EB), label: 'Đã đặt'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Slot Matrix từ Database
                      if (_isLoadingSlots)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
                          ),
                        )
                      else if (_slots.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(Icons.event_busy, size: 36, color: AppTheme.textMuted),
                                SizedBox(height: 8),
                                Text(
                                  'Chưa có khung giờ nào được mở trong ngày này',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _slots.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, idx) {
                            final slot = _slots[idx];
                            final isAvailable = slot.status == FieldSlotStatus.available;
                            final isSelected = _selectedSlotId == slot.id;
                            final timeLabel = '${_formatTime(slot.startsAt)} – ${_formatTime(slot.endsAt)}';
                            final priceLabel = isAvailable
                                ? (slot.basePrice > 0 ? _formatMoney(slot.basePrice) : _formatMoney(field.basePrice))
                                : 'Đã đặt';

                            return GestureDetector(
                              onTap: isAvailable
                                  ? () => setState(() => _selectedSlotId = slot.id)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryLightGreen
                                      : !isAvailable
                                          ? const Color(0xFFF3F4F6)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryDarkGreen
                                        : !isAvailable
                                            ? const Color(0xFFE5E7EB)
                                            : AppTheme.borderColor,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (isSelected) ...[
                                          const Icon(Icons.check, size: 14, color: AppTheme.primaryDarkGreen),
                                          const SizedBox(width: 4),
                                        ],
                                        Expanded(
                                          child: Text(
                                            timeLabel,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: !isAvailable ? AppTheme.textMuted : AppTheme.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      priceLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: !isAvailable
                                            ? AppTheme.textMuted
                                            : isSelected
                                                ? AppTheme.primaryDarkGreen
                                                : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMoney(slotPrice),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryDarkGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedSlot != null
                              ? '${_formatTime(selectedSlot.startsAt)} – ${_formatTime(selectedSlot.endsAt)}'
                              : 'Chưa chọn khung giờ',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Hủy miễn phí trước giờ nhận sân 24 giờ.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isSubmitting || selectedSlot == null ? null : _onBookPressed,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_forward, size: 16),
                              SizedBox(width: 6),
                              Text('Đặt sân'),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _mapAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('đèn') || lower.contains('led') || lower.contains('sáng')) {
      return Icons.lightbulb_outline;
    }
    if (lower.contains('xe') || lower.contains('đỗ')) {
      return Icons.directions_car_outlined;
    }
    if (lower.contains('tắm') || lower.contains('nước')) {
      return Icons.shower_outlined;
    }
    if (lower.contains('wifi')) {
      return Icons.wifi;
    }
    return Icons.check_circle_outline;
  }
}

class _AmenityPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AmenityPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryDarkGreen),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String label;
  final bool hasCheck;

  const _LegendItem({
    required this.color,
    required this.borderColor,
    required this.label,
    this.hasCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
          child: hasCheck
              ? const Icon(Icons.check, size: 10, color: AppTheme.primaryDarkGreen)
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

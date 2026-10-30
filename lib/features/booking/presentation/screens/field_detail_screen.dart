import 'package:flutter/material.dart';
import '../../../../core/auth/auth_context.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/booking_repository.dart';
import '../../domain/models/field_slot.dart';
import '../controllers/booking_controllers.dart';
import '../widgets/booking_widgets.dart';
import 'slot_selection_screen.dart';

/// Màn hình chi tiết sân bóng — hiển thị thông tin đầy đủ và danh sách slot
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
  late final FieldDetailController _controller;
  late final SlotSelectionController _slotCtrl;
  late final PageController _imageController;

  @override
  void initState() {
    super.initState();
    _controller = FieldDetailController(repository: widget.repository);
    _slotCtrl = SlotSelectionController();
    _imageController = PageController();
    _controller.addListener(_onUpdate);
    _slotCtrl.addListener(_onUpdate);
    _controller.loadField(widget.fieldId);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _slotCtrl.removeListener(_onUpdate);
    _controller.dispose();
    _slotCtrl.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const BookingLoadingState(message: 'Đang tải thông tin sân...'),
      );
    }

    if (_controller.errorMessage != null && _controller.field == null) {
      return Scaffold(
        appBar: AppBar(),
        body: BookingErrorState(
          message: _controller.errorMessage!,
          onRetry: () => _controller.loadField(widget.fieldId),
        ),
      );
    }

    final field = _controller.field;
    if (field == null) return const SizedBox.shrink();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with cover image
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageCarousel(field.imageUrls.isNotEmpty
                  ? field.imageUrls
                  : field.coverImageUrl.isNotEmpty
                      ? [field.coverImageUrl]
                      : []),
            ),
            title: Text(
              field.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
            leading: const BackButton(color: Colors.white),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + status row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FieldStatusBadge(status: field.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primaryGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          field.address,
                          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Key info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(icon: Icons.people_rounded, label: 'Sân ${field.fieldType}'),
                      _InfoChip(icon: Icons.group_rounded, label: '${field.capacity} người'),
                      _InfoChip(
                        icon: Icons.payments_outlined,
                        label: '${_fmtPrice(field.basePrice)} ${field.currency}/giờ',
                        color: AppTheme.primaryGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Description
                  if (field.description.isNotEmpty) ...[
                    const Text(
                      'Mô tả',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(field.description, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                    const SizedBox(height: 16),
                  ],
                  // Amenities
                  if (field.amenities.isNotEmpty) ...[
                    const Text(
                      'Tiện nghi',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: field.amenities.map((a) => _AmenityChip(label: a)).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Divider(),
                  const SizedBox(height: 8),
                  // Date selector
                  const Text(
                    'Chọn khung giờ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _DateSelector(
                    selectedDateKey: _controller.selectedDateKey,
                    onDateSelected: (dateKey) {
                      _slotCtrl.clearSelection();
                      _controller.selectDate(dateKey);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Slot list
                  _buildSlotList(),
                  // Bottom padding
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom CTA
      bottomNavigationBar: _slotCtrl.hasSelection
          ? PriceSelectionBar(
              totalAmount: _slotCtrl.totalAmount,
              currency: _slotCtrl.currency,
              slotCount: _slotCtrl.selectedSlots.length,
              totalMinutes: _slotCtrl.totalMinutes,
              onContinue: _goToBooking,
            )
          : const _BookingHintBar(),
    );
  }

  Widget _buildImageCarousel(List<String> urls) {
    if (urls.isEmpty) {
      return Container(
        color: AppTheme.primaryGreen.withValues(alpha: 0.2),
        child: Center(
          child: Icon(
            Icons.sports_soccer,
            size: 80,
            color: AppTheme.primaryGreen.withValues(alpha: 0.4),
          ),
        ),
      );
    }
    return PageView.builder(
      controller: _imageController,
      itemCount: urls.length,
      itemBuilder: (_, index) => Image.network(
        urls[index],
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => Container(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
          child: const Icon(Icons.sports_soccer, size: 80, color: AppTheme.primaryGreen),
        ),
      ),
    );
  }

  Widget _buildSlotList() {
    final slots = _controller.slots;

    if (_controller.isLoading) {
      return const SizedBox(
        height: 120,
        child: BookingLoadingState(message: 'Đang tải khung giờ...'),
      );
    }

    if (slots.isEmpty) {
      return const BookingEmptyState(
        title: 'Chưa có khung giờ nào',
        subtitle: 'Sân chưa cài đặt lịch cho ngày này.',
        icon: Icons.event_busy_rounded,
      );
    }

    return Column(
      children: slots.map((slot) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TimeSlotTile(
            slot: slot,
            isSelected: _slotCtrl.isSelected(slot.id),
            onTap: () => _onSlotTap(slot),
          ),
        );
      }).toList(),
    );
  }

  void _onSlotTap(FieldSlot slot) {
    final error = _slotCtrl.toggleSlot(slot);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.warningOrange,
        ),
      );
    }
  }

  void _goToBooking() {
    final user = AuthContext.instance.currentUser;
    if (!user.canBook) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để đặt sân.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SlotSelectionScreen(
          field: _controller.field!,
          selectedSlots: _slotCtrl.selectedSlots.toList(),
          totalAmount: _slotCtrl.totalAmount,
          currency: _slotCtrl.currency,
          repository: widget.repository,
        ),
      ),
    );
  }

  static String _fmtPrice(int price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toString();
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.darkNavy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;

  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE0E0E0)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String selectedDateKey;
  final ValueChanged<String> onDateSelected;

  const _DateSelector({
    required this.selectedDateKey,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Show next 7 days
    final days = List.generate(7, (i) => today.add(Duration(days: i)));

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final day = days[index];
          final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
          final isSelected = key == selectedDateKey;
          final weekDay = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][day.weekday - 1];

          return GestureDetector(
            onTap: () => onDateSelected(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGreen : const Color(0xFFE0E0E0),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekDay,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '/${day.month}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookingHintBar extends StatelessWidget {
  const _BookingHintBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.touch_app_rounded),
            label: const Text('Chọn khung giờ để đặt sân'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

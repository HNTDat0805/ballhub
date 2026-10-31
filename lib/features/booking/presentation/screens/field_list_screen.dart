import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/booking_repository.dart';
import '../../domain/models/football_field.dart';
import '../controllers/booking_controllers.dart';
import 'field_detail_screen.dart';
import '../../../../widgets/province_picker_modal.dart';
import '../../../../widgets/filter_selection_modal.dart';

/// Màn hình Danh sách Sân bóng (Page 7 - figma.pdf)
class FieldListScreen extends StatefulWidget {
  final BookingRepository repository;

  const FieldListScreen({super.key, required this.repository});

  @override
  State<FieldListScreen> createState() => _FieldListScreenState();
}

class _FieldListScreenState extends State<FieldListScreen> {
  late final FieldListController _controller;
  final _searchController = TextEditingController();
  int _selectedFilter = 0; // 0 = Tất cả, 1 = Tỉnh/Thành, 2 = Loại sân
  String _selectedCity = 'TP. Hồ Chí Minh';
  String? _selectedFieldType;
  String _selectedFieldTypeLabel = 'Sân 7 người';

  @override
  void initState() {
    super.initState();
    _controller = FieldListController(repository: widget.repository);
    _controller.addListener(_onControllerUpdate);
    _controller.loadFields();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Tìm sân bóng'),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm tên sân, địa chỉ',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _controller.setSearchQuery('');
                          _controller.loadFields();
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                _controller.setSearchQuery(val);
                _controller.loadFields();
              },
            ),
          ),

          // Filter Chips: 1. Tất cả | 2. Chọn thành phố | 3. Loại sân (sổ xuống)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip(
                  0,
                  'Tất cả',
                  onTap: () {
                    setState(() {
                      _selectedFilter = 0;
                      _selectedFieldType = null;
                      _selectedFieldTypeLabel = 'Sân 7 người';
                    });
                    _controller.setCityFilter(null);
                    _controller.setFieldTypeFilter(null);
                    _controller.loadFields();
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  1,
                  '$_selectedCity ⌄',
                  onTap: () async {
                    final chosen = await ProvincePickerModal.show(context, currentProvince: _selectedCity);
                    if (chosen != null) {
                      setState(() {
                        _selectedCity = chosen;
                        _selectedFilter = 1;
                      });
                      _controller.setCityFilter(chosen);
                      _controller.setFieldTypeFilter(_selectedFieldType);
                      _controller.loadFields();
                    } else {
                      setState(() => _selectedFilter = 1);
                      _controller.setCityFilter(_selectedCity);
                      _controller.setFieldTypeFilter(_selectedFieldType);
                      _controller.loadFields();
                    }
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  2,
                  '$_selectedFieldTypeLabel ⌄',
                  onTap: () async {
                    final chosen = await FilterSelectionModal.show<String?>(
                      context,
                      title: 'Chọn loại sân bóng',
                      selectedValue: _selectedFieldType ?? '7-a-side',
                      options: const [
                        FilterOption(value: 'all', label: 'Tất cả loại sân', subtitle: 'Hiển thị mọi quy mô sân'),
                        FilterOption(value: '5-a-side', label: 'Sân 5 người', subtitle: '5 vs 5 · Sân bóng đá mini'),
                        FilterOption(value: '7-a-side', label: 'Sân 7 người', subtitle: '7 vs 7 · Tiêu chuẩn phong trào'),
                        FilterOption(value: '11-a-side', label: 'Sân 11 người', subtitle: '11 vs 11 · Sân lớn 11 người tiêu chuẩn'),
                        FilterOption(value: 'futsal', label: 'Sân Futsal', subtitle: 'Bóng đá trong nhà mặt sàn thảm/gỗ'),
                      ],
                    );
                    if (chosen != null) {
                      setState(() {
                        _selectedFilter = 2;
                        if (chosen == 'all') {
                          _selectedFieldType = null;
                          _selectedFieldTypeLabel = 'Loại sân';
                          _controller.setFieldTypeFilter(null);
                        } else {
                          _selectedFieldType = chosen;
                          switch (chosen) {
                            case '5-a-side':
                              _selectedFieldTypeLabel = 'Sân 5 người';
                              break;
                            case '7-a-side':
                              _selectedFieldTypeLabel = 'Sân 7 người';
                              break;
                            case '11-a-side':
                              _selectedFieldTypeLabel = 'Sân 11 người';
                              break;
                            case 'futsal':
                              _selectedFieldTypeLabel = 'Sân Futsal';
                              break;
                          }
                          _controller.setFieldTypeFilter(chosen);
                        }
                      });
                      _controller.loadFields();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Subheader: Số lượng sân thực tế
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _controller.isLoading
                      ? 'Đang tìm kiếm sân bóng...'
                      : '${_controller.fields.length} sân bóng có sẵn',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chế độ xem bản đồ đang mở')),
                    );
                  },
                  child: const Text(
                    'Bản đồ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDarkGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Danh sách sân bóng từ Database
          Expanded(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen))
                : _controller.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                            const SizedBox(height: 12),
                            Text(
                              _controller.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _controller.loadFields(),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _controller.fields.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.sports_soccer,
                                    size: 64,
                                    color: AppTheme.textMuted.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Chưa có sân bóng nào',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Hãy thử xóa bộ lọc hoặc kiểm tra lại sau.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _searchController.clear();
                                      _controller.setSearchQuery('');
                                      _controller.loadFields();
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Làm mới'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: AppTheme.primaryDarkGreen,
                            onRefresh: () => _controller.loadFields(),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: _controller.fields.length,
                              itemBuilder: (context, index) {
                                final f = _controller.fields[index];
                                return _buildDynamicFieldCard(f);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(int index, String label, {required VoidCallback onTap}) {
    final active = _selectedFilter == index;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryLightGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppTheme.primaryDarkGreen : AppTheme.borderColor,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? AppTheme.primaryDarkGreen : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicFieldCard(FootballField field) {
    final priceStr = field.basePrice > 0
        ? '${field.basePrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ/giờ'
        : 'Liên hệ giá';
    final isActive = field.status == FieldStatus.active;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FieldDetailScreen(
                fieldId: field.id,
                repository: widget.repository,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sân cỏ
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF15803D), Color(0xFF166534)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (field.coverImageUrl.isNotEmpty)
                      Image.network(
                        field.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Center(
                          child: Icon(Icons.sports_soccer, size: 60, color: Colors.white24),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(Icons.sports_soccer, size: 60, color: Colors.white24),
                      ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black45,
                        child: Text(
                          field.fieldType.isNotEmpty ? field.fieldType : 'Sân',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Thông tin sân
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          field.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, size: 14, color: AppTheme.accentGold),
                            SizedBox(width: 4),
                            Text(
                              '4.8',
                              style: TextStyle(
                                fontSize: 12,
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
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          field.address.isNotEmpty
                              ? field.address
                              : '${field.district}, ${field.city}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priceStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryDarkGreen,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primaryLightGreen : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? 'Còn giờ trống' : 'Tạm dừng',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? AppTheme.primaryDarkGreen : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

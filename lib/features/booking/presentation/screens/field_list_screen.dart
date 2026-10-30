import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/booking_repository.dart';
import '../../domain/models/football_field.dart';
import '../controllers/booking_controllers.dart';
import '../widgets/booking_widgets.dart';
import 'field_detail_screen.dart';

/// Màn hình danh sách sân bóng — cho phép search và filter
class FieldListScreen extends StatefulWidget {
  final BookingRepository repository;

  const FieldListScreen({super.key, required this.repository});

  @override
  State<FieldListScreen> createState() => _FieldListScreenState();
}

class _FieldListScreenState extends State<FieldListScreen> {
  late final FieldListController _controller;
  final _searchController = TextEditingController();

  // Danh sách fieldType phổ biến
  static const _fieldTypes = ['5 người', '7 người', '11 người'];
  static const _cities = ['Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng', 'Cần Thơ', 'Hải Phòng'];

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
      appBar: AppBar(
        title: const Text('Tìm sân bóng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _controller.loadFields,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm tên sân...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _controller.setSearchQuery('');
                        _controller.loadFields();
                      },
                    )
                  : null,
            ),
            onSubmitted: (value) {
              _controller.setSearchQuery(value);
              _controller.loadFields();
            },
            onChanged: (value) {
              if (value.isEmpty) {
                _controller.setSearchQuery('');
                _controller.loadFields();
              }
            },
          ),
          const SizedBox(height: 10),
          // Filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // City filter
                _buildDropdownChip(
                  label: _controller.cityFilter ?? 'Tất cả thành phố',
                  items: _cities,
                  selected: _controller.cityFilter,
                  onChanged: (v) {
                    _controller.setCityFilter(v);
                    _controller.loadFields();
                  },
                  onClear: () {
                    _controller.setCityFilter(null);
                    _controller.loadFields();
                  },
                ),
                const SizedBox(width: 8),
                // Field type filter
                _buildDropdownChip(
                  label: _controller.fieldTypeFilter ?? 'Loại sân',
                  items: _fieldTypes,
                  selected: _controller.fieldTypeFilter,
                  onChanged: (v) {
                    _controller.setFieldTypeFilter(v);
                    _controller.loadFields();
                  },
                  onClear: () {
                    _controller.setFieldTypeFilter(null);
                    _controller.loadFields();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownChip({
    required String label,
    required List<String> items,
    String? selected,
    required ValueChanged<String?> onChanged,
    required VoidCallback onClear,
  }) {
    final isActive = selected != null;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down_rounded,
            size: 16,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ],
      ),
      selected: isActive,
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isActive ? AppTheme.primaryGreen : const Color(0xFFE0E0E0),
      ),
      onSelected: (_) {
        _showFilterMenu(items, selected, onChanged, onClear);
      },
    );
  }

  void _showFilterMenu(
    List<String> items,
    String? selected,
    ValueChanged<String?> onChanged,
    VoidCallback onClear,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tất cả'),
              trailing: selected == null ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
              onTap: () {
                onClear();
                Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            ...items.map(
              (item) => ListTile(
                title: Text(item),
                trailing: selected == item ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
                onTap: () {
                  onChanged(item);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const BookingLoadingState(message: 'Đang tải danh sách sân...');
    }

    if (_controller.errorMessage != null) {
      return BookingErrorState(
        message: _controller.errorMessage!,
        onRetry: _controller.loadFields,
      );
    }

    if (_controller.fields.isEmpty) {
      return const BookingEmptyState(
        title: 'Không tìm thấy sân nào',
        subtitle: 'Thử thay đổi bộ lọc hoặc từ khoá tìm kiếm.',
        icon: Icons.search_off_rounded,
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _controller.loadFields,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _controller.fields.length,
        itemBuilder: (ctx, index) {
          final field = _controller.fields[index];
          return FieldCard(
            field: field,
            onTap: () => _openFieldDetail(field),
          );
        },
      ),
    );
  }

  void _openFieldDetail(FootballField field) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FieldDetailScreen(
          fieldId: field.id,
          repository: widget.repository,
        ),
      ),
    );
  }
}

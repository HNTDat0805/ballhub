import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/province_service.dart';

/// Modal Bottom Sheet cho phép tìm kiếm và lựa chọn Tỉnh / Thành phố
class ProvincePickerModal extends StatefulWidget {
  final String currentProvince;

  const ProvincePickerModal({
    super.key,
    required this.currentProvince,
  });

  /// Hiển thị Modal chọn Tỉnh thành và trả về tên Tỉnh thành được chọn
  static Future<String?> show(BuildContext context, {required String currentProvince}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProvincePickerModal(currentProvince: currentProvince),
    );
  }

  @override
  State<ProvincePickerModal> createState() => _ProvincePickerModalState();
}

class _ProvincePickerModalState extends State<ProvincePickerModal> {
  final _searchController = TextEditingController();
  List<Province> _allProvinces = [];
  List<Province> _filteredProvinces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    final list = await ProvinceService.getProvinces();
    if (!mounted) return;
    setState(() {
      _allProvinces = list;
      _filteredProvinces = list;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredProvinces = ProvinceService.searchProvinces(_allProvinces, query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: AppTheme.primaryDarkGreen, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Chọn Tỉnh / Thành phố',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Đóng',
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tỉnh thành (VD: Hà Nội, Đà Nẵng...)',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Shortcut chips cho các thành phố lớn
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildQuickChip('TP. Hồ Chí Minh'),
                _buildQuickChip('Hà Nội'),
                _buildQuickChip('Đà Nẵng'),
                _buildQuickChip('Bình Dương'),
                _buildQuickChip('Hải Phòng'),
                _buildQuickChip('Cần Thơ'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // Listview
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
                  )
                : _filteredProvinces.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Không tìm thấy tỉnh thành "${_searchController.text}"',
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredProvinces.length,
                        separatorBuilder: (_, index) => const Divider(height: 1, indent: 56),
                        itemBuilder: (context, index) {
                          final p = _filteredProvinces[index];
                          final isSelected = widget.currentProvince.toLowerCase().contains(p.displayName.toLowerCase()) ||
                              widget.currentProvince.toLowerCase().contains(p.name.toLowerCase());

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: isSelected
                                  ? AppTheme.primaryLightGreen
                                  : AppTheme.surfaceColor,
                              child: Icon(
                                Icons.location_city_outlined,
                                size: 18,
                                color: isSelected
                                    ? AppTheme.primaryDarkGreen
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            title: Text(
                              p.displayName,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppTheme.primaryDarkGreen : AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              p.name,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppTheme.primaryDarkGreen, size: 20)
                                : null,
                            onTap: () {
                              Navigator.pop(context, p.displayName);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    final isSelected = widget.currentProvince.toLowerCase().contains(label.toLowerCase());

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: ActionChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppTheme.textPrimary,
        ),
        backgroundColor: isSelected ? AppTheme.primaryDarkGreen : AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryDarkGreen : Colors.grey.shade300,
        ),
        onPressed: () {
          Navigator.pop(context, label);
        },
      ),
    );
  }
}

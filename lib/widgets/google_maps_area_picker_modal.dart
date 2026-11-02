import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/places_service.dart';
import '../services/province_service.dart';

/// Đại diện cho một địa điểm / khu vực gợi ý kiểu Google Maps Place
class GoogleMapPlace {
  final String title;
  final String subtitle;
  final String fullAddress;
  final String type; // 'district', 'stadium', 'province', 'hub'
  final double latitude;
  final double longitude;
  final String? placeId;

  const GoogleMapPlace({
    required this.title,
    required this.subtitle,
    required this.fullAddress,
    this.type = 'district',
    this.latitude = 10.7769,
    this.longitude = 106.7009,
    this.placeId,
  });
}

/// Modal chọn khu vực thiết kế và logic chuẩn Google Maps:
/// 1. Thanh tìm kiếm Google Maps với auto-complete thời gian thực
/// 2. Bản đồ trực quan tương tác (kéo, thả, ghim vị trí, phóng to/thu nhỏ)
/// 3. Gợi ý sân bóng & quận huyện phổ biến
/// 4. Hỗ trợ chọn nhanh theo phân cấp Tỉnh/Thành phố & Quận/Huyện từ ProvinceService
/// 5. Nút "Vị trí hiện tại của tôi" (GPS)
class GoogleMapsAreaPickerModal extends StatefulWidget {
  final String initialArea;

  const GoogleMapsAreaPickerModal({super.key, this.initialArea = ''});

  /// Hiển thị Modal chọn khu vực kiểu Google Maps và trả về chuỗi khu vực được chọn
  static Future<String?> show(BuildContext context, {String initialArea = ''}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GoogleMapsAreaPickerModal(initialArea: initialArea),
    );
  }

  @override
  State<GoogleMapsAreaPickerModal> createState() =>
      _GoogleMapsAreaPickerModalState();
}

class _GoogleMapsAreaPickerModalState extends State<GoogleMapsAreaPickerModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late TabController _tabController;
  late GoogleMapPlace _selectedPlace;

  List<GoogleMapPlace> _suggestions = [];
  bool _isSearching = false;
  double _zoomLevel = 1.0;
  Offset _mapOffset = Offset.zero;
  bool _isSatelliteMode = false;
  Timer? _searchDebounceTimer;
  String? _modalSessionToken;

  // Dữ liệu Tỉnh/Quận huyện chuẩn
  List<Province> _allProvinces = [];
  String _selectedProvince = 'TP. Hồ Chí Minh';
  List<String> _districtsOfProvince = [];

  // Danh sách các sân bóng & hub bóng đá phổ biến tại Việt Nam
  static final List<GoogleMapPlace> _popularFootballHubs = [
    const GoogleMapPlace(
      title: 'TP. Thủ Đức',
      subtitle: 'Khu vực trung tâm thể thao & giải đấu phong trào, TP.HCM',
      fullAddress: 'TP. Thủ Đức, TP. Hồ Chí Minh',
      type: 'district',
      latitude: 10.8494,
      longitude: 106.7717,
    ),
    const GoogleMapPlace(
      title: 'Quận Bình Thạnh',
      subtitle: 'Cụm sân cỏ nhân tạo Chu Văn An & Ung Văn Khiêm, TP.HCM',
      fullAddress: 'Quận Bình Thạnh, TP. Hồ Chí Minh',
      type: 'district',
      latitude: 10.8016,
      longitude: 106.7113,
    ),
    const GoogleMapPlace(
      title: 'Quận Tân Bình',
      subtitle: 'Khu liên hợp thể thao Chảo Lửa & Sân bay Tân Sơn Nhất, TP.HCM',
      fullAddress: 'Quận Tân Bình, TP. Hồ Chí Minh',
      type: 'stadium',
      latitude: 10.8014,
      longitude: 106.6526,
    ),
    const GoogleMapPlace(
      title: 'Quận 7',
      subtitle: 'Cụm sân bóng đá Nam Sài Gòn & Phú Mỹ Hưng, TP.HCM',
      fullAddress: 'Quận 7, TP. Hồ Chí Minh',
      type: 'district',
      latitude: 10.7340,
      longitude: 106.7218,
    ),
    const GoogleMapPlace(
      title: 'Quận Cầu Giấy',
      subtitle: 'Trung tâm thể thao Cầu Giấy & SVĐ Đại học Sư Phạm, Hà Nội',
      fullAddress: 'Quận Cầu Giấy, Hà Nội',
      type: 'district',
      latitude: 21.0362,
      longitude: 105.7906,
    ),
    const GoogleMapPlace(
      title: 'Quận Nam Từ Liêm',
      subtitle: 'Khu liên hợp thể thao Mỹ Đình & Sân bóng Lê Đức Thọ, Hà Nội',
      fullAddress: 'Quận Nam Từ Liêm, Hà Nội',
      type: 'stadium',
      latitude: 21.0167,
      longitude: 105.7644,
    ),
    const GoogleMapPlace(
      title: 'Quận Đống Đa',
      subtitle: 'Cụm sân cỏ nhân tạo Hoàng Cầu & Thủy Lợi, Hà Nội',
      fullAddress: 'Quận Đống Đa, Hà Nội',
      type: 'district',
      latitude: 21.0181,
      longitude: 105.8299,
    ),
    const GoogleMapPlace(
      title: 'Quận Hải Châu',
      subtitle: 'Cụm sân bóng Tuyên Sơn & Quân khu 5, TP. Đà Nẵng',
      fullAddress: 'Quận Hải Châu, Đà Nẵng',
      type: 'stadium',
      latitude: 16.0544,
      longitude: 108.2208,
    ),
    const GoogleMapPlace(
      title: 'TP. Biên Hòa',
      subtitle: 'Cụm sân thể thao Đồng Nai & Hóa An',
      fullAddress: 'TP. Biên Hòa, Đồng Nai',
      type: 'district',
      latitude: 10.9575,
      longitude: 106.8426,
    ),
    const GoogleMapPlace(
      title: 'TP. Thủ Dầu Một',
      subtitle: 'Trung tâm thể thao Gò Đậu & Thành phố Mới Bình Dương',
      fullAddress: 'TP. Thủ Dầu Một, Bình Dương',
      type: 'district',
      latitude: 10.9804,
      longitude: 106.6519,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Xác định địa điểm ban đầu
    if (widget.initialArea.trim().isNotEmpty) {
      _selectedPlace = GoogleMapPlace(
        title: widget.initialArea.split(',').first.trim(),
        subtitle: 'Khu vực hoạt động hiện tại của đội bóng',
        fullAddress: widget.initialArea.trim(),
      );
      _searchController.text = widget.initialArea.trim();
    } else {
      _selectedPlace = _popularFootballHubs.first;
    }

    _suggestions = _popularFootballHubs;
    _loadProvincesData();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProvincesData() async {
    final list = await ProvinceService.getProvinces();
    if (!mounted) return;
    setState(() {
      _allProvinces = list;
      _districtsOfProvince = ProvinceService.getDistricts(_selectedProvince);
    });
  }

  void _onSearchQueryChanged(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _searchDebounceTimer?.cancel();
      _modalSessionToken = null;
      setState(() {
        _isSearching = false;
        _suggestions = _popularFootballHubs;
      });
      return;
    }

    setState(() => _isSearching = true);

    // 1. Khớp nhanh từ dữ liệu nội bộ (Hub + Tỉnh/Quận huyện) để phản hồi tức thời
    final matches = <GoogleMapPlace>[];

    for (final hub in _popularFootballHubs) {
      if (hub.title.toLowerCase().contains(q) ||
          hub.fullAddress.toLowerCase().contains(q) ||
          hub.subtitle.toLowerCase().contains(q)) {
        matches.add(hub);
      }
    }

    for (final province in _allProvinces) {
      final districts = ProvinceService.getDistricts(province.displayName);
      for (final dist in districts) {
        final full = '$dist, ${province.displayName}';
        if (dist.toLowerCase().contains(q) ||
            province.displayName.toLowerCase().contains(q) ||
            full.toLowerCase().contains(q)) {
          if (!matches.any((m) => m.fullAddress == full)) {
            matches.add(
              GoogleMapPlace(
                title: dist,
                subtitle: '${province.displayName}, Việt Nam',
                fullAddress: full,
                type: 'district',
              ),
            );
          }
        }
      }
    }

    setState(() {
      _suggestions = matches.take(15).toList();
    });

    // 2. Gọi Google Places API Autocomplete song song với debounce 300ms
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      _modalSessionToken ??= PlacesService.generateSessionToken();
      try {
        final predictions = await PlacesService.getAutocompletePredictions(
          query,
          sessionToken: _modalSessionToken,
        );

        if (!mounted || _searchController.text.trim().toLowerCase() != q) {
          return;
        }

        if (predictions.isNotEmpty) {
          final googlePlaces = predictions
              .map(
                (p) => GoogleMapPlace(
                  title: p.mainText,
                  subtitle: p.secondaryText.isNotEmpty
                      ? p.secondaryText
                      : p.description,
                  fullAddress: p.description,
                  type: p.types.contains('stadium') ? 'stadium' : 'district',
                  placeId: p.placeId,
                ),
              )
              .toList();

          setState(() {
            final existingFull = googlePlaces.map((g) => g.fullAddress).toSet();
            _suggestions = [
              ...googlePlaces,
              ...matches.where((m) => !existingFull.contains(m.fullAddress)),
            ].take(20).toList();
          });
        }
      } catch (_) {}
    });
  }

  void _selectPlace(GoogleMapPlace place) async {
    setState(() {
      _selectedPlace = place;
      _searchController.text = place.fullAddress;
      _isSearching = false;
      _mapOffset = Offset.zero;
    });
    _searchFocusNode.unfocus();

    if (place.placeId != null && place.placeId!.isNotEmpty) {
      try {
        final details = await PlacesService.getPlaceDetails(
          place.placeId!,
          sessionToken: _modalSessionToken,
        );
        if (details != null &&
            details.latitude != null &&
            details.longitude != null &&
            mounted) {
          setState(() {
            _selectedPlace = GoogleMapPlace(
              title: details.name,
              subtitle: place.subtitle,
              fullAddress: details.formattedAddress,
              type: place.type,
              latitude: details.latitude!,
              longitude: details.longitude!,
              placeId: details.placeId,
            );
          });
        }
      } catch (_) {}
    }

    _modalSessionToken = null;
  }

  void _useCurrentLocation() {
    const currentLoc = GoogleMapPlace(
      title: 'Vị trí hiện tại (GPS)',
      subtitle: 'TP. Thủ Đức, TP. Hồ Chí Minh (Độ chính xác cao)',
      fullAddress: 'TP. Thủ Đức, TP. Hồ Chí Minh',
      type: 'hub',
    );
    _selectPlace(currentLoc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.my_location, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Đã định vị vị trí hiện tại của bạn thành công!'),
          ],
        ),
        backgroundColor: AppTheme.primaryDarkGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.88,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Thanh kéo mở rộng modal
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Tiêu đề phong cách Google Maps
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chọn khu vực đội bóng',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Định vị sân nhà & tìm đối thủ phù hợp trên Google Maps',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Thanh tìm kiếm Google Maps nổi bật
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    offset: Offset(0, 3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm địa điểm, quận huyện, sân bóng...',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.blueAccent,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchQueryChanged('');
                          },
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.my_location,
                          size: 20,
                          color: Colors.blueAccent,
                        ),
                        tooltip: 'Vị trí hiện tại',
                        onPressed: _useCurrentLocation,
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Tab chuyển đổi (Bản đồ Google Maps / Danh mục chuẩn)
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryDarkGreen,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Color(0x0D000000), blurRadius: 4),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('Bản đồ tương tác'),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Tỉnh / Quận huyện'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick Filter Chips (Chỉ hiển thị khi không gõ tìm kiếm)
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(
                        Icons.gps_fixed,
                        size: 14,
                        color: Colors.blue,
                      ),
                      label: const Text(
                        'Gần tôi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.blue.shade50,
                      onPressed: _useCurrentLocation,
                    ),
                    const SizedBox(width: 8),
                    ..._popularFootballHubs.take(6).map((hub) {
                      final isSelected =
                          _selectedPlace.fullAddress == hub.fullAddress;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            hub.title,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryLightGreen,
                          onSelected: (_) => _selectPlace(hub),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // Nội dung chính
          Expanded(
            child: _isSearching
                ? _buildSearchResultsList()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInteractiveMapTab(),
                      _buildHierarchySelectorTab(),
                    ],
                  ),
          ),

          // Thẻ xác nhận lựa chọn ở chân màn hình
          _buildBottomConfirmation(),
        ],
      ),
    );
  }

  /// Tab 1: Bản đồ mô phỏng Google Maps tương tác
  Widget _buildInteractiveMapTab() {
    return Stack(
      children: [
        // Canvas mô phỏng bản đồ Google Maps
        GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _mapOffset += details.delta;
            });
          },
          child: ClipRect(
            child: CustomPaint(
              size: Size.infinite,
              painter: _GoogleMapCanvasPainter(
                offset: _mapOffset,
                zoomLevel: _zoomLevel,
                isSatellite: _isSatelliteMode,
                centerLabel: _selectedPlace.title,
              ),
            ),
          ),
        ),

        // Pin chỉ vị trí ở chính giữa bản đồ
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tooltip tên địa điểm nổi bật
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      size: 14,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedPlace.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Điểm đánh dấu ghim vị trí kiểu Google Maps
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade600,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66F44336),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              // Chấm tiếp đất của ghim bản đồ
              Icon(Icons.arrow_drop_down, color: Colors.red.shade700, size: 20),
            ],
          ),
        ),

        // Các nút điều khiển bản đồ nổi (+ / - / Lớp bản đồ / Định vị)
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút đổi chế độ bản đồ vệ tinh / đường phố
              FloatingActionButton.small(
                heroTag: 'map_layer',
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.textPrimary,
                onPressed: () =>
                    setState(() => _isSatelliteMode = !_isSatelliteMode),
                tooltip: _isSatelliteMode
                    ? 'Bản đồ đường phố'
                    : 'Bản đồ vệ tinh',
                child: Icon(
                  _isSatelliteMode ? Icons.map : Icons.satellite_alt_rounded,
                ),
              ),
              const SizedBox(height: 8),
              // Phóng to
              FloatingActionButton.small(
                heroTag: 'map_zoom_in',
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.textPrimary,
                onPressed: () {
                  setState(
                    () => _zoomLevel = (_zoomLevel * 1.2).clamp(0.6, 2.5),
                  );
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              // Thu nhỏ
              FloatingActionButton.small(
                heroTag: 'map_zoom_out',
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.textPrimary,
                onPressed: () {
                  setState(
                    () => _zoomLevel = (_zoomLevel / 1.2).clamp(0.6, 2.5),
                  );
                },
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              // Nút định vị
              FloatingActionButton.small(
                heroTag: 'map_gps',
                backgroundColor: AppTheme.primaryDarkGreen,
                foregroundColor: Colors.white,
                onPressed: _useCurrentLocation,
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),

        // Hint bar hướng dẫn người dùng
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 16,
                  color: AppTheme.primaryDarkGreen,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kéo bản đồ để chọn tâm khu vực sân nhà cho đội bóng',
                    style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Tab 2: Chọn phân cấp Tỉnh/Thành phố & Quận/Huyện chuẩn
  Widget _buildHierarchySelectorTab() {
    return Row(
      children: [
        // Cột Tỉnh / Thành phố
        Expanded(
          flex: 5,
          child: Container(
            color: const Color(0xFFF9FAFB),
            child: ListView.separated(
              itemCount: _allProvinces.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final prov = _allProvinces[idx];
                final isSelected = prov.displayName == _selectedProvince;
                return ListTile(
                  dense: true,
                  selected: isSelected,
                  selectedTileColor: AppTheme.primaryLightGreen.withValues(
                    alpha: 0.3,
                  ),
                  title: Text(
                    prov.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppTheme.primaryDarkGreen
                          : AppTheme.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppTheme.primaryDarkGreen,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedProvince = prov.displayName;
                      _districtsOfProvince = ProvinceService.getDistricts(
                        prov.displayName,
                      );
                    });
                  },
                );
              },
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // Cột Quận / Huyện thuộc Tỉnh đã chọn
        Expanded(
          flex: 6,
          child: ListView.separated(
            itemCount: _districtsOfProvince.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (ctx, idx) {
              final dist = _districtsOfProvince[idx];
              final fullAddress = '$dist, $_selectedProvince';
              final isSelected = _selectedPlace.fullAddress == fullAddress;

              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: AppTheme.primaryLightGreen.withValues(
                  alpha: 0.3,
                ),
                leading: const Icon(
                  Icons.location_city_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
                title: Text(
                  dist,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.primaryDarkGreen
                        : AppTheme.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppTheme.primaryDarkGreen,
                      )
                    : null,
                onTap: () {
                  _selectPlace(
                    GoogleMapPlace(
                      title: dist,
                      subtitle: '$_selectedProvince, Việt Nam',
                      fullAddress: fullAddress,
                      type: 'district',
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Danh sách kết quả tìm kiếm tức thời
  Widget _buildSearchResultsList() {
    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy địa điểm "${_searchController.text}"',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hãy thử tìm tên Quận, Huyện hoặc Sân bóng khác',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (ctx, idx) {
        final place = _suggestions[idx];
        IconData leadingIcon = Icons.location_on_outlined;
        Color iconColor = Colors.redAccent;

        if (place.type == 'stadium') {
          leadingIcon = Icons.sports_soccer_rounded;
          iconColor = AppTheme.primaryDarkGreen;
        } else if (place.type == 'district') {
          leadingIcon = Icons.location_city_rounded;
          iconColor = Colors.blueAccent;
        }

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(leadingIcon, color: iconColor, size: 20),
          ),
          title: Text(
            place.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            place.subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.north_west, size: 16, color: Colors.grey),
          onTap: () => _selectPlace(place),
        );
      },
    );
  }

  /// Thẻ xác nhận dưới cùng
  Widget _buildBottomConfirmation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, -3),
            blurRadius: 10,
          ),
        ],
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primaryDarkGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPlace.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        _selectedPlace.fullAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, _selectedPlace.fullAddress);
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Xác nhận khu vực này',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDarkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter vẽ giao diện mô phỏng bản đồ Google Maps phong cách Vector
class _GoogleMapCanvasPainter extends CustomPainter {
  final Offset offset;
  final double zoomLevel;
  final bool isSatellite;
  final String centerLabel;

  _GoogleMapCanvasPainter({
    required this.offset,
    required this.zoomLevel,
    required this.isSatellite,
    required this.centerLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Màu nền bản đồ (Vệ tinh: xanh đen đất, Đường phố: vàng ngà xám chuẩn Google Maps)
    final bgPaint = Paint()
      ..color = isSatellite ? const Color(0xFF1B2A1C) : const Color(0xFFF2EFE9);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    canvas.save();
    canvas.translate(width / 2, height / 2);
    canvas.scale(zoomLevel);
    canvas.translate(offset.dx, offset.dy);

    // 1. Vẽ các mảng công viên / Sân cỏ (Green zones)
    final greenPaint = Paint()
      ..color = isSatellite ? const Color(0xFF263F28) : const Color(0xFFD4E7D0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-280, -180, 160, 120),
        const Radius.circular(12),
      ),
      greenPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(80, 40, 200, 140),
        const Radius.circular(16),
      ),
      greenPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-120, 160, 150, 100),
        const Radius.circular(10),
      ),
      greenPaint,
    );

    // 2. Vẽ dải sông / Kênh nước (Waterways)
    final waterPaint = Paint()
      ..color = isSatellite ? const Color(0xFF16253B) : const Color(0xFFAAD3DF)
      ..strokeWidth = 32
      ..style = PaintingStyle.stroke;

    final riverPath = Path()
      ..moveTo(-width, -220)
      ..cubicTo(-100, -140, 60, -260, width, -180);
    canvas.drawPath(riverPath, waterPaint);

    // 3. Vẽ mạng lưới đường phụ (Local streets)
    final streetPaint = Paint()
      ..color = isSatellite ? const Color(0xFF384639) : Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    for (int i = -4; i <= 4; i++) {
      final y = i * 70.0;
      canvas.drawLine(
        Offset(-width * 1.5, y),
        Offset(width * 1.5, y),
        streetPaint,
      );
      final x = i * 85.0;
      canvas.drawLine(
        Offset(x, -height * 1.5),
        Offset(x, height * 1.5),
        streetPaint,
      );
    }

    // 4. Vẽ trục đại lộ chính (Primary Arteries / Highways)
    final highwayCasing = Paint()
      ..color = isSatellite ? const Color(0xFF4C5D4E) : const Color(0xFFE2D6BE)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    final highwayCore = Paint()
      ..color = isSatellite ? const Color(0xFF5A6F5C) : const Color(0xFFFDE293)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    // Đường chéo lớn
    final mainRoad = Path()
      ..moveTo(-width * 1.5, -height * 0.8)
      ..lineTo(width * 1.5, height * 0.8);
    canvas.drawPath(mainRoad, highwayCasing);
    canvas.drawPath(mainRoad, highwayCore);

    // Đường vòng cung
    final ringRoad = Path()
      ..moveTo(-width * 1.2, 100)
      ..quadraticBezierTo(0, -60, width * 1.2, 120);
    canvas.drawPath(ringRoad, highwayCasing);
    canvas.drawPath(ringRoad, highwayCore);

    // 5. Vẽ các icon sân bóng xung quanh
    final iconBgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final pt in [
      const Offset(-180, -90),
      const Offset(140, 80),
      const Offset(-40, 180),
    ]) {
      canvas.drawCircle(pt, 12, iconBgPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoogleMapCanvasPainter oldDelegate) {
    return oldDelegate.offset != offset ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.isSatellite != isSatellite ||
        oldDelegate.centerLabel != centerLabel;
  }
}

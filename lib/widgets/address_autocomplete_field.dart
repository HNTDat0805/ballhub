import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/place_location.dart';
import '../services/places_service.dart';

/// Thành phần Address Autocomplete tái sử dụng trong Ballhub:
/// 1. Gợi ý địa điểm thời gian thực theo chuẩn Google Maps Places API
/// 2. Debounce 350ms chống spam request
/// 3. Quản lý Session Token tối ưu chi phí billing
/// 4. Hỗ trợ tìm kiếm tiếng Việt có dấu / không dấu
/// 5. Tự động lấy Place Details (kinh độ, vĩ độ, quận huyện, tỉnh thành) khi người dùng bấm chọn
/// 6. Hiển thị Dropdown overlay thông minh, chống tràn và không bị bàn phím che khuất
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final bool isRequired;
  final String? Function(String?)? validator;
  final ValueChanged<PlaceLocation>? onPlaceSelected;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCleared;
  final String? helperText;
  final bool enabled;

  const AddressAutocompleteField({
    super.key,
    this.controller,
    this.initialValue,
    this.labelText = 'Địa chỉ / Khu vực',
    this.hintText = 'Nhập tên sân, địa chỉ, quận huyện...',
    this.prefixIcon = Icons.location_on_outlined,
    this.isRequired = false,
    this.validator,
    this.onPlaceSelected,
    this.onChanged,
    this.onCleared,
    this.helperText,
    this.enabled = true,
  });

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;

  String? _sessionToken;
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        TextEditingController(text: widget.initialValue ?? '');
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Xử lý sự kiện thay đổi trạng thái con trỏ (focus): hiện gợi ý nếu đang có dữ liệu và ẩn khi mất focus
  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_predictions.isNotEmpty) {
        _showOverlay(); // Hiển thị popup gợi ý nếu đã có kết quả tìm kiếm
      }
    } else {
      // Đợi ngắn 200ms để cho phép cử chỉ onTap trên danh sách gợi ý kịp ghi nhận trước khi đóng popup
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay(); // Đóng popup gợi ý
        }
      });
    }
  }

  /// Xử lý khi người dùng thay đổi văn bản trong ô tìm kiếm: debounce 350ms và gọi Google Places API
  void _onTextChanged(String text) {
    widget.onChanged?.call(text);

    _debounceTimer
        ?.cancel(); // Hủy bỏ timer debounce trước đó nếu người dùng vẫn đang gõ

    final query = text.trim();
    if (query.isEmpty) {
      _sessionToken = null;
      setState(() {
        _predictions = [];
        _isLoading = false;
        _hasSearched = false;
        _errorMessage = null;
      });
      _removeOverlay(); // Đóng popup nếu ô nhập trống
      return;
    }

    // Khởi tạo phiên Autocomplete Session mới khi người dùng bắt đầu gõ để gom bill SKU Google Maps
    _sessionToken ??= PlacesService.generateSessionToken();

    // Không gửi request nếu chuỗi tìm kiếm chưa đủ 2 ký tự (tiết kiệm API call)
    if (query.length < 2) {
      setState(() {
        _predictions = [];
        _isLoading = false;
        _hasSearched = false;
      });
      _removeOverlay();
      return;
    }

    setState(() => _isLoading = true);

    // Chờ 350ms sau phím gõ cuối cùng mới thực sự gửi request mạng
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await PlacesService.getAutocompletePredictions(
          query,
          sessionToken: _sessionToken,
        );

        if (!mounted) return;

        setState(() {
          _predictions = results;
          _isLoading = false;
          _hasSearched = true;
          _errorMessage = null;
        });

        if (_focusNode.hasFocus) {
          _showOverlay(); // Hiển thị kết quả gợi ý
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasSearched = true;
          _errorMessage =
              'Không thể tải gợi ý địa điểm. Bạn có thể tự nhập tay.';
        });
        if (_focusNode.hasFocus) {
          _showOverlay();
        }
      }
    });
  }

  /// Xử lý khi người dùng bấm chọn một địa điểm trong danh sách gợi ý
  Future<void> _selectPrediction(PlacePrediction prediction) async {
    // 1. Đóng dropdown và ẩn bàn phím
    _removeOverlay();
    _focusNode.unfocus();

    setState(() {
      _isLoading = true;
      _controller.text = prediction.description;
    });

    // 2. Gọi Place Details API để lấy đầy đủ tọa độ kinh vĩ độ và đơn vị hành chính
    try {
      final details = await PlacesService.getPlaceDetails(
        prediction.placeId,
        sessionToken: _sessionToken,
      );

      final selectedLocation =
          details ??
          PlaceLocation(
            placeId: prediction.placeId,
            name: prediction.mainText,
            formattedAddress: prediction.description,
          );

      if (mounted) {
        setState(() {
          _controller.text = selectedLocation.formattedAddress.isNotEmpty
              ? selectedLocation.formattedAddress
              : selectedLocation.name;
          _isLoading = false;
          _predictions = [];
        });
      }

      // 3. Bắn callback trả về thông tin địa điểm hoàn chỉnh
      widget.onPlaceSelected?.call(selectedLocation);
    } catch (_) {
      // Fallback nếu gọi Place Details thất bại
      final fallbackLocation = PlaceLocation(
        placeId: prediction.placeId,
        name: prediction.mainText,
        formattedAddress: prediction.description,
      );

      if (mounted) {
        setState(() {
          _controller.text = fallbackLocation.formattedAddress;
          _isLoading = false;
          _predictions = [];
        });
      }

      widget.onPlaceSelected?.call(fallbackLocation);
    } finally {
      // 4. Kết thúc chu kỳ session token của Google Places API
      _sessionToken = null;
    }
  }

  /// Xóa sạch dữ liệu ô tìm kiếm và đặt lại trạng thái ban đầu
  void _clearInput() {
    _controller.clear();
    _sessionToken = null;
    _debounceTimer?.cancel();
    setState(() {
      _predictions = [];
      _isLoading = false;
      _hasSearched = false;
      _errorMessage = null;
    });
    _removeOverlay();
    widget.onCleared?.call();
    widget.onChanged?.call('');
  }

  /// Hiển thị dropdown gợi ý trên màn hình
  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context, rootOverlay: false);
    _overlayEntry = _createOverlayEntry();
    overlay.insert(_overlayEntry!);
  }

  /// Đóng dropdown gợi ý và giải phóng bộ nhớ
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Tạo widget OverlayEntry bám theo vị trí của trường nhập liệu
  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (ctx) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(
              0.0,
              size.height + 6,
            ), // Đặt dropdown ngay dưới ô input 6px
            child: Material(
              elevation: 8,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 240),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildSuggestionsContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryDarkGreen,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Đang tìm kiếm trên Google Places...',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasSearched && _predictions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(
              Icons.search_off_rounded,
              color: Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Không tìm thấy địa điểm phù hợp',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Bạn vẫn có thể tiếp tục dùng địa chỉ đã nhập tay ở trên.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _predictions.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (ctx, index) {
        final pred = _predictions[index];
        final isStadium =
            pred.types.contains('stadium') ||
            pred.types.contains('point_of_interest');
        final isDistrict = pred.types.contains('administrative_area_level_2');

        IconData leadingIcon = Icons.location_on_outlined;
        Color iconColor = Colors.redAccent;

        if (isStadium) {
          leadingIcon = Icons.sports_soccer_rounded;
          iconColor = AppTheme.primaryDarkGreen;
        } else if (isDistrict) {
          leadingIcon = Icons.location_city_rounded;
          iconColor = Colors.blueAccent;
        }

        return InkWell(
          onTap: () => _selectPrediction(pred),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(leadingIcon, color: iconColor, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pred.mainText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (pred.secondaryText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          pred.secondaryText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        onChanged: _onTextChanged,
        validator:
            widget.validator ??
            (val) {
              if (widget.isRequired && (val == null || val.trim().isEmpty)) {
                return 'Vui lòng nhập hoặc chọn địa điểm';
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          helperText: widget.helperText,
          prefixIcon: Icon(widget.prefixIcon),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryDarkGreen,
                    ),
                  ),
                )
              else if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  tooltip: 'Xóa địa điểm',
                  onPressed: _clearInput,
                ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: 'Gợi ý tự động từ Google Maps Places',
                  child: Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

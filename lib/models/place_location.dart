/// Mô hình chuẩn hóa dữ liệu địa điểm dùng chung cho Ballhub:
/// Giải đấu, Sân bóng, và Đội bóng.
class PlaceLocation {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final String? province;
  final String? district;
  final String? ward;

  const PlaceLocation({
    this.placeId = '',
    required this.name,
    required this.formattedAddress,
    this.latitude,
    this.longitude,
    this.province,
    this.district,
    this.ward,
  });

  /// Tạo PlaceLocation từ một chuỗi địa chỉ đơn thuần (dành cho dữ liệu cũ / fallback)
  factory PlaceLocation.fromSimpleAddress(String address) {
    final trimmed = address.trim();
    return PlaceLocation(
      placeId: '',
      name: trimmed.isNotEmpty ? trimmed.split(',').first.trim() : '',
      formattedAddress: trimmed,
    );
  }

  /// Trích xuất PlaceLocation từ phản hồi chi tiết Google Place Details
  factory PlaceLocation.fromGooglePlaceDetails(Map<String, dynamic> result) {
    final placeId = result['place_id'] as String? ?? '';
    final name = result['name'] as String? ?? '';
    final formattedAddress = result['formatted_address'] as String? ?? name;

    double? lat;
    double? lng;
    final geometry = result['geometry'];
    if (geometry is Map) {
      final location = geometry['location'];
      if (location is Map) {
        lat = (location['lat'] as num?)?.toDouble();
        lng = (location['lng'] as num?)?.toDouble();
      }
    }

    String? province;
    String? district;
    String? ward;

    final components = result['address_components'];
    if (components is List) {
      // Pass 1: Xác định Tỉnh/Thành và Quận/Huyện tiêu chuẩn
      for (final comp in components) {
        if (comp is! Map) continue;
        final types =
            (comp['types'] as List?)?.whereType<String>().toList() ?? [];
        final longName = comp['long_name'] as String? ?? '';

        if (types.contains('administrative_area_level_1')) {
          province = longName;
        } else if (types.contains('administrative_area_level_2')) {
          district = longName;
        } else if (types.contains('administrative_area_level_3') ||
            types.contains('sublocality_level_2')) {
          ward = longName;
        }
      }

      // Pass 2: Phân giải sublocality_level_1 (phường/xã nếu đã có quận, hoặc quận nếu chưa có)
      for (final comp in components) {
        if (comp is! Map) continue;
        final types =
            (comp['types'] as List?)?.whereType<String>().toList() ?? [];
        final longName = comp['long_name'] as String? ?? '';

        if (types.contains('sublocality_level_1')) {
          if (district != null && ward == null) {
            ward = longName;
          } else {
            district ??= longName;
          }
        }
      }
    }

    return PlaceLocation(
      placeId: placeId,
      name: name,
      formattedAddress: formattedAddress,
      latitude: lat,
      longitude: lng,
      province: province,
      district: district,
      ward: ward,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (placeId.isNotEmpty) 'placeId': placeId,
      'name': name,
      'formattedAddress': formattedAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (province != null && province!.isNotEmpty) 'province': province,
      if (district != null && district!.isNotEmpty) 'district': district,
      if (ward != null && ward!.isNotEmpty) 'ward': ward,
    };
  }

  factory PlaceLocation.fromMap(Map<String, dynamic> map) {
    return PlaceLocation(
      placeId: map['placeId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      formattedAddress:
          map['formattedAddress'] as String? ?? (map['name'] as String? ?? ''),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      province: map['province'] as String?,
      district: map['district'] as String?,
      ward: map['ward'] as String?,
    );
  }

  PlaceLocation copyWith({
    String? placeId,
    String? name,
    String? formattedAddress,
    double? latitude,
    double? longitude,
    String? province,
    String? district,
    String? ward,
  }) {
    return PlaceLocation(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      province: province ?? this.province,
      district: district ?? this.district,
      ward: ward ?? this.ward,
    );
  }

  @override
  String toString() =>
      'PlaceLocation(placeId: $placeId, name: $name, address: $formattedAddress)';
}

/// Gợi ý địa điểm từ Google Places Autocomplete API
class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;
  final List<String> types;

  const PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
    this.types = const [],
  });

  factory PlacePrediction.fromGoogleJson(Map<String, dynamic> json) {
    final placeId = json['place_id'] as String? ?? '';
    final description = json['description'] as String? ?? '';
    final formatting = json['structured_formatting'];

    String mainText = description;
    String secondaryText = '';

    if (formatting is Map) {
      mainText = formatting['main_text'] as String? ?? description;
      secondaryText = formatting['secondary_text'] as String? ?? '';
    }

    final types = (json['types'] as List?)?.whereType<String>().toList() ?? [];

    return PlacePrediction(
      placeId: placeId,
      mainText: mainText,
      secondaryText: secondaryText,
      description: description,
      types: types,
    );
  }
}

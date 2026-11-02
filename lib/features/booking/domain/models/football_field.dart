import 'dart:collection';

/// Trạng thái vận hành của một sân bóng có thể được đặt.
enum FieldStatus { draft, active, inactive, maintenance, archived }

/// Một sân bóng thuộc sở hữu của một chủ sân.
class FootballField {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String coverImageUrl;
  final List<String> imageUrls;
  final String address;
  final String district;
  final String city;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? ward;
  final String fieldType;
  final int capacity;
  final List<String> amenities;
  final int basePrice;
  final String currency;
  final int slotDurationMinutes;
  final FieldStatus status;
  final Map<String, List<String>> openingHours;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  FootballField({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required List<String> imageUrls,
    required this.address,
    required this.district,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.ward,
    required this.fieldType,
    required this.capacity,
    required List<String> amenities,
    required this.basePrice,
    required this.currency,
    required this.slotDurationMinutes,
    required this.status,
    required Map<String, List<String>> openingHours,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  }) : imageUrls = List.unmodifiable(imageUrls),
       amenities = List.unmodifiable(amenities),
       openingHours = UnmodifiableMapView({
         for (final entry in openingHours.entries)
           entry.key: List.unmodifiable(entry.value),
       });

  /// Khởi tạo đối tượng FootballField từ Map JSON của REST API Backend
  factory FootballField.fromJson(Map<String, dynamic> json) {
    return FootballField(
      id: json['id'] as String? ?? '', // Mã định danh duy nhất của sân
      ownerId: json['ownerId'] as String? ?? '', // ID chủ sở hữu sân bóng
      name: json['name'] as String? ?? '', // Tên sân bóng
      description: json['description'] as String? ?? '', // Mô tả chi tiết sân
      coverImageUrl:
          json['coverImageUrl'] as String? ?? '', // Link ảnh bìa đại diện
      imageUrls: _stringList(
        json['imageUrls'],
      ), // Danh sách link ảnh chi tiết sân
      address: json['address'] as String? ?? '', // Địa chỉ hiển thị
      district: json['district'] as String? ?? '', // Quận/huyện
      city: json['city'] as String? ?? '', // Tỉnh/thành phố
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0, // Vĩ độ bản đồ
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0, // Kinh độ bản đồ
      placeId:
          json['placeId'] as String?, // Mã định danh địa điểm Google Place ID
      ward: json['ward'] as String?, // Phường/xã
      fieldType:
          json['fieldType'] as String? ?? '', // Loại sân: Sân 5, Sân 7, Sân 11
      capacity: (json['capacity'] as num?)?.toInt() ?? 0, // Sức chứa số người
      amenities: _stringList(
        json['amenities'],
      ), // Danh sách tiện ích: Đèn chiếu sáng, nước uống, v.v.
      basePrice:
          (json['basePrice'] as num?)?.toInt() ??
          0, // Giá thuê cơ bản mỗi khung giờ
      currency: json['currency'] as String? ?? 'VND', // Đơn vị tiền tệ
      slotDurationMinutes:
          (json['slotDurationMinutes'] as num?)?.toInt() ??
          60, // Thời lượng mỗi slot (phút)
      status: FieldStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () =>
            FieldStatus.draft, // Mặc định là draft nếu không nhận diện được
      ),
      openingHours: _openingHours(
        json['openingHours'],
      ), // Giờ mở cửa theo từng ngày trong tuần
      timezone: json['timezone'] as String? ?? 'Asia/Ho_Chi_Minh', // Múi giờ
      createdAt: _dateTime(json['createdAt']), // Thời điểm tạo
      updatedAt: _dateTime(json['updatedAt']), // Thời điểm cập nhật gần nhất
      createdBy: json['createdBy'] as String? ?? '', // Người tạo
      updatedBy: json['updatedBy'] as String? ?? '', // Người sửa đổi
    );
  }

  /// Tạo bản sao đối tượng FootballField với các thuộc tính thay đổi
  FootballField copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? coverImageUrl,
    List<String>? imageUrls,
    String? address,
    String? district,
    String? city,
    double? latitude,
    double? longitude,
    String? placeId,
    String? ward,
    String? fieldType,
    int? capacity,
    List<String>? amenities,
    int? basePrice,
    String? currency,
    int? slotDurationMinutes,
    FieldStatus? status,
    Map<String, List<String>>? openingHours,
    String? timezone,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return FootballField(
      id: id ?? this.id, // Giữ id cũ hoặc cập nhật id mới
      ownerId: ownerId ?? this.ownerId, // Giữ ownerId cũ hoặc cập nhật
      name: name ?? this.name, // Giữ tên cũ hoặc cập nhật
      description:
          description ?? this.description, // Giữ mô tả cũ hoặc cập nhật
      coverImageUrl:
          coverImageUrl ?? this.coverImageUrl, // Giữ ảnh bìa cũ hoặc cập nhật
      imageUrls:
          imageUrls ?? this.imageUrls, // Giữ danh sách ảnh cũ hoặc cập nhật
      address: address ?? this.address, // Giữ địa chỉ cũ hoặc cập nhật
      district: district ?? this.district, // Giữ quận/huyện cũ hoặc cập nhật
      city: city ?? this.city, // Giữ tỉnh/thành phố cũ hoặc cập nhật
      latitude: latitude ?? this.latitude, // Giữ vĩ độ cũ hoặc cập nhật
      longitude: longitude ?? this.longitude, // Giữ kinh độ cũ hoặc cập nhật
      placeId: placeId ?? this.placeId, // Giữ Google Place ID cũ hoặc cập nhật
      ward: ward ?? this.ward, // Giữ phường/xã cũ hoặc cập nhật
      fieldType: fieldType ?? this.fieldType, // Giữ loại sân cũ hoặc cập nhật
      capacity: capacity ?? this.capacity, // Giữ sức chứa cũ hoặc cập nhật
      amenities: amenities ?? this.amenities, // Giữ tiện ích cũ hoặc cập nhật
      basePrice: basePrice ?? this.basePrice, // Giữ giá thuê cũ hoặc cập nhật
      currency:
          currency ?? this.currency, // Giữ đơn vị tiền tệ cũ hoặc cập nhật
      slotDurationMinutes:
          slotDurationMinutes ??
          this.slotDurationMinutes, // Giữ thời lượng slot cũ hoặc cập nhật
      status: status ?? this.status, // Giữ trạng thái cũ hoặc cập nhật
      openingHours:
          openingHours ?? this.openingHours, // Giữ lịch mở cửa cũ hoặc cập nhật
      timezone: timezone ?? this.timezone, // Giữ múi giờ cũ hoặc cập nhật
      createdAt: createdAt ?? this.createdAt, // Giữ ngày tạo cũ hoặc cập nhật
      updatedAt:
          updatedAt ?? this.updatedAt, // Giữ ngày cập nhật cũ hoặc cập nhật
      createdBy: createdBy ?? this.createdBy, // Giữ người tạo cũ hoặc cập nhật
      updatedBy:
          updatedBy ?? this.updatedBy, // Giữ người cập nhật cũ hoặc cập nhật
    );
  }

  /// Chuyển đối tượng FootballField thành Map JSON để gửi lên Backend REST API
  Map<String, dynamic> toJson() {
    return {
      'id': id, // ID sân
      'ownerId': ownerId, // ID chủ sân
      'name': name, // Tên sân bóng
      'description': description, // Mô tả
      'coverImageUrl': coverImageUrl, // Link ảnh bìa
      'imageUrls': imageUrls, // Danh sách link ảnh
      'address': address, // Địa chỉ
      'district': district, // Quận/huyện
      'city': city, // Tỉnh/thành phố
      'latitude': latitude, // Vĩ độ
      'longitude': longitude, // Kinh độ
      if (placeId != null && placeId!.isNotEmpty)
        'placeId': placeId, // Google Place ID nếu có
      if (ward != null && ward!.isNotEmpty) 'ward': ward, // Phường/xã nếu có
      'fieldType': fieldType, // Loại sân
      'capacity': capacity, // Sức chứa
      'amenities': amenities, // Danh sách tiện ích
      'basePrice': basePrice, // Giá cơ bản
      'currency': currency, // Đơn vị tiền tệ
      'slotDurationMinutes': slotDurationMinutes, // Thời lượng khung giờ
      'status': status
          .name, // Trạng thái: draft, active, inactive, maintenance, archived
      'openingHours': openingHours, // Giờ mở cửa
      'timezone': timezone, // Múi giờ
      'createdAt': createdAt
          .toUtc()
          .toIso8601String(), // Thời điểm tạo chuẩn UTC ISO 8601
      'updatedAt': updatedAt
          .toUtc()
          .toIso8601String(), // Thời điểm sửa đổi chuẩn UTC ISO 8601
      'createdBy': createdBy, // ID người tạo
      'updatedBy': updatedBy, // ID người cập nhật
    };
  }

  /// Hàm tiện ích trích xuất danh sách chuỗi an toàn từ JSON
  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  /// Hàm tiện ích trích xuất bản đồ giờ mở cửa an toàn từ JSON
  static Map<String, List<String>> _openingHours(Object? value) {
    if (value is! Map) return const {};
    return value.map(
      (key, periods) => MapEntry(key.toString(), _stringList(periods)),
    );
  }

  /// Hàm tiện ích parse chuỗi ISO thành DateTime an toàn
  static DateTime _dateTime(Object? value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

import 'dart:collection';

/// Trạng thái vận hành của một sân bóng có thể được đặt.
enum FieldStatus {
  draft,
  active,
  inactive,
  maintenance,
  archived,
}

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
  })  : imageUrls = List.unmodifiable(imageUrls),
        amenities = List.unmodifiable(amenities),
        openingHours = UnmodifiableMapView({
          for (final entry in openingHours.entries)
            entry.key: List.unmodifiable(entry.value),
        });

  factory FootballField.fromJson(Map<String, dynamic> json) {
    return FootballField(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      imageUrls: _stringList(json['imageUrls']),
      address: json['address'] as String? ?? '',
      district: json['district'] as String? ?? '',
      city: json['city'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      fieldType: json['fieldType'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      amenities: _stringList(json['amenities']),
      basePrice: (json['basePrice'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'VND',
      slotDurationMinutes: (json['slotDurationMinutes'] as num?)?.toInt() ?? 60,
      status: FieldStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => FieldStatus.draft,
      ),
      openingHours: _openingHours(json['openingHours']),
      timezone: json['timezone'] as String? ?? 'Asia/Ho_Chi_Minh',
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTime(json['updatedAt']),
      createdBy: json['createdBy'] as String? ?? '',
      updatedBy: json['updatedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'imageUrls': imageUrls,
      'address': address,
      'district': district,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'fieldType': fieldType,
      'capacity': capacity,
      'amenities': amenities,
      'basePrice': basePrice,
      'currency': currency,
      'slotDurationMinutes': slotDurationMinutes,
      'status': status.name,
      'openingHours': openingHours,
      'timezone': timezone,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  static Map<String, List<String>> _openingHours(Object? value) {
    if (value is! Map) return const {};
    return value.map(
      (key, periods) => MapEntry(key.toString(), _stringList(periods)),
    );
  }

  static DateTime _dateTime(Object? value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

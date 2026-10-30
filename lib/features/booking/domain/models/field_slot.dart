/// Trạng thái lưu trữ của một khung giờ thuộc sân bóng.
enum FieldSlotStatus {
  available,
  held,
  booked,
  blocked,
}

/// Một khung giờ có thể đặt của một [FootballField].
class FieldSlot {
  final String id;
  final String fieldId;
  final String dateKey;
  final DateTime startsAt;
  final DateTime endsAt;
  final int durationMinutes;
  final int basePrice;
  final String currency;
  final FieldSlotStatus status;
  final String? bookingId;
  final DateTime? holdExpiresAt;
  final String? blockReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FieldSlot({
    required this.id,
    required this.fieldId,
    required this.dateKey,
    required this.startsAt,
    required this.endsAt,
    required this.durationMinutes,
    required this.basePrice,
    required this.currency,
    required this.status,
    this.bookingId,
    this.holdExpiresAt,
    this.blockReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FieldSlot.fromJson(Map<String, dynamic> json) {
    return FieldSlot(
      id: json['id'] as String? ?? '',
      fieldId: json['fieldId'] as String? ?? '',
      dateKey: json['dateKey'] as String? ?? '',
      startsAt: _dateTime(json['startsAt']),
      endsAt: _dateTime(json['endsAt']),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      basePrice: (json['basePrice'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'VND',
      status: FieldSlotStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => FieldSlotStatus.available,
      ),
      bookingId: json['bookingId'] as String?,
      holdExpiresAt: _nullableDateTime(json['holdExpiresAt']),
      blockReason: json['blockReason'] as String?,
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fieldId': fieldId,
      'dateKey': dateKey,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
      'durationMinutes': durationMinutes,
      'basePrice': basePrice,
      'currency': currency,
      'status': status.name,
      'bookingId': bookingId,
      'holdExpiresAt': holdExpiresAt?.toUtc().toIso8601String(),
      'blockReason': blockReason,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  static DateTime _dateTime(Object? value) {
    return _nullableDateTime(value) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static DateTime? _nullableDateTime(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}

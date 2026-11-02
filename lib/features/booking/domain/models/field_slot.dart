/// Trạng thái lưu trữ của một khung giờ thuộc sân bóng.
enum FieldSlotStatus { available, held, booked, blocked }

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

  /// Khởi tạo đối tượng FieldSlot từ Map JSON trả về từ REST API Backend
  factory FieldSlot.fromJson(Map<String, dynamic> json) {
    return FieldSlot(
      id: json['id'] as String? ?? '', // Mã định danh duy nhất của slot
      fieldId: json['fieldId'] as String? ?? '', // ID sân bóng sở hữu slot
      dateKey:
          json['dateKey'] as String? ?? '', // Ngày theo định dạng YYYY-MM-DD
      startsAt: _dateTime(json['startsAt']), // Thời điểm bắt đầu khung giờ
      endsAt: _dateTime(json['endsAt']), // Thời điểm kết thúc khung giờ
      durationMinutes:
          (json['durationMinutes'] as num?)?.toInt() ?? 0, // Thời lượng phút
      basePrice:
          (json['basePrice'] as num?)?.toInt() ??
          0, // Giá thuê cho khung giờ này
      currency: json['currency'] as String? ?? 'VND', // Tiền tệ
      status: FieldSlotStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => FieldSlotStatus
            .available, // Mặc định là available nếu không tìm thấy
      ),
      bookingId:
          json['bookingId'] as String?, // ID booking liên kết nếu đã được đặt
      holdExpiresAt: _nullableDateTime(
        json['holdExpiresAt'],
      ), // Thời điểm hết hạn giữ chỗ tạm thời
      blockReason:
          json['blockReason'] as String?, // Lý do khóa slot nếu bị chủ sân khóa
      createdAt: _dateTime(json['createdAt']), // Thời điểm tạo
      updatedAt: _dateTime(json['updatedAt']), // Thời điểm cập nhật
    );
  }

  /// Tạo bản sao đối tượng FieldSlot với các thuộc tính thay đổi
  FieldSlot copyWith({
    String? id,
    String? fieldId,
    String? dateKey,
    DateTime? startsAt,
    DateTime? endsAt,
    int? durationMinutes,
    int? basePrice,
    String? currency,
    FieldSlotStatus? status,
    String? bookingId,
    DateTime? holdExpiresAt,
    String? blockReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FieldSlot(
      id: id ?? this.id, // Giữ nguyên hoặc cập nhật id
      fieldId: fieldId ?? this.fieldId, // Giữ nguyên hoặc cập nhật fieldId
      dateKey: dateKey ?? this.dateKey, // Giữ nguyên hoặc cập nhật dateKey
      startsAt: startsAt ?? this.startsAt, // Giữ nguyên hoặc cập nhật startsAt
      endsAt: endsAt ?? this.endsAt, // Giữ nguyên hoặc cập nhật endsAt
      durationMinutes:
          durationMinutes ??
          this.durationMinutes, // Giữ nguyên hoặc cập nhật durationMinutes
      basePrice:
          basePrice ?? this.basePrice, // Giữ nguyên hoặc cập nhật basePrice
      currency: currency ?? this.currency, // Giữ nguyên hoặc cập nhật currency
      status: status ?? this.status, // Giữ nguyên hoặc cập nhật status
      bookingId:
          bookingId ?? this.bookingId, // Giữ nguyên hoặc cập nhật bookingId
      holdExpiresAt:
          holdExpiresAt ??
          this.holdExpiresAt, // Giữ nguyên hoặc cập nhật holdExpiresAt
      blockReason:
          blockReason ??
          this.blockReason, // Giữ nguyên hoặc cập nhật blockReason
      createdAt:
          createdAt ?? this.createdAt, // Giữ nguyên hoặc cập nhật createdAt
      updatedAt:
          updatedAt ?? this.updatedAt, // Giữ nguyên hoặc cập nhật updatedAt
    );
  }

  /// Chuyển đổi đối tượng FieldSlot thành Map JSON để gửi lên Backend REST API
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Mã định danh slot
      'fieldId': fieldId, // ID sân bóng
      'dateKey': dateKey, // Ngày đá
      'startsAt': startsAt
          .toUtc()
          .toIso8601String(), // Thời gian bắt đầu chuẩn UTC ISO 8601
      'endsAt': endsAt
          .toUtc()
          .toIso8601String(), // Thời gian kết thúc chuẩn UTC ISO 8601
      'durationMinutes': durationMinutes, // Thời lượng tính bằng phút
      'basePrice': basePrice, // Giá thuê cơ bản
      'currency': currency, // Đơn vị tiền tệ
      'status': status.name, // Trạng thái: available, held, booked, blocked
      'bookingId': bookingId, // ID đơn đặt sân
      'holdExpiresAt': holdExpiresAt?.toUtc().toIso8601String(), // Hạn giữ chỗ
      'blockReason': blockReason, // Lý do khóa slot
      'createdAt': createdAt.toUtc().toIso8601String(), // Thời gian tạo
      'updatedAt': updatedAt.toUtc().toIso8601String(), // Thời gian cập nhật
    };
  }

  /// Parse DateTime an toàn, nếu null trả về epoch 0 UTC
  static DateTime _dateTime(Object? value) {
    return _nullableDateTime(value) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  /// Parse nullable DateTime từ chuỗi ISO
  static DateTime? _nullableDateTime(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}

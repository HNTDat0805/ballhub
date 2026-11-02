/// Trạng thái vòng đời của một yêu cầu đặt sân.
enum BookingStatus {
  pending,
  confirmed,
  rejected,
  cancelledByUser,
  cancelledByOwner,
  completed,
}

/// Bản ghi lịch sử/yêu cầu đặt một hoặc nhiều khung giờ của sân bóng.
class Booking {
  final String id;
  final String fieldId;
  final String ownerId;
  final String bookerId;
  final String dateKey;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<String> slotIds;
  final String fieldNameSnapshot;
  final String fieldAddressSnapshot;
  final int priceSnapshot;
  final String currency;
  final String bookerNameSnapshot;
  final String bookerPhoneSnapshot;
  final BookingStatus status;
  final String? statusReason;
  final int subtotalAmount;
  final int discountAmount;
  final int totalAmount;
  final String? customerNote;
  final String? ownerNote;
  final String? cancellationReason;
  final DateTime? confirmedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final String? reviewedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.fieldId,
    required this.ownerId,
    required this.bookerId,
    required this.dateKey,
    required this.startsAt,
    required this.endsAt,
    required List<String> slotIds,
    required this.fieldNameSnapshot,
    required this.fieldAddressSnapshot,
    required this.priceSnapshot,
    required this.currency,
    required this.bookerNameSnapshot,
    required this.bookerPhoneSnapshot,
    required this.status,
    this.statusReason,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.totalAmount,
    this.customerNote,
    this.ownerNote,
    this.cancellationReason,
    this.confirmedAt,
    this.rejectedAt,
    this.cancelledAt,
    this.completedAt,
    this.reviewedBy,
    required this.createdAt,
    required this.updatedAt,
  }) : slotIds = List.unmodifiable(slotIds);

  /// Khởi tạo đối tượng Booking từ Map JSON do REST API Backend trả về
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String? ?? '', // Mã định danh booking duy nhất
      fieldId: json['fieldId'] as String? ?? '', // ID sân bóng được đặt
      ownerId: json['ownerId'] as String? ?? '', // ID chủ sân bóng
      bookerId: json['bookerId'] as String? ?? '', // ID người đặt sân
      dateKey: json['dateKey'] as String? ?? '', // Ngày đá YYYY-MM-DD
      startsAt: _dateTime(json['startsAt']), // Thời gian bắt đầu
      endsAt: _dateTime(json['endsAt']), // Thời gian kết thúc
      slotIds: _stringList(
        json['slotIds'],
      ), // Danh sách ID các khung giờ đã chọn
      fieldNameSnapshot:
          json['fieldNameSnapshot'] as String? ??
          '', // Ảnh chụp tên sân tại thời điểm đặt
      fieldAddressSnapshot:
          json['fieldAddressSnapshot'] as String? ??
          '', // Ảnh chụp địa chỉ sân tại thời điểm đặt
      priceSnapshot:
          (json['priceSnapshot'] as num?)?.toInt() ??
          0, // Đơn giá mỗi slot tại thời điểm đặt
      currency: json['currency'] as String? ?? 'VND', // Đơn vị tiền tệ
      bookerNameSnapshot:
          json['bookerNameSnapshot'] as String? ?? '', // Tên người đặt sân
      bookerPhoneSnapshot:
          json['bookerPhoneSnapshot'] as String? ?? '', // Số điện thoại liên hệ
      status: BookingStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => BookingStatus.pending, // Mặc định là pending chờ duyệt
      ),
      statusReason: json['statusReason'] as String?, // Lý do chuyển trạng thái
      subtotalAmount:
          (json['subtotalAmount'] as num?)?.toInt() ?? 0, // Tiền tạm tính
      discountAmount:
          (json['discountAmount'] as num?)?.toInt() ??
          0, // Tiền giảm giá khuyến mãi
      totalAmount:
          (json['totalAmount'] as num?)?.toInt() ??
          0, // Tổng tiền phải thanh toán
      customerNote:
          json['customerNote'] as String?, // Ghi chú của khách hàng khi đặt sân
      ownerNote: json['ownerNote'] as String?, // Ghi chú nội bộ của chủ sân
      cancellationReason:
          json['cancellationReason'] as String?, // Lý do hủy đặt sân nếu có
      confirmedAt: _nullableDateTime(
        json['confirmedAt'],
      ), // Thời điểm chủ sân xác nhận
      rejectedAt: _nullableDateTime(
        json['rejectedAt'],
      ), // Thời điểm chủ sân từ chối
      cancelledAt: _nullableDateTime(json['cancelledAt']), // Thời điểm bị hủy
      completedAt: _nullableDateTime(
        json['completedAt'],
      ), // Thời điểm trận đấu hoàn tất
      reviewedBy: json['reviewedBy'] as String?, // Người xét duyệt đơn
      createdAt: _dateTime(json['createdAt']), // Thời điểm tạo đơn
      updatedAt: _dateTime(
        json['updatedAt'],
      ), // Thời điểm cập nhật đơn gần nhất
    );
  }

  /// Chuyển đổi đối tượng Booking thành Map JSON để lưu trữ hoặc gửi API
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Mã booking
      'fieldId': fieldId, // Mã sân
      'ownerId': ownerId, // Mã chủ sân
      'bookerId': bookerId, // Mã người đặt
      'dateKey': dateKey, // Ngày đặt
      'startsAt': startsAt
          .toUtc()
          .toIso8601String(), // Giờ bắt đầu chuẩn UTC ISO 8601
      'endsAt': endsAt
          .toUtc()
          .toIso8601String(), // Giờ kết thúc chuẩn UTC ISO 8601
      'slotIds': slotIds, // Danh sách slot
      'fieldNameSnapshot': fieldNameSnapshot, // Tên sân snapshot
      'fieldAddressSnapshot': fieldAddressSnapshot, // Địa chỉ sân snapshot
      'priceSnapshot': priceSnapshot, // Giá snapshot
      'currency': currency, // Tiền tệ
      'bookerNameSnapshot': bookerNameSnapshot, // Tên người đặt snapshot
      'bookerPhoneSnapshot': bookerPhoneSnapshot, // Số điện thoại snapshot
      'status': status.name, // Trạng thái đơn đặt sân
      'statusReason': statusReason, // Lý do trạng thái
      'subtotalAmount': subtotalAmount, // Tạm tính
      'discountAmount': discountAmount, // Giảm giá
      'totalAmount': totalAmount, // Tổng tiền
      'customerNote': customerNote, // Ghi chú khách
      'ownerNote': ownerNote, // Ghi chú chủ sân
      'cancellationReason': cancellationReason, // Lý do hủy
      'confirmedAt': confirmedAt?.toUtc().toIso8601String(), // Giờ xác nhận
      'rejectedAt': rejectedAt?.toUtc().toIso8601String(), // Giờ từ chối
      'cancelledAt': cancelledAt?.toUtc().toIso8601String(), // Giờ hủy
      'completedAt': completedAt?.toUtc().toIso8601String(), // Giờ hoàn thành
      'reviewedBy': reviewedBy, // Người duyệt
      'createdAt': createdAt.toUtc().toIso8601String(), // Giờ tạo
      'updatedAt': updatedAt.toUtc().toIso8601String(), // Giờ cập nhật
    };
  }

  /// Hàm tiện ích trích xuất danh sách chuỗi an toàn từ JSON
  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
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

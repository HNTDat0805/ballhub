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

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String? ?? '',
      fieldId: json['fieldId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      bookerId: json['bookerId'] as String? ?? '',
      dateKey: json['dateKey'] as String? ?? '',
      startsAt: _dateTime(json['startsAt']),
      endsAt: _dateTime(json['endsAt']),
      slotIds: _stringList(json['slotIds']),
      fieldNameSnapshot: json['fieldNameSnapshot'] as String? ?? '',
      fieldAddressSnapshot: json['fieldAddressSnapshot'] as String? ?? '',
      priceSnapshot: (json['priceSnapshot'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'VND',
      bookerNameSnapshot: json['bookerNameSnapshot'] as String? ?? '',
      bookerPhoneSnapshot: json['bookerPhoneSnapshot'] as String? ?? '',
      status: BookingStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      statusReason: json['statusReason'] as String?,
      subtotalAmount: (json['subtotalAmount'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      customerNote: json['customerNote'] as String?,
      ownerNote: json['ownerNote'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      confirmedAt: _nullableDateTime(json['confirmedAt']),
      rejectedAt: _nullableDateTime(json['rejectedAt']),
      cancelledAt: _nullableDateTime(json['cancelledAt']),
      completedAt: _nullableDateTime(json['completedAt']),
      reviewedBy: json['reviewedBy'] as String?,
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fieldId': fieldId,
      'ownerId': ownerId,
      'bookerId': bookerId,
      'dateKey': dateKey,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
      'slotIds': slotIds,
      'fieldNameSnapshot': fieldNameSnapshot,
      'fieldAddressSnapshot': fieldAddressSnapshot,
      'priceSnapshot': priceSnapshot,
      'currency': currency,
      'bookerNameSnapshot': bookerNameSnapshot,
      'bookerPhoneSnapshot': bookerPhoneSnapshot,
      'status': status.name,
      'statusReason': statusReason,
      'subtotalAmount': subtotalAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'customerNote': customerNote,
      'ownerNote': ownerNote,
      'cancellationReason': cancellationReason,
      'confirmedAt': confirmedAt?.toUtc().toIso8601String(),
      'rejectedAt': rejectedAt?.toUtc().toIso8601String(),
      'cancelledAt': cancelledAt?.toUtc().toIso8601String(),
      'completedAt': completedAt?.toUtc().toIso8601String(),
      'reviewedBy': reviewedBy,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  static DateTime _dateTime(Object? value) {
    return _nullableDateTime(value) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static DateTime? _nullableDateTime(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}

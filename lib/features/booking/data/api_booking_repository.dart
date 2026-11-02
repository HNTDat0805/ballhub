import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../domain/models/booking.dart';
import '../domain/models/field_slot.dart';
import '../domain/models/football_field.dart';
import 'booking_repository.dart';
import 'seeds/booking_seed_data.dart';

/// Implementsation của [BookingRepository] sử dụng REST API thông qua [ApiClient].
///
/// Mọi lỗi HTTP đã được ApiClient chuẩn hóa thành [ApiException].
class ApiBookingRepository implements BookingRepository {
  final ApiClient _client;

  ApiBookingRepository({ApiClient? client}) : _client = client ?? ApiClient();

  static final List<FootballField> _userCreatedFields = [];

  // ───────── Quản lý Sân bóng (Field) ─────────

  @override
  Future<List<FootballField>> getFields({
    String? city,
    String? district,
    String? fieldType,
    String? status,
    String? ownerId,
    String? search,
  }) async {
    final params = <String, dynamic>{
      if (city != null) 'city': city,
      if (district != null) 'district': district,
      if (fieldType != null) 'fieldType': fieldType,
      if (status != null) 'status': status,
      if (ownerId != null) 'ownerId': ownerId,
      if (search != null) 'search': search,
    };
    List<FootballField> list = [];
    try {
      final data = await _client.get(
        '/fields',
        queryParams: params,
        timeout: const Duration(seconds: 3),
      );
      list = _parseList(data, FootballField.fromJson);
      if (list.isEmpty) {
        list = BookingSeedData.getSampleFields(
          city: city,
          district: district,
          fieldType: fieldType,
          search: search,
        );
      }
    } catch (_) {
      // Tự động dự phòng dữ liệu sân bóng mẫu khi backend chưa khởi động hoặc offline
      list = BookingSeedData.getSampleFields(
        city: city,
        district: district,
        fieldType: fieldType,
        search: search,
      );
    }

    final matchingCreated = _userCreatedFields.where((f) {
      if (status != null && f.status.name != status) {
        return false;
      }
      if (ownerId != null && f.ownerId.isNotEmpty && f.ownerId != ownerId) {
        return false;
      }
      if (city != null &&
          city.isNotEmpty &&
          !f.city.toLowerCase().contains(city.toLowerCase())) {
        return false;
      }
      if (district != null &&
          district.isNotEmpty &&
          !f.district.toLowerCase().contains(district.toLowerCase())) {
        return false;
      }
      if (fieldType != null &&
          fieldType.isNotEmpty &&
          f.fieldType != fieldType) {
        return false;
      }
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        final match =
            f.name.toLowerCase().contains(q) ||
            f.address.toLowerCase().contains(q) ||
            f.district.toLowerCase().contains(q) ||
            f.city.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    return [
      ...matchingCreated,
      ...list.where(
        (f) => !matchingCreated.any(
          (m) => m.id == f.id || m.name.toLowerCase() == f.name.toLowerCase(),
        ),
      ),
    ];
  }

  @override
  Future<FootballField> getFieldById(String fieldId) async {
    final created = _userCreatedFields
        .where((f) => f.id == fieldId)
        .firstOrNull;
    if (created != null) return created;

    try {
      final data = await _client.get(
        '/fields/$fieldId',
        timeout: const Duration(seconds: 3),
      );
      return FootballField.fromJson(_toMap(data));
    } catch (_) {
      return BookingSeedData.getSampleFields().firstWhere(
        (f) => f.id == fieldId,
        orElse: () => BookingSeedData.getSampleFields().first,
      );
    }
  }

  @override
  Future<FootballField> createField(Map<String, dynamic> data) async {
    try {
      final result = await _client.post('/fields', body: data);
      final field = FootballField.fromJson(_toMap(result));
      _userCreatedFields.removeWhere((f) => f.id == field.id);
      _userCreatedFields.insert(0, field);
      notifyBookingChanged();
      return field;
    } catch (e) {
      if (e is ApiException &&
          (e.code == 'NETWORK_ERROR' ||
              e.code == 'TIMEOUT' ||
              e.statusCode == 503)) {
        final localId = 'field_${DateTime.now().millisecondsSinceEpoch}';
        final localField = FootballField.fromJson({
          ...data,
          'id': localId,
          'rating': 5.0,
          'reviewCount': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
        _userCreatedFields.removeWhere(
          (f) => f.name.toLowerCase() == localField.name.toLowerCase(),
        );
        _userCreatedFields.insert(0, localField);
        notifyBookingChanged();
        return localField;
      }
      rethrow;
    }
  }

  @override
  Future<FootballField> updateField(
    String fieldId,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _client.patch('/fields/$fieldId', body: data);
      final field = FootballField.fromJson(_toMap(result));
      final idx = _userCreatedFields.indexWhere((f) => f.id == fieldId);
      if (idx != -1) {
        _userCreatedFields[idx] = field;
      }
      notifyBookingChanged();
      return field;
    } catch (e) {
      if (e is ApiException &&
          (e.code == 'NETWORK_ERROR' ||
              e.code == 'TIMEOUT' ||
              e.statusCode == 503)) {
        final idx = _userCreatedFields.indexWhere((f) => f.id == fieldId);
        if (idx != -1) {
          final updated = _userCreatedFields[idx].copyWith(
            name: data['name'] as String?,
            description: data['description'] as String?,
            address: data['address'] as String?,
            district: data['district'] as String?,
            city: data['city'] as String?,
            basePrice: data['basePrice'] as int?,
            capacity: data['capacity'] as int?,
          );
          _userCreatedFields[idx] = updated;
          notifyBookingChanged();
          return updated;
        }
      }
      rethrow;
    }
  }

  @override
  Future<FootballField> updateFieldStatus(String fieldId, String status) async {
    try {
      final result = await _client.patch(
        '/fields/$fieldId/status',
        body: {'status': status},
      );
      final field = FootballField.fromJson(_toMap(result));
      final idx = _userCreatedFields.indexWhere((f) => f.id == fieldId);
      if (idx != -1) {
        _userCreatedFields[idx] = field;
      }
      notifyBookingChanged();
      return field;
    } catch (_) {
      final idx = _userCreatedFields.indexWhere((f) => f.id == fieldId);
      if (idx != -1) {
        final parsedStatus = FieldStatus.values.firstWhere(
          (s) => s.name == status,
          orElse: () => FieldStatus.active,
        );
        final updated = _userCreatedFields[idx].copyWith(status: parsedStatus);
        _userCreatedFields[idx] = updated;
        notifyBookingChanged();
        return updated;
      }
      rethrow;
    }
  }

  // ───────── Quản lý Khung giờ (Slot) ─────────

  @override
  Future<List<FieldSlot>> getFieldSlots(
    String fieldId, {
    String? dateKey,
  }) async {
    final params = <String, dynamic>{if (dateKey != null) 'dateKey': dateKey};
    try {
      final data = await _client.get(
        '/fields/$fieldId/slots',
        queryParams: params,
        timeout: const Duration(seconds: 3),
      );
      final list = _parseList(data, FieldSlot.fromJson);
      if (list.isNotEmpty) {
        return list.map((s) {
          if (_bookedSlotIds.contains(s.id) &&
              s.status == FieldSlotStatus.available) {
            return s.copyWith(status: FieldSlotStatus.booked);
          }
          return s;
        }).toList();
      }
      return BookingSeedData.getSampleSlots(
        fieldId,
        dateKey: dateKey,
        bookedSlotIds: _bookedSlotIds,
      );
    } catch (_) {
      return BookingSeedData.getSampleSlots(
        fieldId,
        dateKey: dateKey,
        bookedSlotIds: _bookedSlotIds,
      );
    }
  }

  @override
  Future<FieldSlot> createSlot(
    String fieldId,
    Map<String, dynamic> data,
  ) async {
    final result = await _client.post('/fields/$fieldId/slots', body: data);
    return FieldSlot.fromJson(_toMap(result));
  }

  @override
  Future<FieldSlot> updateSlot(
    String fieldId,
    String slotId,
    Map<String, dynamic> data,
  ) async {
    final result = await _client.patch(
      '/fields/$fieldId/slots/$slotId',
      body: data,
    );
    return FieldSlot.fromJson(_toMap(result));
  }

  @override
  Future<FieldSlot> blockSlot(
    String fieldId,
    String slotId, {
    String? reason,
  }) async {
    final result = await _client.post(
      '/fields/$fieldId/slots/$slotId/block',
      body: {'reason': reason ?? 'Chủ sân khóa khung giờ.'},
    );
    return FieldSlot.fromJson(_toMap(result));
  }

  @override
  Future<FieldSlot> unblockSlot(String fieldId, String slotId) async {
    final result = await _client.post('/fields/$fieldId/slots/$slotId/unblock');
    return FieldSlot.fromJson(_toMap(result));
  }

  static final List<Booking> _fallbackBookings = [];
  static final Set<String> _bookedSlotIds = {};

  /// Danh sách các đơn đặt sân đã được lưu trong bộ nhớ cục bộ (đồng bộ 0ms)
  static List<Booking> get localBookings =>
      List.unmodifiable(_fallbackBookings);

  /// ValueNotifier thông báo cho toàn bộ ứng dụng khi danh sách hoặc trạng thái đặt sân thay đổi
  static final ValueNotifier<int> bookingChanged = ValueNotifier<int>(0);

  /// Kích hoạt thông báo thay đổi đặt sân
  static void notifyBookingChanged() => bookingChanged.value++;

  /// Dọn dẹp trạng thái cục bộ cho testing hoặc khi đăng xuất
  @visibleForTesting
  static void clearLocalState() {
    _userCreatedFields.clear();
    _fallbackBookings.clear();
    _bookedSlotIds.clear();
    notifyBookingChanged();
  }

  // ───────── Đặt sân người dùng (Booking) ─────────

  @override
  Future<Booking> createBooking({
    required String fieldId,
    required List<String> slotIds,
    String? customerNote,
  }) async {
    final body = <String, dynamic>{
      'fieldId': fieldId,
      'slotIds': slotIds,
      if (customerNote != null && customerNote.isNotEmpty)
        'customerNote': customerNote,
    };
    try {
      final result = await _client.post('/bookings', body: body);
      final booking = Booking.fromJson(_toMap(result));
      _fallbackBookings.insert(0, booking);
      _bookedSlotIds.addAll(slotIds);
      notifyBookingChanged();
      return booking;
    } catch (_) {
      // Tự động dự phòng tạo đơn đặt sân khi backend offline hoặc chạy dữ liệu mẫu
      final now = DateTime.now();
      final bookingId = 'booking_${now.millisecondsSinceEpoch}';
      final field = await getFieldById(fieldId);
      final slots = await getFieldSlots(fieldId);
      final bookedSlots = slots.where((s) => slotIds.contains(s.id)).toList();
      final total = bookedSlots.fold<int>(0, (sum, s) => sum + s.basePrice);

      for (final sId in slotIds) {
        _bookedSlotIds.add(sId);
      }

      final dateKey = bookedSlots.isNotEmpty
          ? bookedSlots.first.dateKey
          : '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final fallbackBooking = Booking(
        id: bookingId,
        fieldId: fieldId,
        ownerId: field.ownerId,
        bookerId: 'current_user',
        dateKey: dateKey,
        startsAt: bookedSlots.isNotEmpty
            ? bookedSlots.first.startsAt
            : now.add(const Duration(hours: 2)),
        endsAt: bookedSlots.isNotEmpty
            ? bookedSlots.last.endsAt
            : now.add(const Duration(hours: 3)),
        slotIds: slotIds,
        fieldNameSnapshot: field.name,
        fieldAddressSnapshot: field.address,
        priceSnapshot: bookedSlots.isNotEmpty
            ? bookedSlots.first.basePrice
            : 250000,
        currency: 'VND',
        bookerNameSnapshot: 'Người đặt sân',
        bookerPhoneSnapshot: '0901234567',
        status: BookingStatus.confirmed,
        subtotalAmount: total > 0 ? total : 250000,
        discountAmount: 0,
        totalAmount: total > 0 ? total : 250000,
        customerNote: customerNote,
        createdAt: now,
        updatedAt: now,
      );

      _fallbackBookings.insert(0, fallbackBooking);
      notifyBookingChanged();
      return fallbackBooking;
    }
  }

  @override
  Future<List<Booking>> getMyBookings() async {
    try {
      final data = await _client.get(
        '/bookings/me',
        timeout: const Duration(seconds: 3),
      );
      final list = _parseList(data, Booking.fromJson);
      if (list.isNotEmpty) {
        _fallbackBookings.clear();
        _fallbackBookings.addAll(list);
        return list;
      }
    } catch (_) {}
    return List.of(_fallbackBookings);
  }

  @override
  Future<Booking> getBooking(String bookingId) async {
    final cached = _fallbackBookings
        .where((b) => b.id == bookingId)
        .firstOrNull;
    try {
      final data = await _client.get(
        '/bookings/$bookingId',
        timeout: const Duration(seconds: 3),
      );
      final booking = Booking.fromJson(_toMap(data));
      final idx = _fallbackBookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) {
        _fallbackBookings[idx] = booking;
      } else {
        _fallbackBookings.add(booking);
      }
      return booking;
    } catch (_) {
      if (cached != null) return cached;
      return _fallbackBookings.firstWhere(
        (b) => b.id == bookingId,
        orElse: () => _fallbackBookings.first,
      );
    }
  }

  @override
  Future<Booking> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final result = await _client.post(
        '/bookings/$bookingId/cancel',
        body: {'reason': reason ?? ''},
      );
      final booking = Booking.fromJson(_toMap(result));
      _bookedSlotIds.removeAll(booking.slotIds);
      final idx = _fallbackBookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) {
        _fallbackBookings[idx] = booking;
      }
      notifyBookingChanged();
      return booking;
    } catch (_) {
      final idx = _fallbackBookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) {
        final b = _fallbackBookings[idx];
        final cancelled = Booking(
          id: b.id,
          fieldId: b.fieldId,
          ownerId: b.ownerId,
          bookerId: b.bookerId,
          dateKey: b.dateKey,
          startsAt: b.startsAt,
          endsAt: b.endsAt,
          slotIds: b.slotIds,
          fieldNameSnapshot: b.fieldNameSnapshot,
          fieldAddressSnapshot: b.fieldAddressSnapshot,
          priceSnapshot: b.priceSnapshot,
          currency: b.currency,
          bookerNameSnapshot: b.bookerNameSnapshot,
          bookerPhoneSnapshot: b.bookerPhoneSnapshot,
          status: BookingStatus.cancelledByUser,
          subtotalAmount: b.subtotalAmount,
          discountAmount: b.discountAmount,
          totalAmount: b.totalAmount,
          customerNote: b.customerNote,
          cancellationReason: reason,
          createdAt: b.createdAt,
          updatedAt: DateTime.now(),
        );
        _fallbackBookings[idx] = cancelled;
        for (final sId in b.slotIds) {
          _bookedSlotIds.remove(sId);
        }
        notifyBookingChanged();
        return cancelled;
      }
      rethrow;
    }
  }

  // ───────── Quản lý Đặt sân của Chủ sân (Owner Booking) ─────────

  @override
  Future<List<Booking>> getOwnerBookings() async {
    try {
      final data = await _client.get(
        '/owner/bookings',
        timeout: const Duration(seconds: 3),
      );
      return _parseList(data, Booking.fromJson);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Booking> confirmBooking(String bookingId) async {
    final result = await _client.post('/owner/bookings/$bookingId/confirm');
    return Booking.fromJson(_toMap(result));
  }

  @override
  Future<Booking> rejectBooking(
    String bookingId, {
    required String reason,
  }) async {
    final result = await _client.post(
      '/owner/bookings/$bookingId/reject',
      body: {'reason': reason},
    );
    return Booking.fromJson(_toMap(result));
  }

  @override
  Future<Booking> ownerCancelBooking(
    String bookingId, {
    required String reason,
  }) async {
    final result = await _client.post(
      '/owner/bookings/$bookingId/cancel',
      body: {'reason': reason},
    );
    return Booking.fromJson(_toMap(result));
  }

  // ───────── Hàm tiện ích & Dữ liệu dự phòng ─────────

  static Map<String, dynamic> _toMap(dynamic val) {
    if (val is Map<String, dynamic>) return val;
    if (val is Map) return Map<String, dynamic>.from(val);
    return <String, dynamic>{};
  }

  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

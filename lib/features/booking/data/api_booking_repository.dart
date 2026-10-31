import '../../../core/api/api_client.dart';
import '../domain/models/booking.dart';
import '../domain/models/field_slot.dart';
import '../domain/models/football_field.dart';
import 'booking_repository.dart';

/// Implementsation của [BookingRepository] sử dụng REST API thông qua [ApiClient].
///
/// Mọi lỗi HTTP đã được ApiClient chuẩn hóa thành [ApiException].
class ApiBookingRepository implements BookingRepository {
  final ApiClient _client;

  ApiBookingRepository({ApiClient? client}) : _client = client ?? ApiClient();

  // ───────── Field ─────────

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
    try {
      final data = await _client.get('/fields', queryParams: params);
      final list = _parseList(data, FootballField.fromJson);
      if (list.isNotEmpty) return list;
      return _getFallbackSampleFields(
        city: city,
        district: district,
        fieldType: fieldType,
        search: search,
      );
    } catch (_) {
      // Tự động dự phòng dữ liệu sân bóng mẫu khi backend chưa khởi động hoặc offline
      return _getFallbackSampleFields(
        city: city,
        district: district,
        fieldType: fieldType,
        search: search,
      );
    }
  }

  @override
  Future<FootballField> getFieldById(String fieldId) async {
    try {
      final data = await _client.get('/fields/$fieldId');
      return FootballField.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return _getFallbackSampleFields().firstWhere(
        (f) => f.id == fieldId,
        orElse: () => _getFallbackSampleFields().first,
      );
    }
  }

  @override
  Future<FootballField> createField(Map<String, dynamic> data) async {
    final result = await _client.post('/fields', body: data);
    return FootballField.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<FootballField> updateField(String fieldId, Map<String, dynamic> data) async {
    final result = await _client.patch('/fields/$fieldId', body: data);
    return FootballField.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<FootballField> updateFieldStatus(String fieldId, String status) async {
    final result = await _client.patch('/fields/$fieldId/status', body: {'status': status});
    return FootballField.fromJson(result as Map<String, dynamic>);
  }

  // ───────── Slot ─────────

  @override
  Future<List<FieldSlot>> getFieldSlots(String fieldId, {String? dateKey}) async {
    final params = <String, dynamic>{
      if (dateKey != null) 'dateKey': dateKey,
    };
    try {
      final data = await _client.get('/fields/$fieldId/slots', queryParams: params);
      final list = _parseList(data, FieldSlot.fromJson);
      if (list.isNotEmpty) return list;
      return _getFallbackSampleSlots(fieldId, dateKey: dateKey);
    } catch (_) {
      return _getFallbackSampleSlots(fieldId, dateKey: dateKey);
    }
  }

  @override
  Future<FieldSlot> createSlot(String fieldId, Map<String, dynamic> data) async {
    final result = await _client.post('/fields/$fieldId/slots', body: data);
    return FieldSlot.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<FieldSlot> updateSlot(String fieldId, String slotId, Map<String, dynamic> data) async {
    final result = await _client.patch('/fields/$fieldId/slots/$slotId', body: data);
    return FieldSlot.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<FieldSlot> blockSlot(String fieldId, String slotId, {String? reason}) async {
    final result = await _client.post(
      '/fields/$fieldId/slots/$slotId/block',
      body: {'reason': reason ?? 'Chủ sân khóa khung giờ.'},
    );
    return FieldSlot.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<FieldSlot> unblockSlot(String fieldId, String slotId) async {
    final result = await _client.post('/fields/$fieldId/slots/$slotId/unblock');
    return FieldSlot.fromJson(result as Map<String, dynamic>);
  }

  // ───────── Booking ─────────

  @override
  Future<Booking> createBooking({
    required String fieldId,
    required List<String> slotIds,
    String? customerNote,
  }) async {
    final body = <String, dynamic>{
      'fieldId': fieldId,
      'slotIds': slotIds,
      if (customerNote != null && customerNote.isNotEmpty) 'customerNote': customerNote,
    };
    final result = await _client.post('/bookings', body: body);
    return Booking.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<List<Booking>> getMyBookings() async {
    try {
      final data = await _client.get('/bookings/me');
      return _parseList(data, Booking.fromJson);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Booking> getBooking(String bookingId) async {
    final data = await _client.get('/bookings/$bookingId');
    return Booking.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Booking> cancelBooking(String bookingId, {String? reason}) async {
    final result = await _client.post(
      '/bookings/$bookingId/cancel',
      body: {'reason': reason ?? ''},
    );
    return Booking.fromJson(result as Map<String, dynamic>);
  }

  // ───────── Owner Booking ─────────

  @override
  Future<List<Booking>> getOwnerBookings() async {
    try {
      final data = await _client.get('/owner/bookings');
      return _parseList(data, Booking.fromJson);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Booking> confirmBooking(String bookingId) async {
    final result = await _client.post('/owner/bookings/$bookingId/confirm');
    return Booking.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<Booking> rejectBooking(String bookingId, {required String reason}) async {
    final result = await _client.post(
      '/owner/bookings/$bookingId/reject',
      body: {'reason': reason},
    );
    return Booking.fromJson(result as Map<String, dynamic>);
  }

  // ───────── Helpers & Fallbacks ─────────

  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  static List<FootballField> _getFallbackSampleFields({
    String? city,
    String? district,
    String? fieldType,
    String? search,
  }) {
    final now = DateTime.now();
    final fields = [
      FootballField(
        id: 'field_gia_dinh',
        ownerId: 'owner_01',
        name: 'Sân bóng Gia Định',
        description: 'Sân cỏ nhân tạo chất lượng cao, thoáng mát, đạt chuẩn thi đấu.',
        coverImageUrl: 'https://images.unsplash.com/photo-1529900245534-47fbfb57835a?auto=format&fit=crop&w=800&q=80',
        imageUrls: const [
          'https://images.unsplash.com/photo-1529900245534-47fbfb57835a?auto=format&fit=crop&w=800&q=80',
        ],
        address: '2A Phan Chu Trinh, Phường 12',
        district: 'Bình Thạnh',
        city: 'TP. Hồ Chí Minh',
        latitude: 10.8012,
        longitude: 106.6987,
        fieldType: '7-a-side',
        capacity: 14,
        amenities: const ['Wifi', 'Gửi xe', 'Nước uống', 'Đèn chiếu sáng', 'Phòng thay đồ'],
        basePrice: 300000,
        currency: 'VND',
        slotDurationMinutes: 60,
        status: FieldStatus.active,
        openingHours: const {
          'mon': ['06:00', '23:00'],
          'tue': ['06:00', '23:00'],
          'wed': ['06:00', '23:00'],
          'thu': ['06:00', '23:00'],
          'fri': ['06:00', '23:00'],
          'sat': ['06:00', '23:00'],
          'sun': ['06:00', '23:00'],
        },
        timezone: 'Asia/Ho_Chi_Minh',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
        createdBy: 'owner_01',
        updatedBy: 'owner_01',
      ),
      FootballField(
        id: 'field_binh_quoi',
        ownerId: 'owner_01',
        name: 'Sân bóng Bình Quới',
        description: 'Cụm sân 5 và sân 7 ven sông, không khí mát mẻ, bãi giữ xe ô tô rộng rãi.',
        coverImageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80',
        imageUrls: const [
          'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80',
        ],
        address: '1143 Bình Quới, Cư xá Thanh Đa',
        district: 'Bình Thạnh',
        city: 'TP. Hồ Chí Minh',
        latitude: 10.8256,
        longitude: 106.7312,
        fieldType: '7-a-side',
        capacity: 14,
        amenities: const ['Căn tin', 'Gửi xe ô tô', 'Nước uống', 'Trọng tài'],
        basePrice: 350000,
        currency: 'VND',
        slotDurationMinutes: 60,
        status: FieldStatus.active,
        openingHours: const {
          'mon': ['06:00', '23:00'],
          'tue': ['06:00', '23:00'],
          'wed': ['06:00', '23:00'],
          'thu': ['06:00', '23:00'],
          'fri': ['06:00', '23:00'],
          'sat': ['06:00', '23:00'],
          'sun': ['06:00', '23:00'],
        },
        timezone: 'Asia/Ho_Chi_Minh',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
        createdBy: 'owner_01',
        updatedBy: 'owner_01',
      ),
      FootballField(
        id: 'field_thanh_da',
        ownerId: 'owner_01',
        name: 'Sân bóng Thanh Đa',
        description: 'Sân cỏ nhân tạo mới nâng cấp mặt cỏ đạt chuẩn FIFA 2 sao.',
        coverImageUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=800&q=80',
        imageUrls: const [
          'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=800&q=80',
        ],
        address: 'Lô IV Cư xá Thanh Đa',
        district: 'Bình Thạnh',
        city: 'TP. Hồ Chí Minh',
        latitude: 10.8142,
        longitude: 106.7210,
        fieldType: '5-a-side',
        capacity: 10,
        amenities: const ['Wifi', 'Gửi xe máy', 'Áo bib thi đấu'],
        basePrice: 280000,
        currency: 'VND',
        slotDurationMinutes: 60,
        status: FieldStatus.active,
        openingHours: const {
          'mon': ['06:00', '23:00'],
          'tue': ['06:00', '23:00'],
          'wed': ['06:00', '23:00'],
          'thu': ['06:00', '23:00'],
          'fri': ['06:00', '23:00'],
          'sat': ['06:00', '23:00'],
          'sun': ['06:00', '23:00'],
        },
        timezone: 'Asia/Ho_Chi_Minh',
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now,
        createdBy: 'owner_01',
        updatedBy: 'owner_01',
      ),
    ];

    return fields.where((f) {
      if (city != null && f.city.toLowerCase() != city.toLowerCase()) return false;
      if (district != null && f.district.toLowerCase() != district.toLowerCase()) return false;
      if (fieldType != null && f.fieldType != fieldType) return false;
      if (search != null && search.trim().isNotEmpty) {
        final query = search.trim().toLowerCase();
        final match = f.name.toLowerCase().contains(query) ||
            f.address.toLowerCase().contains(query) ||
            f.district.toLowerCase().contains(query);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  static List<FieldSlot> _getFallbackSampleSlots(String fieldId, {String? dateKey}) {
    final now = DateTime.now();
    final dKey = dateKey ??
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final parts = dKey.split('-');
    final targetDate = parts.length == 3
        ? DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
        : now;

    final hours = [7, 8, 9, 15, 16, 17, 18, 19, 20, 21];
    return hours.map((h) {
      final start = DateTime(targetDate.year, targetDate.month, targetDate.day, h, 0);
      final end = start.add(const Duration(hours: 1));
      final isHeld = h == 18;
      final isBooked = h == 19;
      return FieldSlot(
        id: 'slot_${fieldId}_${dKey}_$h',
        fieldId: fieldId,
        dateKey: dKey,
        startsAt: start,
        endsAt: end,
        durationMinutes: 60,
        basePrice: (h >= 17 && h <= 20) ? 350000 : 250000,
        currency: 'VND',
        status: isBooked
            ? FieldSlotStatus.booked
            : isHeld
                ? FieldSlotStatus.held
                : FieldSlotStatus.available,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      );
    }).toList();
  }
}

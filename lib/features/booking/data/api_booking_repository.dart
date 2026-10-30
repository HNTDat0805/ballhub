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
    final data = await _client.get('/fields', queryParams: params);
    return _parseList(data, FootballField.fromJson);
  }

  @override
  Future<FootballField> getFieldById(String fieldId) async {
    final data = await _client.get('/fields/$fieldId');
    return FootballField.fromJson(data as Map<String, dynamic>);
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
    final data = await _client.get('/fields/$fieldId/slots', queryParams: params);
    return _parseList(data, FieldSlot.fromJson);
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
    final data = await _client.get('/bookings/me');
    return _parseList(data, Booking.fromJson);
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
    final data = await _client.get('/owner/bookings');
    return _parseList(data, Booking.fromJson);
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

  // ───────── Helpers ─────────

  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}

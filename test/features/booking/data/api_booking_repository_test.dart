import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ballhub/core/api/api_client.dart';
import 'package:ballhub/features/booking/data/api_booking_repository.dart';
import 'package:ballhub/features/booking/domain/models/booking.dart';
import 'package:ballhub/features/booking/domain/models/field_slot.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

http.Response jsonResponse(dynamic data, [int statusCode = 200]) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(data)),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  group('ApiBookingRepository Client Tests (22 test cases)', () {
    final sampleFieldMap = {
      'id': 'f_1',
      'ownerId': 'owner_1',
      'name': 'Sân Bóng Chuyên Nghiệp',
      'description': 'Mặt cỏ FIFA Pro',
      'address': '123 Nguyễn Thị Minh Khai',
      'district': 'Quận 1',
      'city': 'TP. Hồ Chí Minh',
      'fieldType': '7_a_side',
      'capacity': 14,
      'basePrice': 300000,
      'currency': 'VND',
      'slotDurationMinutes': 60,
      'status': 'active',
      'createdAt': '2026-06-01T00:00:00.000Z',
      'updatedAt': '2026-06-01T00:00:00.000Z',
    };

    final sampleSlotMap = {
      'id': 'slot_1',
      'fieldId': 'f_1',
      'dateKey': '2026-07-01',
      'startsAt': '2026-07-01T17:00:00.000Z',
      'endsAt': '2026-07-01T18:00:00.000Z',
      'basePrice': 300000,
      'currency': 'VND',
      'status': 'available',
      'createdAt': '2026-06-01T00:00:00.000Z',
      'updatedAt': '2026-06-01T00:00:00.000Z',
    };

    final sampleBookingMap = {
      'id': 'bk_1',
      'fieldId': 'f_1',
      'ownerId': 'owner_1',
      'bookerId': 'player_1',
      'dateKey': '2026-07-01',
      'startsAt': '2026-07-01T17:00:00.000Z',
      'endsAt': '2026-07-01T18:00:00.000Z',
      'slotIds': ['slot_1'],
      'fieldNameSnapshot': 'Sân Bóng Chuyên Nghiệp',
      'fieldAddressSnapshot': '123 Nguyễn Thị Minh Khai',
      'priceSnapshot': 300000,
      'currency': 'VND',
      'bookerNameSnapshot': 'Cầu thủ A',
      'bookerPhoneSnapshot': '0901234567',
      'status': 'pending',
      'subtotalAmount': 300000,
      'discountAmount': 0,
      'totalAmount': 300000,
      'createdAt': '2026-06-01T00:00:00.000Z',
      'updatedAt': '2026-06-01T00:00:00.000Z',
    };

    // 1. getFields returns list
    test('1. getFields fetches list of fields with query parameters', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/fields');
        expect(req.url.queryParameters['city'], 'TP. Hồ Chí Minh');
        return jsonResponse({'success': true, 'data': [sampleFieldMap]});
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final fields = await repo.getFields(city: 'TP. Hồ Chí Minh');
      expect(fields.length, 1);
      expect(fields.first.name, 'Sân Bóng Chuyên Nghiệp');
    });

    // 2. getFields fallback on error
    test('2. getFields returns fallback sample fields on error', () async {
      final mock = MockHttpClient((req) async => jsonResponse('Error', 500));
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final fields = await repo.getFields();
      expect(fields.isNotEmpty, true);
    });

    // 3. getFieldById
    test('3. getFieldById returns field details', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/fields/f_1');
        return jsonResponse({'success': true, 'data': sampleFieldMap});
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final field = await repo.getFieldById('f_1');
      expect(field.id, 'f_1');
      expect(field.district, 'Quận 1');
    });

    // 4. createField
    test('4. createField posts field data and returns created field', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/v1/fields');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleFieldMap}, 201);
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final created = await repo.createField({'name': 'Sân Mới'});
      expect(body['name'], 'Sân Mới');
      expect(created.name, 'Sân Bóng Chuyên Nghiệp');
    });

    // 5. updateField
    test('5. updateField patches field data', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'PATCH');
        expect(req.url.path, '/api/v1/fields/f_1');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleFieldMap});
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      await repo.updateField('f_1', {'description': 'Mô tả mới'});
      expect(body['description'], 'Mô tả mới');
    });

    // 6. updateFieldStatus
    test('6. updateFieldStatus patches status endpoint', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'PATCH');
        expect(req.url.path, '/api/v1/fields/f_1/status');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleFieldMap});
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      await repo.updateFieldStatus('f_1', 'inactive');
      expect(body['status'], 'inactive');
    });

    // 7. getFieldSlots
    test('7. getFieldSlots fetches slots for a given date', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/fields/f_1/slots');
        expect(req.url.queryParameters['dateKey'], '2026-07-01');
        return jsonResponse({'success': true, 'data': [sampleSlotMap]});
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final slots = await repo.getFieldSlots('f_1', dateKey: '2026-07-01');
      expect(slots.length, 1);
      expect(slots.first.id, 'slot_1');
      expect(slots.first.status, FieldSlotStatus.available);
    });

    // 8. createSlot
    test('8. createSlot posts new slot data', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/v1/fields/f_1/slots');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleSlotMap}, 201);
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final slot = await repo.createSlot('f_1', {'dateKey': '2026-07-01'});
      expect(body['dateKey'], '2026-07-01');
      expect(slot.id, 'slot_1');
    });

    // 9. updateSlot
    test('9. updateSlot patches slot info', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'PATCH');
        expect(req.url.path, '/api/v1/fields/f_1/slots/slot_1');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleSlotMap});
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      await repo.updateSlot('f_1', 'slot_1', {'basePrice': 350000});
      expect(body['basePrice'], 350000);
    });

    // 10. blockSlot
    test('10. blockSlot posts to /block endpoint with reason', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/v1/fields/f_1/slots/slot_1/block');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse(
            {'success': true, 'data': {...sampleSlotMap, 'status': 'blocked'}});
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final slot = await repo.blockSlot('f_1', 'slot_1', reason: 'Bảo trì sân');
      expect(body['reason'], 'Bảo trì sân');
      expect(slot.status, FieldSlotStatus.blocked);
    });

    // 11. unblockSlot
    test('11. unblockSlot posts to /unblock endpoint', () async {
      final mock = MockHttpClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/v1/fields/f_1/slots/slot_1/unblock');
        return jsonResponse({'success': true, 'data': sampleSlotMap});
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final slot = await repo.unblockSlot('f_1', 'slot_1');
      expect(slot.status, FieldSlotStatus.available);
    });

    // 12. createBooking
    test('12. createBooking posts booking request to /bookings', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/v1/bookings');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({'success': true, 'data': sampleBookingMap}, 201);
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final booking = await repo.createBooking(
        fieldId: 'f_1',
        slotIds: ['slot_1'],
        customerNote: 'Chuẩn bị thêm bóng',
      );
      expect(body['fieldId'], 'f_1');
      expect(body['customerNote'], 'Chuẩn bị thêm bóng');
      expect(booking.id, 'bk_1');
      expect(booking.status, BookingStatus.pending);
    });

    // 13. getMyBookings
    test('13. getMyBookings fetches current user bookings', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/bookings/me');
        return jsonResponse({'success': true, 'data': [sampleBookingMap]});
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final myBookings = await repo.getMyBookings();
      expect(myBookings.length, 1);
      expect(myBookings.first.totalAmount, 300000);
    });

    // 14. getBooking by ID
    test('14. getBooking fetches specific booking by ID', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/bookings/bk_1');
        return jsonResponse({'success': true, 'data': sampleBookingMap});
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final booking = await repo.getBooking('bk_1');
      expect(booking.id, 'bk_1');
      expect(booking.fieldNameSnapshot, 'Sân Bóng Chuyên Nghiệp');
    });

    // 15. cancelBooking
    test('15. cancelBooking posts cancellation reason to /cancel', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/v1/bookings/bk_1/cancel');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({
          'success': true,
          'data': {...sampleBookingMap, 'status': 'cancelledByUser'}
        });
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final cancelled = await repo.cancelBooking('bk_1', reason: 'Trời mưa bão');
      expect(body['reason'], 'Trời mưa bão');
      expect(cancelled.status, BookingStatus.cancelledByUser);
    });

    // 16. getOwnerBookings
    test('16. getOwnerBookings fetches bookings for field owner', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.path, '/api/v1/owner/bookings');
        return jsonResponse({'success': true, 'data': [sampleBookingMap]});
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final ownerList = await repo.getOwnerBookings();
      expect(ownerList.length, 1);
      expect(ownerList.first.ownerId, 'owner_1');
    });

    // 17. confirmBooking
    test('17. confirmBooking confirms pending booking by owner', () async {
      final mock = MockHttpClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/v1/owner/bookings/bk_1/confirm');
        return jsonResponse({
          'success': true,
          'data': {...sampleBookingMap, 'status': 'confirmed'}
        });
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final confirmed = await repo.confirmBooking('bk_1');
      expect(confirmed.status, BookingStatus.confirmed);
    });

    // 18. rejectBooking
    test('18. rejectBooking rejects booking with reason by owner', () async {
      late Map<String, dynamic> body;
      final mock = MockHttpClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/v1/owner/bookings/bk_1/reject');
        body = jsonDecode((req as http.Request).body);
        return jsonResponse({
          'success': true,
          'data': {...sampleBookingMap, 'status': 'rejected'}
        });
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final rejected = await repo.rejectBooking('bk_1', reason: 'Hỏng dàn đèn chiếu sáng');
      expect(body['reason'], 'Hỏng dàn đèn chiếu sáng');
      expect(rejected.status, BookingStatus.rejected);
    });

    // 19. filter by fieldType in getFields
    test('19. getFields passes fieldType parameter properly', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.queryParameters['fieldType'], '7_a_side');
        return jsonResponse({'success': true, 'data': [sampleFieldMap]});
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final fields = await repo.getFields(fieldType: '7_a_side');
      expect(fields.length, 1);
    });

    // 20. filter by search query in getFields
    test('20. getFields passes search keyword properly', () async {
      final mock = MockHttpClient((req) async {
        expect(req.url.queryParameters['search'], 'Chuyên Nghiệp');
        return jsonResponse({'success': true, 'data': [sampleFieldMap]});
      });
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final fields = await repo.getFields(search: 'Chuyên Nghiệp');
      expect(fields.length, 1);
    });

    // 21. createBooking fallback calculation
    test('21. createBooking calculates fallback amounts when offline', () async {
      final mock = MockHttpClient((req) async => jsonResponse('Network offline', 503));
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final booking = await repo.createBooking(
        fieldId: 'field_gia_dinh',
        slotIds: ['slot_101'],
        customerNote: 'Ghi chú fallback',
      );
      expect(booking.fieldId, 'field_gia_dinh');
      expect(booking.customerNote, 'Ghi chú fallback');
      expect(booking.status, BookingStatus.confirmed);
    });

    // 22. cancelBooking fallback updates offline state
    test('22. cancelBooking updates fallback list when offline', () async {
      final mock = MockHttpClient((req) async => jsonResponse('Network offline', 503));
      final repo = ApiBookingRepository(
          client: ApiClient(baseUrl: 'http://localhost:5001/api/v1', client: mock));

      final booking = await repo.createBooking(
        fieldId: 'field_offline',
        slotIds: ['slot_off_1'],
      );
      final cancelled = await repo.cancelBooking(booking.id, reason: 'Bận đột xuất');
      expect(cancelled.status, BookingStatus.cancelledByUser);
      expect(cancelled.cancellationReason, 'Bận đột xuất');
    });
  });
}

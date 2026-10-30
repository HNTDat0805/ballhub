import 'package:flutter_test/flutter_test.dart';
import 'package:ballhub/features/booking/domain/models/booking.dart';
import 'package:ballhub/features/booking/domain/models/field_slot.dart';
import 'package:ballhub/features/booking/domain/models/football_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test helpers — tạo dữ liệu mẫu nhất quán
// ─────────────────────────────────────────────────────────────────────────────

Booking _makeBooking({BookingStatus status = BookingStatus.pending, Map<String, dynamic>? overrides}) {
  final json = <String, dynamic>{
    'id': 'booking_001',
    'fieldId': 'field_001',
    'ownerId': 'owner_001',
    'bookerId': 'player_001',
    'dateKey': '2026-11-01',
    'startsAt': '2026-11-01T08:00:00.000Z',
    'endsAt': '2026-11-01T09:00:00.000Z',
    'slotIds': ['slot_001'],
    'fieldNameSnapshot': 'Sân 5 người Hoàng Mai A',
    'fieldAddressSnapshot': '123 Đường Hoàng Mai, Hà Nội',
    'priceSnapshot': 300000,
    'currency': 'VND',
    'bookerNameSnapshot': 'Nguyễn Văn A',
    'bookerPhoneSnapshot': '0901234567',
    'status': status.name,
    'subtotalAmount': 300000,
    'discountAmount': 0,
    'totalAmount': 300000,
    'createdAt': '2026-10-30T07:00:00.000Z',
    'updatedAt': '2026-10-30T07:00:00.000Z',
    ...?overrides,
  };
  return Booking.fromJson(json);
}

FieldSlot _makeSlot({FieldSlotStatus status = FieldSlotStatus.available, Map<String, dynamic>? overrides}) {
  final json = <String, dynamic>{
    'id': 'slot_001',
    'fieldId': 'field_001',
    'dateKey': '2026-11-01',
    'startsAt': '2026-11-01T08:00:00.000Z',
    'endsAt': '2026-11-01T09:00:00.000Z',
    'durationMinutes': 60,
    'basePrice': 300000,
    'currency': 'VND',
    'status': status.name,
    'createdAt': '2026-10-30T06:00:00.000Z',
    'updatedAt': '2026-10-30T06:00:00.000Z',
    ...?overrides,
  };
  return FieldSlot.fromJson(json);
}

FootballField _makeField({FieldStatus status = FieldStatus.active, Map<String, dynamic>? overrides}) {
  final json = <String, dynamic>{
    'id': 'field_001',
    'ownerId': 'owner_001',
    'name': 'Sân 5 người Hoàng Mai A',
    'description': 'Sân cỏ nhân tạo chất lượng cao',
    'coverImageUrl': '',
    'imageUrls': <String>[],
    'address': '123 Đường Hoàng Mai',
    'district': 'Hoàng Mai',
    'city': 'Hà Nội',
    'latitude': 21.003,
    'longitude': 105.845,
    'fieldType': '5 người',
    'capacity': 10,
    'amenities': ['wifi', 'parking'],
    'basePrice': 300000,
    'currency': 'VND',
    'slotDurationMinutes': 60,
    'status': status.name,
    'openingHours': <String, dynamic>{},
    'timezone': 'Asia/Ho_Chi_Minh',
    'createdAt': '2026-10-01T00:00:00.000Z',
    'updatedAt': '2026-10-01T00:00:00.000Z',
    'createdBy': 'owner_001',
    'updatedBy': 'owner_001',
    ...?overrides,
  };
  return FootballField.fromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking model tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Booking.fromJson', () {
    test('parse fields cơ bản từ JSON hợp lệ', () {
      final booking = _makeBooking();
      expect(booking.id, 'booking_001');
      expect(booking.fieldId, 'field_001');
      expect(booking.ownerId, 'owner_001');
      expect(booking.bookerId, 'player_001');
      expect(booking.dateKey, '2026-11-01');
      expect(booking.fieldNameSnapshot, 'Sân 5 người Hoàng Mai A');
      expect(booking.currency, 'VND');
      expect(booking.status, BookingStatus.pending);
      expect(booking.totalAmount, 300000);
      expect(booking.discountAmount, 0);
      expect(booking.slotIds, ['slot_001']);
    });

    test('parse DateTime UTC đúng', () {
      final booking = _makeBooking();
      expect(booking.startsAt.isUtc, isTrue);
      expect(booking.startsAt.hour, 8);
      expect(booking.endsAt.hour, 9);
      expect(booking.createdAt.isUtc, isTrue);
    });

    test('status parse đúng theo enum name', () {
      expect(_makeBooking(status: BookingStatus.pending).status, BookingStatus.pending);
      expect(_makeBooking(status: BookingStatus.confirmed).status, BookingStatus.confirmed);
      expect(_makeBooking(status: BookingStatus.rejected).status, BookingStatus.rejected);
      expect(_makeBooking(status: BookingStatus.cancelledByUser).status, BookingStatus.cancelledByUser);
      expect(_makeBooking(status: BookingStatus.cancelledByOwner).status, BookingStatus.cancelledByOwner);
      expect(_makeBooking(status: BookingStatus.completed).status, BookingStatus.completed);
    });

    test('status không hợp lệ fallback về pending', () {
      final booking = _makeBooking(overrides: {'status': 'unknownState'});
      expect(booking.status, BookingStatus.pending);
    });

    test('optional fields null khi không có', () {
      final booking = _makeBooking();
      expect(booking.customerNote, isNull);
      expect(booking.ownerNote, isNull);
      expect(booking.cancellationReason, isNull);
      expect(booking.confirmedAt, isNull);
      expect(booking.rejectedAt, isNull);
      expect(booking.cancelledAt, isNull);
    });

    test('parse confirmedAt khi có trong JSON', () {
      final booking = _makeBooking(overrides: {
        'status': 'confirmed',
        'confirmedAt': '2026-10-30T10:00:00.000Z',
      });
      expect(booking.confirmedAt, isNotNull);
      expect(booking.confirmedAt!.isUtc, isTrue);
    });

    test('parse cancellationReason khi booking cancelled', () {
      final booking = _makeBooking(overrides: {
        'status': 'cancelledByUser',
        'cancellationReason': 'Tôi bận đột xuất',
        'cancelledAt': '2026-10-30T11:00:00.000Z',
      });
      expect(booking.cancellationReason, 'Tôi bận đột xuất');
      expect(booking.cancelledAt, isNotNull);
    });

    test('slotIds là immutable List', () {
      final booking = _makeBooking(overrides: {
        'slotIds': ['slot_001', 'slot_002'],
      });
      expect(booking.slotIds, hasLength(2));
      expect(() => (booking.slotIds as dynamic).add('slot_003'), throwsUnsupportedError);
    });

    test('toJson → fromJson round-trip', () {
      final original = _makeBooking(
        status: BookingStatus.confirmed,
        overrides: {
          'customerNote': 'Xin vui lòng chuẩn bị sân trước 10 phút',
          'confirmedAt': '2026-10-30T10:00:00.000Z',
        },
      );
      final json = original.toJson();
      final restored = Booking.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.status, original.status);
      expect(restored.customerNote, original.customerNote);
      expect(restored.confirmedAt?.toIso8601String(), original.confirmedAt?.toIso8601String());
      expect(restored.totalAmount, original.totalAmount);
    });

    test('priceSnapshot lớn hơn 0 và khớp totalAmount khi không có discount', () {
      final booking = _makeBooking();
      expect(booking.priceSnapshot, greaterThan(0));
      expect(booking.subtotalAmount, booking.totalAmount); // không có discount
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // FieldSlot model tests
  // ─────────────────────────────────────────────────────────────────────────────

  group('FieldSlot.fromJson', () {
    test('parse fields cơ bản', () {
      final slot = _makeSlot();
      expect(slot.id, 'slot_001');
      expect(slot.fieldId, 'field_001');
      expect(slot.dateKey, '2026-11-01');
      expect(slot.durationMinutes, 60);
      expect(slot.basePrice, 300000);
      expect(slot.currency, 'VND');
      expect(slot.status, FieldSlotStatus.available);
    });

    test('status parse đúng tất cả giá trị', () {
      expect(_makeSlot(status: FieldSlotStatus.available).status, FieldSlotStatus.available);
      expect(_makeSlot(status: FieldSlotStatus.held).status, FieldSlotStatus.held);
      expect(_makeSlot(status: FieldSlotStatus.booked).status, FieldSlotStatus.booked);
      expect(_makeSlot(status: FieldSlotStatus.blocked).status, FieldSlotStatus.blocked);
    });

    test('status không hợp lệ fallback về available', () {
      final slot = _makeSlot(overrides: {'status': 'unknown'});
      expect(slot.status, FieldSlotStatus.available);
    });

    test('startsAt trước endsAt', () {
      final slot = _makeSlot();
      expect(slot.startsAt.isBefore(slot.endsAt), isTrue);
    });

    test('bookingId null khi slot available', () {
      expect(_makeSlot().bookingId, isNull);
    });

    test('bookingId có giá trị khi slot held', () {
      final slot = _makeSlot(
        status: FieldSlotStatus.held,
        overrides: {'bookingId': 'booking_001'},
      );
      expect(slot.bookingId, 'booking_001');
    });

    test('blockReason có giá trị khi slot blocked', () {
      final slot = _makeSlot(
        status: FieldSlotStatus.blocked,
        overrides: {'blockReason': 'Bảo trì cỏ nhân tạo'},
      );
      expect(slot.blockReason, 'Bảo trì cỏ nhân tạo');
    });

    test('toJson → fromJson round-trip', () {
      final original = _makeSlot(
        status: FieldSlotStatus.held,
        overrides: {'bookingId': 'booking_001'},
      );
      final json = original.toJson();
      final restored = FieldSlot.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.status, original.status);
      expect(restored.bookingId, original.bookingId);
      expect(restored.durationMinutes, original.durationMinutes);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // FootballField model tests
  // ─────────────────────────────────────────────────────────────────────────────

  group('FootballField.fromJson', () {
    test('parse fields cơ bản', () {
      final field = _makeField();
      expect(field.id, 'field_001');
      expect(field.ownerId, 'owner_001');
      expect(field.name, 'Sân 5 người Hoàng Mai A');
      expect(field.city, 'Hà Nội');
      expect(field.district, 'Hoàng Mai');
      expect(field.fieldType, '5 người');
      expect(field.capacity, 10);
      expect(field.basePrice, 300000);
      expect(field.currency, 'VND');
      expect(field.slotDurationMinutes, 60);
      expect(field.timezone, 'Asia/Ho_Chi_Minh');
    });

    test('status parse đúng tất cả giá trị', () {
      expect(_makeField(status: FieldStatus.active).status, FieldStatus.active);
      expect(_makeField(status: FieldStatus.draft).status, FieldStatus.draft);
      expect(_makeField(status: FieldStatus.inactive).status, FieldStatus.inactive);
      expect(_makeField(status: FieldStatus.maintenance).status, FieldStatus.maintenance);
      expect(_makeField(status: FieldStatus.archived).status, FieldStatus.archived);
    });

    test('status không hợp lệ fallback về draft', () {
      final field = _makeField(overrides: {'status': 'badstatus'});
      expect(field.status, FieldStatus.draft);
    });

    test('amenities và imageUrls là immutable', () {
      final field = _makeField();
      expect(() => (field.amenities as dynamic).add('pool'), throwsUnsupportedError);
      expect(() => (field.imageUrls as dynamic).add('url'), throwsUnsupportedError);
    });

    test('amenities parse đúng', () {
      final field = _makeField();
      expect(field.amenities, containsAll(['wifi', 'parking']));
    });

    test('amenities rỗng khi không có', () {
      final field = _makeField(overrides: {'amenities': <String>[]});
      expect(field.amenities, isEmpty);
    });

    test('imageUrls parse từ JSON list', () {
      final field = _makeField(overrides: {
        'imageUrls': ['https://example.com/img1.jpg', 'https://example.com/img2.jpg'],
      });
      expect(field.imageUrls, hasLength(2));
    });

    test('basePrice không âm', () {
      expect(_makeField().basePrice, greaterThanOrEqualTo(0));
    });

    test('toJson → fromJson round-trip', () {
      final original = _makeField(
        status: FieldStatus.active,
        overrides: {
          'description': 'Mô tả đã thay đổi',
          'amenities': ['wifi', 'shower', 'locker'],
        },
      );
      final json = original.toJson();
      final restored = FootballField.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.status, original.status);
      expect(restored.description, original.description);
      expect(restored.amenities, containsAll(['wifi', 'shower', 'locker']));
    });

    test('field chỉ có thể đặt khi status active', () {
      // Đây là business rule: chỉ field active mới booking được
      expect(_makeField(status: FieldStatus.active).status == FieldStatus.active, isTrue);
      expect(_makeField(status: FieldStatus.draft).status == FieldStatus.active, isFalse);
      expect(_makeField(status: FieldStatus.inactive).status == FieldStatus.active, isFalse);
      expect(_makeField(status: FieldStatus.maintenance).status == FieldStatus.active, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Booking business logic validation tests
  // ─────────────────────────────────────────────────────────────────────────────

  group('Booking — business logic validation', () {
    test('totalAmount = subtotalAmount khi không có discount', () {
      final booking = _makeBooking(overrides: {
        'subtotalAmount': 600000,
        'discountAmount': 0,
        'totalAmount': 600000,
      });
      expect(booking.totalAmount, booking.subtotalAmount - booking.discountAmount);
    });

    test('totalAmount có discount', () {
      final booking = _makeBooking(overrides: {
        'subtotalAmount': 600000,
        'discountAmount': 60000,
        'totalAmount': 540000,
      });
      expect(booking.totalAmount, 540000);
      expect(booking.discountAmount, 60000);
    });

    test('nhiều slotIds được parse đúng', () {
      final booking = _makeBooking(overrides: {
        'slotIds': ['slot_001', 'slot_002', 'slot_003'],
        'totalAmount': 900000,
        'subtotalAmount': 900000,
      });
      expect(booking.slotIds, hasLength(3));
      expect(booking.slotIds, containsAllInOrder(['slot_001', 'slot_002', 'slot_003']));
    });

    test('startsAt trước endsAt', () {
      final booking = _makeBooking();
      expect(booking.startsAt.isBefore(booking.endsAt), isTrue);
    });

    test('bookerId != ownerId (người đặt khác chủ sân)', () {
      final booking = _makeBooking();
      expect(booking.bookerId, isNot(equals(booking.ownerId)));
    });

    test('priceSnapshot không âm', () {
      final booking = _makeBooking();
      expect(booking.priceSnapshot, greaterThanOrEqualTo(0));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // BookingStatus enum tests
  // ─────────────────────────────────────────────────────────────────────────────

  group('BookingStatus', () {
    test('có đủ 6 trạng thái', () {
      expect(BookingStatus.values, hasLength(6));
    });

    test('giá trị name đúng convention', () {
      expect(BookingStatus.pending.name, 'pending');
      expect(BookingStatus.confirmed.name, 'confirmed');
      expect(BookingStatus.rejected.name, 'rejected');
      expect(BookingStatus.cancelledByUser.name, 'cancelledByUser');
      expect(BookingStatus.cancelledByOwner.name, 'cancelledByOwner');
      expect(BookingStatus.completed.name, 'completed');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // FieldSlotStatus enum tests
  // ─────────────────────────────────────────────────────────────────────────────

  group('FieldSlotStatus', () {
    test('có đủ 4 trạng thái lưu trữ', () {
      expect(FieldSlotStatus.values, hasLength(4));
    });

    test('giá trị name đúng convention', () {
      expect(FieldSlotStatus.available.name, 'available');
      expect(FieldSlotStatus.held.name, 'held');
      expect(FieldSlotStatus.booked.name, 'booked');
      expect(FieldSlotStatus.blocked.name, 'blocked');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // FieldStatus enum tests
  // ─────────────────────────────────────────────────────────────────────────────

  group('FieldStatus', () {
    test('có đủ 5 trạng thái', () {
      expect(FieldStatus.values, hasLength(5));
    });

    test('giá trị name đúng convention', () {
      expect(FieldStatus.draft.name, 'draft');
      expect(FieldStatus.active.name, 'active');
      expect(FieldStatus.inactive.name, 'inactive');
      expect(FieldStatus.maintenance.name, 'maintenance');
      expect(FieldStatus.archived.name, 'archived');
    });
  });
}

import 'package:ballhub/features/booking/domain/models/booking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Booking', () {
    test('round-trips price snapshots and booking slot IDs', () {
      final booking = Booking.fromJson({
        'id': 'booking_1',
        'fieldId': 'field_1',
        'ownerId': 'owner_1',
        'bookerId': 'user_1',
        'dateKey': '2026-11-10',
        'startsAt': '2026-11-10T11:00:00.000Z',
        'endsAt': '2026-11-10T13:00:00.000Z',
        'slotIds': ['slot_18', 'slot_19'],
        'fieldNameSnapshot': 'Sân 5A',
        'fieldAddressSnapshot': 'Quận 1, TP. Hồ Chí Minh',
        'priceSnapshot': 700000,
        'currency': 'VND',
        'bookerNameSnapshot': 'Nguyễn An',
        'bookerPhoneSnapshot': '0900000000',
        'status': 'pending',
        'statusReason': 'Awaiting field owner confirmation',
        'subtotalAmount': 700000,
        'discountAmount': 0,
        'totalAmount': 700000,
        'createdAt': '2026-11-01T11:00:00.000Z',
        'updatedAt': '2026-11-01T11:00:00.000Z',
      });

      final json = booking.toJson();

      expect(booking.status, BookingStatus.pending);
      expect(booking.statusReason, 'Awaiting field owner confirmation');
      expect(booking.slotIds, ['slot_18', 'slot_19']);
      expect(json['priceSnapshot'], 700000);
      expect(json['statusReason'], 'Awaiting field owner confirmation');
      expect(json['totalAmount'], 700000);
    });
  });
}

import 'package:ballhub/features/booking/domain/models/field_slot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FieldSlot', () {
    test('maps nullable hold information and falls back to available status', () {
      final slot = FieldSlot.fromJson({
        'id': '2026-11-10_18-00',
        'fieldId': 'field_1',
        'dateKey': '2026-11-10',
        'startsAt': '2026-11-10T11:00:00.000Z',
        'endsAt': '2026-11-10T12:00:00.000Z',
        'durationMinutes': 60,
        'basePrice': 350000,
        'currency': 'VND',
        'status': 'not-a-status',
      });

      expect(slot.status, FieldSlotStatus.available);
      expect(slot.bookingId, isNull);
      expect(slot.holdExpiresAt, isNull);
      expect(slot.toJson()['dateKey'], '2026-11-10');
    });
  });
}

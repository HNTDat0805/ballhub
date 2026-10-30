import 'package:ballhub/features/booking/domain/models/football_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FootballField', () {
    test('maps JSON and falls back safely for an unknown field status', () {
      final field = FootballField.fromJson({
        'id': 'field_1',
        'ownerId': 'owner_1',
        'name': 'Sân 5A',
        'status': 'unexpected-status',
        'basePrice': 350000,
        'openingHours': {
          'monday': ['06:00-22:00'],
        },
      });

      expect(field.id, 'field_1');
      expect(field.status, FieldStatus.draft);
      expect(field.openingHours['monday'], ['06:00-22:00']);
      expect(field.toJson()['basePrice'], 350000);
      expect(field.timezone, 'Asia/Ho_Chi_Minh');
    });
  });
}

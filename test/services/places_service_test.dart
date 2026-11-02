import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ballhub/core/api/api_client.dart';
import 'package:ballhub/models/place_location.dart';
import 'package:ballhub/services/places_service.dart';

void main() {
  group('PlaceLocation Model Tests', () {
    test('1. PlaceLocation.fromSimpleAddress creates a clean model', () {
      final loc = PlaceLocation.fromSimpleAddress(
        'Quận Bình Thạnh, TP. Hồ Chí Minh',
      );
      expect(loc.name, 'Quận Bình Thạnh');
      expect(loc.formattedAddress, 'Quận Bình Thạnh, TP. Hồ Chí Minh');
      expect(loc.placeId, '');
      expect(loc.latitude, isNull);
    });

    test('2. PlaceLocation.fromGooglePlaceDetails extracts coordinates and administrative components', () {
      final googleDetails = {
        'place_id': 'ChIJ_abc123',
        'name': 'Sân bóng đá Chảo Lửa',
        'formatted_address':
            '30 Phan Thúc Duyện, Phường 4, Tân Bình, TP. Hồ Chí Minh, Việt Nam',
        'geometry': {
          'location': {'lat': 10.8014, 'lng': 106.6526},
        },
        'address_components': [
          {
            'long_name': '30',
            'types': ['street_number'],
          },
          {
            'long_name': 'Phan Thúc Duyện',
            'types': ['route'],
          },
          {
            'long_name': 'Phường 4',
            'types': ['sublocality_level_1', 'sublocality'],
          },
          {
            'long_name': 'Quận Tân Bình',
            'types': ['administrative_area_level_2', 'political'],
          },
          {
            'long_name': 'Thành phố Hồ Chí Minh',
            'types': ['administrative_area_level_1', 'political'],
          },
          {
            'long_name': 'Việt Nam',
            'types': ['country', 'political'],
          },
        ],
      };

      final loc = PlaceLocation.fromGooglePlaceDetails(googleDetails);

      expect(loc.placeId, 'ChIJ_abc123');
      expect(loc.name, 'Sân bóng đá Chảo Lửa');
      expect(loc.latitude, 10.8014);
      expect(loc.longitude, 106.6526);
      expect(loc.province, 'Thành phố Hồ Chí Minh');
      expect(loc.district, 'Quận Tân Bình');
      expect(loc.ward, 'Phường 4');
    });

    test(
      '3. PlaceLocation roundtrip toMap and fromMap preserves all fields',
      () {
        const loc = PlaceLocation(
          placeId: 'p123',
          name: 'Sân Mỹ Đình',
          formattedAddress: 'Lê Đức Thọ, Mỹ Đình, Nam Từ Liêm, Hà Nội',
          latitude: 21.0167,
          longitude: 105.7644,
          province: 'Hà Nội',
          district: 'Nam Từ Liêm',
          ward: 'Mỹ Đình 1',
        );

        final map = loc.toMap();
        final revived = PlaceLocation.fromMap(map);

        expect(revived.placeId, loc.placeId);
        expect(revived.name, loc.name);
        expect(revived.formattedAddress, loc.formattedAddress);
        expect(revived.latitude, loc.latitude);
        expect(revived.longitude, loc.longitude);
        expect(revived.province, loc.province);
        expect(revived.district, loc.district);
        expect(revived.ward, loc.ward);
      },
    );
  });

  group('PlacesService Autocomplete & Session Token Tests', () {
    test('4. generateSessionToken returns a valid UUID v4 format', () {
      final token1 = PlacesService.generateSessionToken();
      final token2 = PlacesService.generateSessionToken();

      expect(token1, isNotEmpty);
      expect(token2, isNotEmpty);
      expect(token1, isNot(token2));

      // Regex kiểm tra định dạng UUID v4: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(uuidRegex.hasMatch(token1), isTrue);
      expect(uuidRegex.hasMatch(token2), isTrue);
    });

    test(
      '5. getAutocompletePredictions returns empty list when query is empty',
      () async {
        final predictions = await PlacesService.getAutocompletePredictions('');
        expect(predictions, isEmpty);
      },
    );

    test('6. getAutocompletePredictions falls back to local hubs and provinces when offline', () async {
      // Mock ApiClient ném lỗi kết nối mạng
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Offline"}', 503);
      });
      PlacesService.apiClient = ApiClient(client: mockClient);
      PlacesService.httpClient = mockClient;

      // Tìm kiếm tiếng Việt không dấu 'thu duc'
      final results = await PlacesService.getAutocompletePredictions('thu duc');

      expect(results, isNotEmpty);
      expect(
        results.any(
          (r) =>
              r.mainText.contains('Thủ Đức') ||
              r.description.contains('Thủ Đức'),
        ),
        isTrue,
      );
    });

    test('7. getPlaceDetails resolves local hub details smoothly', () async {
      final details = await PlacesService.getPlaceDetails('hub_thuduc');

      expect(details, isNotNull);
      expect(details!.name, 'TP. Thủ Đức');
      expect(details.formattedAddress.contains('TP. Hồ Chí Minh'), isTrue);
    });
  });
}

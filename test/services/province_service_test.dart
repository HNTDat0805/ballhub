import 'package:ballhub/services/province_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProvinceService Tests', () {
    test('getProvinces should return 63 provinces from fallback or API', () async {
      final list = await ProvinceService.getProvinces();
      expect(list.isNotEmpty, isTrue);
      expect(list.length, greaterThanOrEqualTo(63));

      final hcm = list.firstWhere((p) => p.displayName == 'TP. Hồ Chí Minh');
      expect(hcm.code, 79);

      final hn = list.firstWhere((p) => p.displayName == 'Hà Nội');
      expect(hn.code, 1);
    });

    test('searchProvinces should filter with accent and unaccented keywords', () async {
      final list = await ProvinceService.getProvinces();

      // Tìm có dấu
      final res1 = ProvinceService.searchProvinces(list, 'Đà Nẵng');
      expect(res1.any((p) => p.displayName == 'Đà Nẵng'), isTrue);

      // Tìm không dấu
      final res2 = ProvinceService.searchProvinces(list, 'da nang');
      expect(res2.any((p) => p.displayName == 'Đà Nẵng'), isTrue);

      // Tìm viết tắt
      final res3 = ProvinceService.searchProvinces(list, 'tphcm');
      expect(res3.any((p) => p.displayName == 'TP. Hồ Chí Minh'), isTrue);

      // Tìm Hà Nội không dấu
      final res4 = ProvinceService.searchProvinces(list, 'ha noi');
      expect(res4.any((p) => p.displayName == 'Hà Nội'), isTrue);
    });

    test('Province.fromJson should format displayName cleanly', () {
      final p1 = Province.fromJson({'code': 79, 'name': 'Thành phố Hồ Chí Minh'});
      expect(p1.displayName, 'TP. Hồ Chí Minh');

      final p2 = Province.fromJson({'code': 1, 'name': 'Thành phố Hà Nội'});
      expect(p2.displayName, 'Hà Nội');

      final p3 = Province.fromJson({'code': 74, 'name': 'Tỉnh Bình Dương'});
      expect(p3.displayName, 'Bình Dương');
    });
  });
}

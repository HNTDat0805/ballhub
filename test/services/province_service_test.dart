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

    test('getDistricts returns accurate districts for TP. Hồ Chí Minh, Hà Nội, Đà Nẵng, Hải Phòng, Cần Thơ, Bình Dương', () {
      final hcm = ProvinceService.getDistricts('TP. Hồ Chí Minh');
      expect(hcm, containsAll(['Quận 1', 'Bình Thạnh', 'TP. Thủ Đức']));

      final hn = ProvinceService.getDistricts('Hà Nội');
      expect(hn, containsAll(['Cầu Giấy', 'Nam Từ Liêm', 'Ba Đình']));

      final dn = ProvinceService.getDistricts('Đà Nẵng');
      expect(dn, containsAll(['Hải Châu', 'Sơn Trà']));

      final hp = ProvinceService.getDistricts('Hải Phòng');
      expect(hp, containsAll(['Lê Chân', 'Hồng Bàng', 'Thủy Nguyên']));

      final ct = ProvinceService.getDistricts('Cần Thơ');
      expect(ct, containsAll(['Ninh Kiều', 'Cái Răng']));

      final bd = ProvinceService.getDistricts('Bình Dương');
      expect(bd, containsAll(['TP. Thủ Dầu Một', 'TP. Thuận An', 'TP. Dĩ An']));
    });

    test('getDistricts handles prefix normalization (Tỉnh, Thành phố, TP.)', () {
      final ct = ProvinceService.getDistricts('Thành phố Cần Thơ');
      expect(ct, contains('Ninh Kiều'));

      final bd = ProvinceService.getDistricts('Tỉnh Bình Dương');
      expect(bd, contains('TP. Thủ Dầu Một'));

      final dn = ProvinceService.getDistricts('TP. Đà Nẵng');
      expect(dn, contains('Hải Châu'));
    });

    test('getDistricts falls back gracefully for unknown province', () {
      final res = ProvinceService.getDistricts('Vùng Đất Không Xác Định');
      expect(res.isNotEmpty, isTrue);
      expect(res.first, contains('Trung tâm Thành phố / Thị xã'));
    });
  });
}

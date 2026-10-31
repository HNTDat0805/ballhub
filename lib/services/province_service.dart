import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thực thể Tỉnh / Thành phố tại Việt Nam
class Province {
  final int code;
  final String name;
  final String displayName;

  const Province({
    required this.code,
    required this.name,
    required this.displayName,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? '';
    final code = (json['code'] as num?)?.toInt() ?? 0;
    return Province(
      code: code,
      name: rawName,
      displayName: _formatDisplayName(rawName),
    );
  }

  static String _formatDisplayName(String raw) {
    if (raw == 'Thành phố Hồ Chí Minh') return 'TP. Hồ Chí Minh';
    if (raw == 'Thành phố Hà Nội') return 'Hà Nội';
    if (raw == 'Thành phố Đà Nẵng') return 'Đà Nẵng';
    if (raw == 'Thành phố Hải Phòng') return 'Hải Phòng';
    if (raw == 'Thành phố Cần Thơ') return 'Cần Thơ';
    if (raw.startsWith('Tỉnh ')) {
      return raw.substring(5);
    }
    if (raw.startsWith('Thành phố ')) {
      return raw.substring(10);
    }
    return raw;
  }
}

/// Dịch vụ tải và tìm kiếm danh sách Tỉnh/Thành phố thông qua Public API & Offline Fallback
class ProvinceService {
  static const String _apiUrl = 'https://provinces.open-api.vn/api/p/';
  static List<Province>? _cachedProvinces;

  /// Lấy danh sách 63 tỉnh thành phố
  static Future<List<Province>> getProvinces() async {
    if (_cachedProvinces != null && _cachedProvinces!.isNotEmpty) {
      return _cachedProvinces!;
    }

    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final list = decoded
              .whereType<Map>()
              .map((m) => Province.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          if (list.isNotEmpty) {
            _cachedProvinces = list;
            return list;
          }
        }
      }
    } catch (_) {
      // Khi offline hoặc API chậm, chuyển sang fallback 63 tỉnh thành có sẵn
    }

    _cachedProvinces = _fallbackProvinces;
    return _cachedProvinces!;
  }

  /// Tìm kiếm tỉnh thành theo từ khóa (hỗ trợ cả tiếng Việt có dấu và không dấu)
  static List<Province> searchProvinces(List<Province> list, String query) {
    final cleanQuery = _removeAccents(query.trim().toLowerCase());
    if (cleanQuery.isEmpty) return list;

    return list.where((p) {
      final nameClean = _removeAccents(p.name.toLowerCase());
      final displayClean = _removeAccents(p.displayName.toLowerCase());
      // Hỗ trợ alias viết tắt phổ biến
      if ((cleanQuery == 'tphcm' || cleanQuery == 'hcm' || cleanQuery == 'sg' || cleanQuery == 'sai gon') &&
          (displayClean.contains('ho chi minh') || p.code == 79)) {
        return true;
      }
      if ((cleanQuery == 'hn' || cleanQuery == 'ha noi') && (displayClean.contains('ha noi') || p.code == 1)) {
        return true;
      }
      return nameClean.contains(cleanQuery) || displayClean.contains(cleanQuery);
    }).toList();
  }

  /// Loại bỏ dấu tiếng Việt để tìm kiếm tiện lợi
  static String _removeAccents(String str) {
    var withAccents = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    var withoutAccents = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var result = str;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Danh sách 63 tỉnh thành Việt Nam chuẩn bị sẵn phòng trường hợp máy không có kết nối internet
  static final List<Province> _fallbackProvinces = [
    const Province(code: 79, name: 'Thành phố Hồ Chí Minh', displayName: 'TP. Hồ Chí Minh'),
    const Province(code: 1, name: 'Thành phố Hà Nội', displayName: 'Hà Nội'),
    const Province(code: 48, name: 'Thành phố Đà Nẵng', displayName: 'Đà Nẵng'),
    const Province(code: 31, name: 'Thành phố Hải Phòng', displayName: 'Hải Phòng'),
    const Province(code: 92, name: 'Thành phố Cần Thơ', displayName: 'Cần Thơ'),
    const Province(code: 74, name: 'Tỉnh Bình Dương', displayName: 'Bình Dương'),
    const Province(code: 75, name: 'Tỉnh Đồng Nai', displayName: 'Đồng Nai'),
    const Province(code: 77, name: 'Tỉnh Bà Rịa - Vũng Tàu', displayName: 'Bà Rịa - Vũng Tàu'),
    const Province(code: 56, name: 'Tỉnh Khánh Hòa', displayName: 'Khánh Hòa'),
    const Province(code: 68, name: 'Tỉnh Lâm Đồng', displayName: 'Lâm Đồng'),
    const Province(code: 80, name: 'Tỉnh Long An', displayName: 'Long An'),
    const Province(code: 82, name: 'Tỉnh Tiền Giang', displayName: 'Tiền Giang'),
    const Province(code: 91, name: 'Tỉnh Kiên Giang', displayName: 'Kiên Giang'),
    const Province(code: 89, name: 'Tỉnh An Giang', displayName: 'An Giang'),
    const Province(code: 2, name: 'Tỉnh Hà Giang', displayName: 'Hà Giang'),
    const Province(code: 4, name: 'Tỉnh Cao Bằng', displayName: 'Cao Bằng'),
    const Province(code: 6, name: 'Tỉnh Bắc Kạn', displayName: 'Bắc Kạn'),
    const Province(code: 8, name: 'Tỉnh Tuyên Quang', displayName: 'Tuyên Quang'),
    const Province(code: 10, name: 'Tỉnh Lào Cai', displayName: 'Lào Cai'),
    const Province(code: 11, name: 'Tỉnh Điện Biên', displayName: 'Điện Biên'),
    const Province(code: 12, name: 'Tỉnh Lai Châu', displayName: 'Lai Châu'),
    const Province(code: 14, name: 'Tỉnh Sơn La', displayName: 'Sơn La'),
    const Province(code: 15, name: 'Tỉnh Yên Bái', displayName: 'Yên Bái'),
    const Province(code: 17, name: 'Tỉnh Hoà Bình', displayName: 'Hoà Bình'),
    const Province(code: 19, name: 'Tỉnh Thái Nguyên', displayName: 'Thái Nguyên'),
    const Province(code: 20, name: 'Tỉnh Lạng Sơn', displayName: 'Lạng Sơn'),
    const Province(code: 22, name: 'Tỉnh Quảng Ninh', displayName: 'Quảng Ninh'),
    const Province(code: 24, name: 'Tỉnh Bắc Giang', displayName: 'Bắc Giang'),
    const Province(code: 25, name: 'Tỉnh Phú Thọ', displayName: 'Phú Thọ'),
    const Province(code: 26, name: 'Tỉnh Vĩnh Phúc', displayName: 'Vĩnh Phúc'),
    const Province(code: 27, name: 'Tỉnh Bắc Ninh', displayName: 'Bắc Ninh'),
    const Province(code: 30, name: 'Tỉnh Hải Dương', displayName: 'Hải Dương'),
    const Province(code: 33, name: 'Tỉnh Hưng Yên', displayName: 'Hưng Yên'),
    const Province(code: 34, name: 'Tỉnh Thái Bình', displayName: 'Thái Bình'),
    const Province(code: 35, name: 'Tỉnh Hà Nam', displayName: 'Hà Nam'),
    const Province(code: 36, name: 'Tỉnh Nam Định', displayName: 'Nam Định'),
    const Province(code: 37, name: 'Tỉnh Ninh Bình', displayName: 'Ninh Bình'),
    const Province(code: 38, name: 'Tỉnh Thanh Hóa', displayName: 'Thanh Hóa'),
    const Province(code: 40, name: 'Tỉnh Nghệ An', displayName: 'Nghệ An'),
    const Province(code: 42, name: 'Tỉnh Hà Tĩnh', displayName: 'Hà Tĩnh'),
    const Province(code: 44, name: 'Tỉnh Quảng Bình', displayName: 'Quảng Bình'),
    const Province(code: 45, name: 'Tỉnh Quảng Trị', displayName: 'Quảng Trị'),
    const Province(code: 46, name: 'Tỉnh Thừa Thiên Huế', displayName: 'Thừa Thiên Huế'),
    const Province(code: 49, name: 'Tỉnh Quảng Nam', displayName: 'Quảng Nam'),
    const Province(code: 51, name: 'Tỉnh Quảng Ngãi', displayName: 'Quảng Ngãi'),
    const Province(code: 52, name: 'Tỉnh Bình Định', displayName: 'Bình Định'),
    const Province(code: 54, name: 'Tỉnh Phú Yên', displayName: 'Phú Yên'),
    const Province(code: 58, name: 'Tỉnh Ninh Thuận', displayName: 'Ninh Thuận'),
    const Province(code: 60, name: 'Tỉnh Bình Thuận', displayName: 'Bình Thuận'),
    const Province(code: 62, name: 'Tỉnh Kon Tum', displayName: 'Kon Tum'),
    const Province(code: 64, name: 'Tỉnh Gia Lai', displayName: 'Gia Lai'),
    const Province(code: 66, name: 'Tỉnh Đắk Lắk', displayName: 'Đắk Lắk'),
    const Province(code: 67, name: 'Tỉnh Đắk Nông', displayName: 'Đắk Nông'),
    const Province(code: 70, name: 'Tỉnh Bình Phước', displayName: 'Bình Phước'),
    const Province(code: 72, name: 'Tỉnh Tây Ninh', displayName: 'Tây Ninh'),
    const Province(code: 83, name: 'Tỉnh Bến Tre', displayName: 'Bến Tre'),
    const Province(code: 84, name: 'Tỉnh Trà Vinh', displayName: 'Trà Vinh'),
    const Province(code: 86, name: 'Tỉnh Vĩnh Long', displayName: 'Vĩnh Long'),
    const Province(code: 87, name: 'Tỉnh Đồng Tháp', displayName: 'Đồng Tháp'),
    const Province(code: 93, name: 'Tỉnh Hậu Giang', displayName: 'Hậu Giang'),
    const Province(code: 94, name: 'Tỉnh Sóc Trăng', displayName: 'Sóc Trăng'),
    const Province(code: 95, name: 'Tỉnh Bạc Liêu', displayName: 'Bạc Liêu'),
    const Province(code: 96, name: 'Tỉnh Cà Mau', displayName: 'Cà Mau'),
  ];
}

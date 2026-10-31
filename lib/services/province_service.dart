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

  /// Lấy danh sách các Quận / Huyện / Khu vực tương ứng theo từng Tỉnh/Thành phố
  static List<String> getDistricts(String provinceName) {
    final clean = _normalizeProvinceName(provinceName);
    if (clean.isEmpty) return _defaultDistricts;

    // 1. Khớp chính xác hoặc khớp tên chuẩn
    for (final entry in _provinceDistricts.entries) {
      if (entry.key.toLowerCase() == clean.toLowerCase()) {
        return entry.value;
      }
    }

    // 2. Khớp không phân biệt dấu và hỗ trợ từ khóa con
    final noAccentClean = _removeAccents(clean.toLowerCase());
    for (final entry in _provinceDistricts.entries) {
      final keyNoAccent = _removeAccents(entry.key.toLowerCase());
      if (keyNoAccent == noAccentClean ||
          keyNoAccent.contains(noAccentClean) ||
          noAccentClean.contains(keyNoAccent)) {
        return entry.value;
      }
    }

    // 3. Fallback mặc định an toàn
    return _defaultDistricts;
  }

  static String _normalizeProvinceName(String raw) {
    var s = raw.trim();
    if (s.startsWith('Thành phố ')) s = s.substring(10);
    if (s.startsWith('TP. ')) s = s.substring(4);
    if (s.startsWith('TP ')) s = s.substring(3);
    if (s.startsWith('Tỉnh ')) s = s.substring(5);
    return s.trim();
  }

  static const List<String> _defaultDistricts = [
    'Trung tâm Thành phố / Thị xã',
    'Khu vực phía Bắc',
    'Khu vực phía Nam',
    'Khu vực phía Đông',
    'Khu vực phía Tây',
  ];

  /// Bản đồ phân cấp Quận / Huyện cho 63 Tỉnh Thành Việt Nam
  static final Map<String, List<String>> _provinceDistricts = {
    'Hồ Chí Minh': [
      'Quận 1', 'Quận 3', 'Quận 4', 'Quận 5', 'Quận 6', 'Quận 7', 'Quận 8',
      'Quận 10', 'Quận 11', 'Quận 12', 'Bình Thạnh', 'Gò Vấp', 'Phú Nhuận',
      'Tân Bình', 'Tân Phú', 'Bình Tân', 'TP. Thủ Đức', 'Hóc Môn', 'Củ Chi',
      'Bình Chánh', 'Nhà Bè', 'Cần Giờ'
    ],
    'Hà Nội': [
      'Cầu Giấy', 'Nam Từ Liêm', 'Bắc Từ Liêm', 'Ba Đình', 'Đống Đa', 'Thanh Xuân',
      'Hoàn Kiếm', 'Hai Bà Trưng', 'Tây Hồ', 'Hoàng Mai', 'Long Biên', 'Hà Đông',
      'Sơn Tây', 'Gia Lâm', 'Đông Anh', 'Hoài Đức', 'Thanh Trì', 'Sóc Sơn', 'Mê Linh',
      'Chương Mỹ', 'Thạch Thất', 'Quốc Oai'
    ],
    'Đà Nẵng': [
      'Hải Châu', 'Thanh Khê', 'Sơn Trà', 'Ngũ Hành Sơn', 'Liên Chiểu', 'Cẩm Lệ', 'Hòa Vang'
    ],
    'Hải Phòng': [
      'Hồng Bàng', 'Ngô Quyền', 'Lê Chân', 'Hải An', 'Kiến An', 'Đồ Sơn', 'Dương Kinh',
      'Thủy Nguyên', 'An Dương', 'An Lão', 'Kiến Thụy', 'Tiên Lãng', 'Vĩnh Bảo', 'Cát Hải'
    ],
    'Cần Thơ': [
      'Ninh Kiều', 'Bình Thủy', 'Cái Răng', 'Ô Môn', 'Thốt Nốt', 'Phong Điền', 'Cờ Đỏ', 'Thới Lai', 'Vĩnh Thạnh'
    ],
    'Bình Dương': [
      'TP. Thủ Dầu Một', 'TP. Thuận An', 'TP. Dĩ An', 'TP. Tân Uyên', 'TP. Bến Cát',
      'Bàu Bàng', 'Bắc Tân Uyên', 'Dầu Tiếng', 'Phú Giáo'
    ],
    'Đồng Nai': [
      'TP. Biên Hòa', 'TP. Long Khánh', 'Long Thành', 'Nhơn Trạch', 'Trảng Bom',
      'Vĩnh Cửu', 'Thống Nhất', 'Cẩm Mỹ', 'Xuân Lộc', 'Định Quán', 'Tân Phú'
    ],
    'Bà Rịa - Vũng Tàu': [
      'TP. Vũng Tàu', 'TP. Bà Rịa', 'TX. Phú Mỹ', 'Châu Đức', 'Long Điền', 'Đất Đỏ', 'Xuyên Mộc', 'Côn Đảo'
    ],
    'Khánh Hòa': [
      'TP. Nha Trang', 'TP. Cam Ranh', 'TX. Ninh Hòa', 'Cam Lâm', 'Diên Khánh', 'Vạn Ninh', 'Khánh Vĩnh', 'Khánh Sơn'
    ],
    'Lâm Đồng': [
      'TP. Đà Lạt', 'TP. Bảo Lộc', 'Đức Trọng', 'Di Linh', 'Đơn Dương', 'Lạc Dương', 'Lâm Hà', 'Bảo Lâm'
    ],
    'Quảng Ninh': [
      'TP. Hạ Long', 'TP. Cẩm Phả', 'TP. Uông Bí', 'TP. Móng Cái', 'TX. Quảng Yên', 'TX. Đông Triều', 'Vân Đồn', 'Tiên Yên'
    ],
    'Nghệ An': [
      'TP. Vinh', 'TX. Cửa Lò', 'TX. Thái Hòa', 'TX. Hoàng Mai', 'Diễn Châu', 'Quỳnh Lưu', 'Nghi Lộc', 'Yên Thành', 'Nam Đàn', 'Đô Lương'
    ],
    'Thanh Hóa': [
      'TP. Thanh Hóa', 'TP. Sầm Sơn', 'TX. Bỉm Sơn', 'TX. Nghi Sơn', 'Hoằng Hóa', 'Quảng Xương', 'Đông Sơn', 'Thọ Xuân', 'Triệu Sơn'
    ],
    'Thừa Thiên Huế': [
      'TP. Huế', 'TX. Hương Thủy', 'TX. Hương Trà', 'Phú Vang', 'Quảng Điền', 'Phong Điền', 'Phú Lộc'
    ],
    'Quảng Nam': [
      'TP. Tam Kỳ', 'TP. Hội An', 'TX. Điện Bàn', 'Núi Thành', 'Duy Xuyên', 'Thăng Bình', 'Đại Lộc'
    ],
    'Bình Định': [
      'TP. Quy Nhơn', 'TX. An Nhơn', 'TX. Hoài Nhơn', 'Tuy Phước', 'Phù Cát', 'Phù Mỹ'
    ],
    'Đắk Lắk': [
      'TP. Buôn Ma Thuột', 'TX. Buôn Hồ', 'Krông Pắc', 'Cư M\'gar', 'Ea Kar', 'Krông Ana'
    ],
    'Gia Lai': [
      'TP. Pleiku', 'TX. An Khê', 'TX. Ayun Pa', 'Chư Sê', 'Đak Đoa', 'Ia Grai'
    ],
    'Bắc Ninh': [
      'TP. Bắc Ninh', 'TP. Từ Sơn', 'TX. Quế Võ', 'TX. Thuận Thành', 'Yên Phong', 'Tiên Du'
    ],
    'Hải Dương': [
      'TP. Hải Dương', 'TP. Chí Linh', 'TX. Kinh Môn', 'Cẩm Giàng', 'Nam Sách', 'Kim Thành'
    ],
    'Vĩnh Phúc': [
      'TP. Vĩnh Yên', 'TP. Phúc Yên', 'Bình Xuyên', 'Vĩnh Tường', 'Yên Lạc'
    ],
    'Thái Nguyên': [
      'TP. Thái Nguyên', 'TP. Sông Công', 'TP. Phổ Yên', 'Đại Từ', 'Phú Lương'
    ],
    'Nam Định': [
      'TP. Nam Định', 'Giao Thủy', 'Hải Hậu', 'Nghĩa Hưng', 'Ý Yên'
    ],
    'Thái Bình': [
      'TP. Thái Bình', 'Đông Hưng', 'Hưng Hà', 'Kiến Xương', 'Quỳnh Phụ', 'Thái Thụy'
    ],
    'Ninh Bình': [
      'TP. Ninh Bình', 'TP. Tam Điệp', 'Hoa Lư', 'Gia Viễn', 'Nho Quan'
    ],
    'Kiên Giang': [
      'TP. Rạch Giá', 'TP. Phú Quốc', 'TP. Hà Tiên', 'Kiên Lương', 'Hòn Đất', 'Châu Thành'
    ],
    'An Giang': [
      'TP. Long Xuyên', 'TP. Châu Đốc', 'TX. Tân Châu', 'TX. Tịnh Biên', 'Chợ Mới', 'Phú Tân'
    ],
    'Tiền Giang': [
      'TP. Mỹ Tho', 'TX. Gò Công', 'TX. Cai Lậy', 'Châu Thành', 'Chợ Gạo', 'Cái Bè'
    ],
    'Long An': [
      'TP. Tân An', 'TX. Kiến Tường', 'Bến Lức', 'Cần Đước', 'Cần Giuộc', 'Đức Hòa'
    ],
    'Đồng Tháp': [
      'TP. Cao Lãnh', 'TP. Sa Đéc', 'TP. Hồng Ngự', 'Lấp Vò', 'Lai Vung', 'Tháp Mười'
    ],
    'Bến Tre': [
      'TP. Bến Tre', 'Châu Thành', 'Chợ Lách', 'Mỏ Cày Nam', 'Giồng Trôm', 'Ba Tri'
    ],
    'Tây Ninh': [
      'TP. Tây Ninh', 'TX. Trảng Bàng', 'TX. Hòa Thành', 'Gò Dầu', 'Bến Cầu', 'Tân Châu'
    ],
    'Bình Phước': [
      'TP. Đồng Xoài', 'TX. Chơn Thành', 'TX. Bình Long', 'TX. Phước Long', 'Hớn Quản'
    ],
    'Cà Mau': [
      'TP. Cà Mau', 'Cái Nước', 'Đầm Dơi', 'Năm Căn', 'Trần Văn Thời', 'Phú Tân'
    ],
    'Hà Nam': [
      'TP. Phủ Lý', 'TX. Duy Tiên', 'Kim Bảng', 'Thanh Liêm', 'Lý Nhân'
    ],
    'Hưng Yên': [
      'TP. Hưng Yên', 'TX. Mỹ Hào', 'Văn Giang', 'Văn Lâm', 'Yên Mỹ'
    ],
    'Bắc Giang': [
      'TP. Bắc Giang', 'TX. Việt Yên', 'Hiệp Hòa', 'Lạng Giang', 'Lục Nam'
    ],
    'Phú Thọ': [
      'TP. Việt Trì', 'TX. Phú Thọ', 'Lâm Thao', 'Phù Ninh', 'Cẩm Khê'
    ],
    'Quảng Bình': [
      'TP. Đồng Hới', 'TX. Ba Đồn', 'Bố Trạch', 'Quảng Trạch', 'Lệ Thủy'
    ],
    'Quảng Trị': [
      'TP. Đông Hà', 'TX. Quảng Trị', 'Triệu Phong', 'Hải Lăng', 'Gio Linh'
    ],
    'Hà Tĩnh': [
      'TP. Hà Tĩnh', 'TX. Hồng Lĩnh', 'TX. Kỳ Anh', 'Nghi Xuân', 'Can Lộc'
    ],
    'Quảng Ngãi': [
      'TP. Quảng Ngãi', 'TX. Đức Phổ', 'Bình Sơn', 'Sơn Tịnh', 'Tư Nghĩa'
    ],
    'Phú Yên': [
      'TP. Tuy Hòa', 'TX. Sông Cầu', 'TX. Đông Hòa', 'Tây Hòa', 'Tuy An'
    ],
    'Bình Thuận': [
      'TP. Phan Thiết', 'TX. La Gi', 'Hàm Thuận Bắc', 'Hàm Thuận Nam', 'Tuy Phong'
    ],
    'Ninh Thuận': [
      'TP. Phan Rang - Tháp Chàm', 'Ninh Hải', 'Ninh Phước', 'Ninh Sơn'
    ],
    'Kon Tum': [
      'TP. Kon Tum', 'Đăk Hà', 'Đăk Tô', 'Ngọc Hồi', 'Sa Thầy'
    ],
    'Đắk Nông': [
      'TP. Gia Nghĩa', 'Đắk R\'lấp', 'Cư Jút', 'Đắk Mil', 'Krông Nô'
    ],
    'Sóc Trăng': [
      'TP. Sóc Trăng', 'TX. Vĩnh Châu', 'TX. Ngã Năm', 'Mỹ Xuyên', 'Châu Thành'
    ],
    'Bạc Liêu': [
      'TP. Bạc Liêu', 'TX. Giá Rai', 'Hòa Bình', 'Vĩnh Lợi', 'Phước Long'
    ],
    'Trà Vinh': [
      'TP. Trà Vinh', 'TX. Duyên Hải', 'Càng Long', 'Cầu Kè', 'Tiểu Cần'
    ],
    'Vĩnh Long': [
      'TP. Vĩnh Long', 'TX. Bình Minh', 'Long Hồ', 'Mang Thít', 'Tam Bình'
    ],
    'Hậu Giang': [
      'TP. Vị Thanh', 'TP. Ngã Bảy', 'TX. Long Mỹ', 'Phụng Hiệp', 'Châu Thành'
    ],
    'Hòa Bình': [
      'TP. Hòa Bình', 'Lương Sơn', 'Cao Phong', 'Kim Bôi', 'Lạc Sơn'
    ],
    'Sơn La': [
      'TP. Sơn La', 'Mộc Châu', 'Mai Sơn', 'Thuận Châu', 'Yên Châu'
    ],
    'Điện Biên': [
      'TP. Điện Biên Phủ', 'TX. Mường Lay', 'Điện Biên', 'Tuần Giáo'
    ],
    'Lai Châu': [
      'TP. Lai Châu', 'Tam Đường', 'Phong Thổ', 'Tân Uyên', 'Than Uyên'
    ],
    'Lào Cai': [
      'TP. Lào Cai', 'TX. Sa Pa', 'Bát Xát', 'Bảo Thắng', 'Bảo Yên'
    ],
    'Yên Bái': [
      'TP. Yên Bái', 'TX. Nghĩa Lộ', 'Trấn Yên', 'Văn Chấn', 'Lục Yên'
    ],
    'Hà Giang': [
      'TP. Hà Giang', 'Đồng Văn', 'Mèo Vạc', 'Quản Bạ', 'Vị Xuyên'
    ],
    'Cao Bằng': [
      'TP. Cao Bằng', 'Trùng Khánh', 'Quảng Hòa', 'Bảo Lạc', 'Nguyên Bình'
    ],
    'Bắc Kạn': [
      'TP. Bắc Kạn', 'Ba Bể', 'Bạch Thông', 'Chợ Đồn', 'Chợ Mới'
    ],
    'Tuyên Quang': [
      'TP. Tuyên Quang', 'Sơn Dương', 'Yên Sơn', 'Hàm Yên', 'Chiêm Hóa'
    ],
    'Lạng Sơn': [
      'TP. Lạng Sơn', 'Hữu Lũng', 'Chi Lăng', 'Cao Lộc', 'Lộc Bình'
    ],
  };

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

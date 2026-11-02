/// Thể thức thi đấu của giải bóng đá
enum TournamentFormat {
  /// Vòng tròn tính điểm 1 lượt (mỗi đội gặp nhau 1 lần)
  roundRobinSingle,

  /// Vòng tròn tính điểm 2 lượt (lượt đi và lượt về sân nhà - sân khách)
  roundRobinDouble,

  /// Đấu loại trực tiếp (Knockout / Cúp loại trực tiếp)
  knockout;

  String get displayName => switch (this) {
    TournamentFormat.roundRobinSingle => 'Vòng tròn 1 lượt',
    TournamentFormat.roundRobinDouble => 'Vòng tròn 2 lượt (Lượt đi - về)',
    TournamentFormat.knockout => 'Loại trực tiếp (Knockout)',
  };
}

/// Trạng thái vòng đời của giải đấu
enum TournamentStatus {
  /// Đang chuẩn bị / nháp: BTC cấu hình thông tin giải đấu
  preparing,

  /// Đang mở cổng cho các đội bóng đăng ký tham gia
  registrationOpen,

  /// Đã chốt danh sách đội, đã tạo lịch và đang tiến hành thi đấu
  inProgress,

  /// Giải đấu đã hoàn thành tất cả các trận và xác định nhà vô địch
  completed,

  /// Giải đấu bị hủy bởi Ban tổ chức
  cancelled;

  String get displayName => switch (this) {
    TournamentStatus.preparing => 'Chuẩn bị',
    TournamentStatus.registrationOpen => 'Mở đăng ký',
    TournamentStatus.inProgress => 'Đang diễn ra',
    TournamentStatus.completed => 'Đã kết thúc',
    TournamentStatus.cancelled => 'Đã hủy',
  };
}

/// Mô hình thực thể giải đấu (Tournament Domain Model)
class Tournament {
  final String id;
  final String name;
  final String description;
  final String bannerUrl;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationDeadline;
  final int maxTeams;
  final TournamentFormat format;
  final TournamentStatus status;
  final String organizerId;
  final String organizerName;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? placeId;
  final double? latitude;
  final double? longitude;
  final String? province;
  final String? district;
  final String? ward;

  const Tournament({
    required this.id,
    required this.name,
    required this.description,
    this.bannerUrl = '',
    required this.location,
    this.placeId,
    this.latitude,
    this.longitude,
    this.province,
    this.district,
    this.ward,
    required this.startDate,
    required this.endDate,
    required this.registrationDeadline,
    required this.maxTeams,
    required this.format,
    required this.status,
    required this.organizerId,
    required this.organizerName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Kiểm tra xem đội bóng có đủ điều kiện đăng ký vào giải đấu tại thời điểm hiện tại hay không:
  /// 1. Giải phải đang ở trạng thái [TournamentStatus.registrationOpen].
  /// 2. Thời điểm hiện tại phải trước hạn chót đăng ký [registrationDeadline].
  /// 3. Số đội đã được duyệt chưa vượt quá giới hạn tối đa [maxTeams].
  bool canRegister({
    required DateTime now,
    required int currentApprovedTeamsCount,
  }) {
    if (status != TournamentStatus.registrationOpen) {
      return false; // Chỉ mở đăng ký khi giải ở trạng thái registrationOpen
    }
    if (now.isAfter(registrationDeadline)) {
      return false; // Không được đăng ký nếu đã quá hạn chót
    }
    if (currentApprovedTeamsCount >= maxTeams) {
      return false; // Không cho phép đăng ký nếu đã đủ số đội tối đa
    }
    return true; // Thỏa mãn tất cả điều kiện đăng ký
  }

  /// Kiểm tra điều kiện để Ban tổ chức có thể tạo lịch thi đấu tự động:
  /// 1. Giải đang ở giai đoạn chuẩn bị hoặc mở đăng ký.
  /// 2. Cần có tối thiểu 2 đội bóng đã được duyệt tham gia.
  bool canGenerateSchedule({required int approvedTeamsCount}) {
    if (status != TournamentStatus.registrationOpen &&
        status != TournamentStatus.preparing) {
      return false; // Chỉ cho phép tạo lịch khi giải ở trạng thái chuẩn bị hoặc đang mở đăng ký
    }
    return approvedTeamsCount >=
        2; // Cần tối thiểu 2 đội bóng để sinh lịch thi đấu
  }

  /// Tạo bản sao mới của đối tượng Tournament với các trường cần thay đổi được cập nhật
  Tournament copyWith({
    String? id,
    String? name,
    String? description,
    String? bannerUrl,
    String? location,
    String? placeId,
    double? latitude,
    double? longitude,
    String? province,
    String? district,
    String? ward,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    int? maxTeams,
    TournamentFormat? format,
    TournamentStatus? status,
    String? organizerId,
    String? organizerName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tournament(
      id: id ?? this.id, // Giữ nguyên id cũ nếu không truyền id mới
      name: name ?? this.name, // Cập nhật tên giải đấu
      description: description ?? this.description, // Cập nhật mô tả giải
      bannerUrl: bannerUrl ?? this.bannerUrl, // Cập nhật link ảnh banner
      location: location ?? this.location, // Cập nhật địa điểm thi đấu
      placeId: placeId ?? this.placeId, // Cập nhật Google Places ID
      latitude: latitude ?? this.latitude, // Cập nhật vĩ độ bản đồ
      longitude: longitude ?? this.longitude, // Cập nhật kinh độ bản đồ
      province: province ?? this.province, // Cập nhật tỉnh/thành phố
      district: district ?? this.district, // Cập nhật quận/huyện
      ward: ward ?? this.ward, // Cập nhật phường/xã
      startDate: startDate ?? this.startDate, // Cập nhật ngày bắt đầu giải
      endDate: endDate ?? this.endDate, // Cập nhật ngày bế mạc
      registrationDeadline:
          registrationDeadline ??
          this.registrationDeadline, // Cập nhật hạn chót đăng ký
      maxTeams: maxTeams ?? this.maxTeams, // Cập nhật số đội tối đa
      format: format ?? this.format, // Cập nhật thể thức thi đấu
      status: status ?? this.status, // Cập nhật trạng thái vòng đời giải
      organizerId: organizerId ?? this.organizerId, // Cập nhật ID ban tổ chức
      organizerName:
          organizerName ?? this.organizerName, // Cập nhật tên ban tổ chức
      createdAt: createdAt ?? this.createdAt, // Giữ nguyên ngày tạo
      updatedAt: updatedAt ?? this.updatedAt, // Cập nhật thời điểm sửa đổi
    );
  }

  /// Chuyển đổi đối tượng Tournament thành `Map<String, dynamic>` để lưu trữ vào Firestore hoặc gửi API
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Mã định danh duy nhất của giải đấu
      'name': name, // Tên giải đấu
      'description': description, // Mô tả quy mô, điều lệ giải
      'bannerUrl': bannerUrl, // Đường dẫn ảnh bìa giải đấu
      'location': location, // Chuỗi địa chỉ hiển thị sân thi đấu
      if (placeId != null && placeId!.isNotEmpty)
        'placeId': placeId, // ID Google Place nếu có
      if (latitude != null) 'latitude': latitude, // Tọa độ vĩ độ
      if (longitude != null) 'longitude': longitude, // Tọa độ kinh độ
      if (province != null && province!.isNotEmpty)
        'province': province, // Tỉnh/Thành phố
      if (district != null && district!.isNotEmpty)
        'district': district, // Quận/Huyện
      if (ward != null && ward!.isNotEmpty) 'ward': ward, // Phường/Xã
      'startDate': startDate
          .toIso8601String(), // Thời gian khai mạc theo chuẩn ISO 8601
      'endDate': endDate
          .toIso8601String(), // Thời gian bế mạc theo chuẩn ISO 8601
      'registrationDeadline': registrationDeadline
          .toIso8601String(), // Hạn chót đăng ký theo chuẩn ISO 8601
      'maxTeams': maxTeams, // Số lượng đội bóng tối đa tham gia
      'format': format.name, // Tên thể thức thi đấu: roundRobinSingle, roundRobinDouble, knockout
      'status': status.name, // Tên trạng thái: preparing, registrationOpen, inProgress, completed, cancelled
      'organizerId': organizerId, // UID người tạo / Ban tổ chức giải
      'organizerName': organizerName, // Tên hiển thị người tạo
      'createdAt': createdAt.toIso8601String(), // Thời gian tạo bản ghi
      'updatedAt': updatedAt
          .toIso8601String(), // Thời gian cập nhật bản ghi gần nhất
    };
  }

  /// Khởi tạo đối tượng Tournament từ Map dữ liệu (từ Firestore hoặc REST API response)
  factory Tournament.fromMap(Map<dynamic, dynamic> map, String id) {
    return Tournament(
      id: id, // Gán ID từ document ID hoặc trường id
      name:
          map['name'] as String? ??
          'Chưa đặt tên', // Tên giải mặc định nếu rỗng
      description: map['description'] as String? ?? '', // Mô tả giải đấu
      bannerUrl: map['bannerUrl'] as String? ?? '', // Ảnh banner giải đấu
      location: map['location'] as String? ?? '', // Tên địa điểm thi đấu
      placeId: map['placeId'] as String?, // Mã Google Place ID
      latitude: (map['latitude'] as num?)
          ?.toDouble(), // Parse vĩ độ kiểu số thực
      longitude: (map['longitude'] as num?)
          ?.toDouble(), // Parse kinh độ kiểu số thực
      province: map['province'] as String?, // Tên tỉnh/thành phố
      district: map['district'] as String?, // Tên quận/huyện
      ward: map['ward'] as String?, // Tên phường/xã
      startDate:
          DateTime.tryParse(map['startDate'] as String? ?? '') ?? DateTime.now(), // Parse ngày bắt đầu giải, fallback thời điểm hiện tại
      endDate:
          DateTime.tryParse(map['endDate'] as String? ?? '') ??
          DateTime.now().add(
            const Duration(days: 7),
          ), // Parse ngày kết thúc giải, mặc định 7 ngày sau
      registrationDeadline:
          DateTime.tryParse(map['registrationDeadline'] as String? ?? '') ??
          DateTime.now(), // Parse hạn chót đăng ký giải đấu
      maxTeams:
          (map['maxTeams'] as num?)?.toInt() ??
          8, // Số đội tối đa, mặc định là 8
      format: TournamentFormat.values.firstWhere(
        (f) => f.name == map['format'],
        orElse: () => TournamentFormat.roundRobinSingle, // Mặc định là vòng tròn 1 lượt nếu không tìm thấy
      ),
      status: TournamentStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TournamentStatus
            .preparing, // Mặc định là đang chuẩn bị nếu không tìm thấy
      ),
      organizerId: map['organizerId'] as String? ?? '', // UID Ban tổ chức
      organizerName:
          map['organizerName'] as String? ?? '', // Tên hiển thị Ban tổ chức
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(), // Thời điểm tạo giải đấu
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(), // Thời điểm cập nhật giải đấu gần nhất
    );
  }
}

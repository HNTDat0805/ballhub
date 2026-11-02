/// Model biểu diễn thực thể Người dùng trong hệ thống Ballhub.
/// Chứa thông tin cá nhân cơ bản: họ tên, email, số điện thoại, avatar base64, vị trí thi đấu và khu vực sinh sống.
class AppUser {
  /// Mã định danh duy nhất của người dùng (khớp với Firebase Auth UID)
  final String userId;

  /// Họ và tên đầy đủ của người dùng
  final String fullName;

  /// Địa chỉ email đăng ký tài khoản
  final String email;

  /// Số điện thoại liên lạc
  final String? phone;

  /// Ảnh đại diện định dạng chuỗi Base64 Data URI (nếu có)
  final String? avatarBase64;

  /// Vị trí thi đấu sở trường trên sân (ví dụ: Tiền đạo, Tiền vệ, Hậu vệ, Thủ môn)
  final String? position;

  /// Khu vực/Tỉnh thành hoạt động (ví dụ: TP. Hồ Chí Minh, Hà Nội)
  final String? area;

  /// Khởi tạo một đối tượng [AppUser]
  AppUser({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarBase64,
    this.position,
    this.area,
  });

  /// Khởi tạo [AppUser] từ dữ liệu Map (JSON nhận từ Backend REST API hoặc Firestore Document)
  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    userId: m['userId'] ?? '',
    fullName: m['fullName'] ?? '',
    email: m['email'] ?? '',
    phone: m['phone'],
    avatarBase64: m['avatarBase64'],
    position: m['position'],
    area: m['area'],
  );

  /// Tạo bản sao [AppUser] mới với các trường được cập nhật tùy chọn (Pattern Immutability)
  AppUser copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    String? avatarBase64,
    String? position,
    String? area,
  }) => AppUser(
    userId: userId ?? this.userId,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    avatarBase64: avatarBase64 ?? this.avatarBase64,
    position: position ?? this.position,
    area: area ?? this.area,
  );

  /// Chuyển đổi đối tượng [AppUser] thành Map để gửi lên REST API hoặc lưu trữ
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'avatarBase64': avatarBase64,
    'position': position,
    'area': area,
  };
}

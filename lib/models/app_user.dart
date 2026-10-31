class AppUser {
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarBase64;
  final String? position;
  final String? area;

  AppUser({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarBase64,
    this.position,
    this.area,
  });

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        userId: m['userId'] ?? '',
        fullName: m['fullName'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'],
        avatarBase64: m['avatarBase64'],
        position: m['position'],
        area: m['area'],
      );

  AppUser copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    String? avatarBase64,
    String? position,
    String? area,
  }) =>
      AppUser(
        userId: userId ?? this.userId,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        avatarBase64: avatarBase64 ?? this.avatarBase64,
        position: position ?? this.position,
        area: area ?? this.area,
      );

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
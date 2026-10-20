import 'package:flutter/material.dart';

/// Hệ thống thiết kế giao diện (Design System) của Ballhub.
///
/// Sử dụng bảng màu thể thao hiện đại:
/// - Xanh lá Emerald chủ đạo (sân cỏ)
/// - Xanh Navy đậm (chuyên nghiệp, sang trọng)
/// - Vàng ánh kim (cúp vô địch, điểm nhấn)
/// - Xám nhạt / Trắng (nền, thẻ hiển thị Material 3)
class AppTheme {
  /// Màu xanh lá emerald chủ đạo tượng trưng cho sân cỏ
  static const Color primaryGreen = Color(0xFF0F9D58);

  /// Màu xanh navy đậm thể thao cho AppBar và Header
  static const Color darkNavy = Color(0xFF1A237E);

  /// Màu nền bề mặt ứng dụng
  static const Color surfaceColor = Color(0xFFF8F9FA);

  /// Màu nền thẻ dữ liệu
  static const Color cardColor = Colors.white;

  /// Màu chữ chính
  static const Color textPrimary = Color(0xFF212121);

  /// Màu chữ phụ (ghi chú, metadata)
  static const Color textSecondary = Color(0xFF757575);

  /// Màu vàng ánh kim cho huy hiệu cúp và trạng thái nổi bật
  static const Color accentGold = Color(0xFFFFB300);

  /// Màu đỏ cảnh báo / nguy hiểm (xóa giải, hủy trận, thẻ đỏ)
  static const Color dangerRed = Color(0xFFD32F2F);

  /// Màu cam cảnh báo (chờ duyệt, hoãn trận)
  static const Color warningOrange = Color(0xFFF57C00);

  /// Cấu hình ThemeData Material 3 chuẩn cho toàn ứng dụng Ballhub
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: darkNavy,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: surfaceColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dangerRed),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

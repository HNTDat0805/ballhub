import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

/// Điểm khởi nhập (Entry Point) của ứng dụng Ballhub.
///
/// Khởi tạo Firebase SDK (nếu có cấu hình) và chuyển hướng vào [AuthGate]
/// để kiểm tra phiên đăng nhập của người dùng.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(const BallhubApp());
}

/// Widget gốc của ứng dụng Ballhub
class BallhubApp extends StatelessWidget {
  const BallhubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ballhub - Nền tảng bóng đá phong trào',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

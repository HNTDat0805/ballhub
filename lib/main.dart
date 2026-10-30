import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/tournament/data/api_tournament_repository.dart';
import 'features/tournament/data/tournament_repository.dart';
import 'features/tournament/presentation/controllers/tournament_controller.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

/// Điểm khởi nhập (Entry Point) của ứng dụng Ballhub.
///
/// Trình tự khởi động:
/// 1. Khởi tạo ràng buộc Flutter framework qua [WidgetsFlutterBinding.ensureInitialized].
/// 2. Khởi tạo Firebase SDK (bọc trong try-catch để phòng ngừa lỗi cấu hình nền tảng).
/// 3. Khởi tạo [ApiTournamentRepository] tuân thủ kiến trúc API-first.
/// 4. Đưa [TournamentRepository] vào [TournamentController] và khởi chạy [BallhubApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Khởi tạo Repository gọi REST API Backend
  final TournamentRepository repository = ApiTournamentRepository();
  final controller = TournamentController(repository: repository);

  runApp(BallhubApp(
    controller: controller,
    repository: repository,
    isFirebaseInitialized: isFirebaseInitialized,
  ));
}

/// Widget gốc của ứng dụng Ballhub
class BallhubApp extends StatelessWidget {
  final TournamentController controller;
  final TournamentRepository repository;
  final bool isFirebaseInitialized;

  const BallhubApp({
    super.key,
    required this.controller,
    required this.repository,
    required this.isFirebaseInitialized,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ballhub - Tournament & Football Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}


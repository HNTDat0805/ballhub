import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/booking/data/api_booking_repository.dart';
import 'features/booking/presentation/screens/booking_home_screen.dart';
import 'features/tournament/data/api_tournament_repository.dart';
import 'features/tournament/data/tournament_repository.dart';
import 'features/tournament/presentation/controllers/tournament_controller.dart';
import 'features/tournament/presentation/screens/tournament_list_screen.dart';
import 'firebase_options.dart';

/// Điểm khởi nhập (Entry Point) của ứng dụng Ballhub.
///
/// Trình tự khởi động:
/// 1. Khởi tạo ràng buộc Flutter framework qua [WidgetsFlutterBinding.ensureInitialized].
/// 2. Khởi tạo Firebase SDK (bọc trong try-catch để phòng ngừa lỗi cấu hình nền tảng).
/// 3. Khởi tạo các Repository tuân thủ kiến trúc API-first.
/// 4. Chạy [BallhubApp] với màn hình chính có bottom navigation.
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
  final TournamentRepository tournamentRepository = ApiTournamentRepository();
  final tournamentController = TournamentController(repository: tournamentRepository);
  final bookingRepository = ApiBookingRepository();

  runApp(BallhubApp(
    tournamentController: tournamentController,
    tournamentRepository: tournamentRepository,
    bookingRepository: bookingRepository,
    isFirebaseInitialized: isFirebaseInitialized,
  ));
}

/// Widget gốc của ứng dụng Ballhub
class BallhubApp extends StatefulWidget {
  final TournamentController tournamentController;
  final TournamentRepository tournamentRepository;
  final ApiBookingRepository bookingRepository;
  final bool isFirebaseInitialized;

  const BallhubApp({
    super.key,
    required this.tournamentController,
    required this.tournamentRepository,
    required this.bookingRepository,
    required this.isFirebaseInitialized,
  });

  @override
  State<BallhubApp> createState() => _BallhubAppState();
}

class _BallhubAppState extends State<BallhubApp> {
  // 0 = Booking (default), 1 = Tournament
  int _activeSection = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ballhub - Đặt sân & Giải đấu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _MainShell(
        activeSection: _activeSection,
        onSectionChanged: (index) => setState(() => _activeSection = index),
        bookingRepository: widget.bookingRepository,
        tournamentController: widget.tournamentController,
        tournamentRepository: widget.tournamentRepository,
      ),
    );
  }
}

/// Shell điều hướng cấp cao nhất — chuyển đổi giữa Booking và Tournament
class _MainShell extends StatelessWidget {
  final int activeSection;
  final ValueChanged<int> onSectionChanged;
  final ApiBookingRepository bookingRepository;
  final TournamentController tournamentController;
  final TournamentRepository tournamentRepository;

  const _MainShell({
    required this.activeSection,
    required this.onSectionChanged,
    required this.bookingRepository,
    required this.tournamentController,
    required this.tournamentRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: activeSection,
        children: [
          // Tab 0: Booking (sân bóng)
          BookingHomeScreen(repository: bookingRepository),
          // Tab 1: Tournament (giải đấu)
          TournamentListScreen(
            controller: tournamentController,
            repository: tournamentRepository,
          ),
        ],
      ),
      bottomNavigationBar: _AppBottomNav(
        currentIndex: activeSection,
        onChanged: onSectionChanged,
      ),
    );
  }
}

/// Bottom navigation bar cấp cao nhất — Booking | Tournament
class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _AppBottomNav({required this.currentIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onChanged,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: AppTheme.textSecondary,
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer_outlined),
            activeIcon: Icon(Icons.sports_soccer_rounded),
            label: 'Đặt sân',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events_rounded),
            label: 'Giải đấu',
          ),
        ],
      ),
    );
  }
}

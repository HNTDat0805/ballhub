import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/booking/data/api_booking_repository.dart';
import '../features/booking/presentation/screens/field_list_screen.dart';
import '../features/tournament/data/api_tournament_repository.dart';
import '../features/tournament/presentation/controllers/tournament_controller.dart';
import '../features/tournament/presentation/screens/tournament_list_screen.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'teams/team_list_screen.dart';

/// Shell điều hướng chính của Ballhub (MainScreen).
///
/// Quản lý 5 Tab điều hướng theo đúng cấu trúc Figma (figma.pdf):
/// 0. Khám phá (Explore / Home) - Page 4
/// 1. Giải đấu (Tournaments) - Page 5 & 6
/// 2. Đặt sân (Pitch Booking) - Page 7 & 8
/// 3. Đội bóng (Teams & Matchmaking) - Page 9 & 10
/// 4. Cá nhân (User Profile) - Page 12
class MainScreen extends StatefulWidget {
  final AppUser? demoUser;

  const MainScreen({super.key, this.demoUser});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final _tournamentRepo = ApiTournamentRepository();
  late final _tournamentController = TournamentController(repository: _tournamentRepo);
  late final _bookingRepo = ApiBookingRepository();

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUser = widget.demoUser ??
        AppUser(
          userId: AuthService.uid ?? '',
          fullName: AuthService.currentUser?.displayName?.isNotEmpty == true
              ? AuthService.currentUser!.displayName!
              : (AuthService.currentUser?.email?.split('@').first ?? 'Cầu thủ Ballhub'),
          email: AuthService.currentUser?.email ?? '',
          position: 'Cầu thủ',
          area: '',
        );

    final pages = [
      HomeScreen(
        user: effectiveUser,
        onNavigate: _navigateToTab,
        tournamentRepository: _tournamentRepo,
        bookingRepository: _bookingRepo,
      ),

      // 1. Giải đấu (Trang 5 & 6)
      TournamentListScreen(
        controller: _tournamentController,
        repository: _tournamentRepo,
      ),

      // 2. Đặt sân (Trang 7 & 8)
      FieldListScreen(repository: _bookingRepo),

      // 3. Đội bóng (Trang 9 & 10)
      const TeamListScreen(),

      // 4. Cá nhân (Trang 12)
      ProfileScreen(user: effectiveUser),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.borderColor, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _navigateToTab,
          selectedItemColor: AppTheme.primaryDarkGreen,
          unselectedItemColor: AppTheme.textMuted,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Khám phá',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Giải đấu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.stadium_outlined),
              activeIcon: Icon(Icons.stadium),
              label: 'Đặt sân',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Đội bóng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
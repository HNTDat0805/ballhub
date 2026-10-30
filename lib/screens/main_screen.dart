import 'package:flutter/material.dart';
import 'teams/team_list_screen.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import '../features/tournament/data/api_tournament_repository.dart';
import '../features/tournament/presentation/controllers/tournament_controller.dart';
import '../features/tournament/presentation/screens/tournament_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  late final Stream<AppUser?> _userStream = AuthService.currentUserStream();
  late final _tournamentRepo = ApiTournamentRepository();
  late final _tournamentController = TournamentController(repository: _tournamentRepo);

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _userStream,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  TextButton(onPressed: AuthService.logout, child: const Text('Đăng xuất')),
                ],
              ),
            ),
          );
        }

        final pages = [
          HomeScreen(user: user, onNavigate: _goTo),
          const TeamListScreen(),
          const PlaceholderScreen(title: 'Sân bóng', note: 'Phân hệ đặt sân (Hưng)'),
          TournamentListScreen(
            controller: _tournamentController,
            repository: _tournamentRepo,
          ),
          ProfileScreen(user: user),
        ];

        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _goTo,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
              NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Đội bóng'),
              NavigationDestination(icon: Icon(Icons.stadium_outlined), selectedIcon: Icon(Icons.stadium), label: 'Sân bóng'),
              NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Giải đấu'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cá nhân'),
            ],
          ),
        );
      },
    );
  }
}

// Màn hình chờ cho các tab chưa làm (Hưng, Đạt thay bằng màn hình của họ)
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String note;
  const PlaceholderScreen({super.key, required this.title, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$note\nđang phát triển...', textAlign: TextAlign.center)),
    );
  }
}
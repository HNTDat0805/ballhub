import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/team.dart';
import '../../services/team_service.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/team_card.dart';
import '../../widgets/user_avatar.dart';
import '../teams/team_form_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppUser user;
  final void Function(int) onNavigate;

  const HomeScreen({super.key, required this.user, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Team>> _myTeams;

  @override
  void initState() {
    super.initState();
    _myTeams = TeamService.getMyTeams();
    TeamService.changed.addListener(_reload);
  }

  @override
  void dispose() {
    TeamService.changed.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    setState(() {
      _myTeams = TeamService.getMyTeams();
    });
  }

  Future<void> _refresh() async {
    _reload();
    try {
      await _myTeams;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('StreetBall', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Lời chào
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  UserAvatar(avatarBase64: user.avatarBase64, name: user.fullName, radius: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Xin chào, ${user.fullName}!',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Hôm nay ra sân chưa? ⚽', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Tiện ích', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _action(Icons.search, 'Tìm đội', () => widget.onNavigate(1)),
                _action(Icons.group_add, 'Tạo đội', () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const TeamFormScreen()))),
                _action(Icons.stadium, 'Đặt sân', () => widget.onNavigate(2)),
                _action(Icons.emoji_events, 'Giải đấu', () => widget.onNavigate(3)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Đội của tôi', style: textTheme.titleMedium)),
                TextButton(onPressed: () => widget.onNavigate(1), child: const Text('Xem tất cả')),
              ],
            ),
            FutureBuilder<List<Team>>(
              future: _myTeams,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) return Text(errorText(snap.error!));
                final teams = snap.data ?? [];
                if (teams.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Bạn chưa tham gia đội nào. Hãy tạo đội hoặc tìm đội để tham gia nhé!'),
                    ),
                  );
                }
                return Column(children: teams.map((t) => TeamCard(team: t)).toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primaryContainer,
            child: Icon(icon, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
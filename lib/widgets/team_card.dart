import 'package:flutter/material.dart';
import '../models/team.dart';
import '../screens/teams/team_detail_screen.dart';
import '../services/auth_service.dart';
import '../utils/ui_helpers.dart';

class TeamCard extends StatelessWidget {
  final Team team;
  const TeamCard({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = team.teamName.isEmpty ? '?' : team.teamName[0].toUpperCase();
    return Card(
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TeamDetailScreen(teamId: team.teamId)),
        ),
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(team.teamName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${team.area} • ${team.memberCount} thành viên\nĐội trưởng: ${team.captainName}'),
        isThreeLine: true,
        trailing: team.captainId == AuthService.uid
            ? const Icon(Icons.star, color: Colors.amber)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

// Danh sách đội có loading, lỗi, kéo để làm mới
class TeamFutureList extends StatelessWidget {
  final Future<List<Team>> future;
  final Future<void> Function() onRefresh;
  final String emptyText;

  const TeamFutureList({super.key, required this.future, required this.onRefresh, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Team>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(errorText(snap.error!))));
        }
        final teams = snap.data ?? [];
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: teams.isEmpty
              ? ListView(children: [
                  Padding(padding: const EdgeInsets.all(32), child: Text(emptyText, textAlign: TextAlign.center)),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: teams.length,
                  itemBuilder: (context, i) => TeamCard(team: teams[i]),
                ),
        );
      },
    );
  }
}
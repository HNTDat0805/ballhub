import 'package:flutter/material.dart';
import '../../models/team.dart';
import '../../services/team_service.dart';
import '../../widgets/team_card.dart';
import 'team_form_screen.dart';

class TeamListScreen extends StatelessWidget {
  const TeamListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đội bóng'),
          bottom: const TabBar(tabs: [Tab(text: 'Tìm đội'), Tab(text: 'Đội của tôi')]),
        ),
        body: const TabBarView(children: [_SearchTab(), _MyTeamsTab()]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeamFormScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Tạo đội'),
        ),
      ),
    );
  }
}

// ----- Tab tìm đội -----
class _SearchTab extends StatefulWidget {
  const _SearchTab();

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _kwCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  late Future<List<Team>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeamService.search();
    TeamService.changed.addListener(_search);
  }

  @override
  void dispose() {
    TeamService.changed.removeListener(_search);
    _kwCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _future = TeamService.search(keyword: _kwCtrl.text, area: _areaCtrl.text);
    });
  }

  Future<void> _refresh() async {
    _search();
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              TextField(
                controller: _kwCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: const InputDecoration(
                    hintText: 'Tên đội...', prefixIcon: Icon(Icons.search), isDense: true),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _areaCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(
                          hintText: 'Khu vực (VD: Thủ Đức)',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _search, child: const Text('Tìm')),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TeamFutureList(future: _future, onRefresh: _refresh, emptyText: 'Không tìm thấy đội nào'),
        ),
      ],
    );
  }
}

// ----- Tab đội của tôi -----
class _MyTeamsTab extends StatefulWidget {
  const _MyTeamsTab();

  @override
  State<_MyTeamsTab> createState() => _MyTeamsTabState();
}

class _MyTeamsTabState extends State<_MyTeamsTab> {
  late Future<List<Team>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeamService.getMyTeams();
    TeamService.changed.addListener(_reload);
  }

  @override
  void dispose() {
    TeamService.changed.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = TeamService.getMyTeams();
    });
  }

  Future<void> _refresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return TeamFutureList(future: _future, onRefresh: _refresh, emptyText: 'Bạn chưa tham gia đội nào');
  }
}
import 'package:flutter/material.dart';
import '../../models/team.dart';
import '../../services/team_service.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/user_avatar.dart';

class JoinRequestsScreen extends StatefulWidget {
  final String teamId;
  const JoinRequestsScreen({super.key, required this.teamId});

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  List<JoinRequest>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await TeamService.getPendingRequests(widget.teamId);
      if (!mounted) return;
      setState(() {
        _items = list;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  Future<void> _handle(JoinRequest r, bool approve) async {
    try {
      if (approve) {
        await TeamService.approve(r);
      } else {
        await TeamService.reject(r);
      }
      if (!mounted) return;
      setState(() => _items!.remove(r));
      showMessage(context, approve ? 'Đã duyệt ${r.fullName}' : 'Đã từ chối ${r.fullName}');
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu tham gia')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_items == null) {
      if (_error != null) return Center(child: Text(_error!));
      return const Center(child: CircularProgressIndicator());
    }
    final items = _items!;
    return RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(children: const [
              Padding(
                padding: EdgeInsets.all(32),
                child: Text('Chưa có yêu cầu nào', textAlign: TextAlign.center),
              ),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final r = items[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: UserAvatar(avatarBase64: r.avatarBase64, name: r.fullName),
                          title: Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(r.position ?? 'Chưa cập nhật vị trí'),
                        ),
                        if ((r.message ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('"${r.message}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => _handle(r, false), child: const Text('Từ chối')),
                            const SizedBox(width: 8),
                            FilledButton(onPressed: () => _handle(r, true), child: const Text('Duyệt')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
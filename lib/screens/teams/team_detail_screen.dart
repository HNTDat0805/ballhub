import 'package:flutter/material.dart';
import '../../models/team.dart';
import '../../services/auth_service.dart';
import '../../services/team_service.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/user_avatar.dart';
import 'join_requests_screen.dart';
import 'team_form_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  Team? _team;
  List<TeamMember> _members = [];
  bool _isMember = false;
  bool _hasPending = false;
  String? _error;

  bool get _isCaptain => _team != null && _team!.captainId == AuthService.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final team = await TeamService.getTeam(widget.teamId);
      if (team == null) throw AppException('Đội không tồn tại');
      final members = await TeamService.getMembers(widget.teamId);
      final isMember = await TeamService.isMember(widget.teamId);
      final hasPending = isMember ? false : await TeamService.hasPendingRequest(widget.teamId);
      if (!mounted) return;
      setState(() {
        _team = team;
        _members = members;
        _isMember = isMember;
        _hasPending = hasPending;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  Future<void> _edit() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TeamFormScreen(team: _team)),
    );
    if (ok == true) _load();
  }

  Future<void> _openRequests() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JoinRequestsScreen(teamId: widget.teamId)),
    );
    _load();
  }

  Future<void> _requestJoin() async {
    final ctrl = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xin gia nhập đội'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Lời nhắn cho đội trưởng (không bắt buộc)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Gửi')),
        ],
      ),
    );
    if (message == null) return;
    try {
      await TeamService.sendJoinRequest(widget.teamId, message);
      if (mounted) showMessage(context, 'Đã gửi yêu cầu, chờ đội trưởng duyệt');
      _load();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    }
  }

  Future<void> _leave() async {
    final ok = await confirmDialog(context, 'Rời đội', 'Bạn có chắc muốn rời đội này?');
    if (!ok) return;
    try {
      await TeamService.removeMember(widget.teamId, AuthService.uid!);
      if (!mounted) return;
      showMessage(context, 'Bạn đã rời đội');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    }
  }

  Future<void> _removeMember(TeamMember m) async {
    final ok = await confirmDialog(context, 'Xóa thành viên', 'Xóa ${m.fullName} khỏi đội?');
    if (!ok) return;
    try {
      await TeamService.removeMember(widget.teamId, m.userId);
      if (mounted) showMessage(context, 'Đã xóa ${m.fullName}');
      _load();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_team?.teamName ?? 'Chi tiết đội'),
        actions: [
          if (_isCaptain) IconButton(icon: const Icon(Icons.edit), tooltip: 'Sửa đội', onPressed: _edit),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_team == null) {
      if (_error != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              const SizedBox(height: 8),
              FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final team = _team!;
    final theme = Theme.of(context);
    final initial = team.teamName.isEmpty ? '?' : team.teamName[0].toUpperCase();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thông tin đội
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(initial, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Text(team.teamName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text(team.area),
                    ],
                  ),
                  Text('Đội trưởng: ${team.captainName} • ${team.memberCount} thành viên'),
                  if ((team.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(team.description!, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildActions(),
          const SizedBox(height: 16),
          Text('Danh sách cầu thủ (${_members.length})', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          // Danh sách cầu thủ
          ..._members.map((m) => Card(
                child: ListTile(
                  leading: UserAvatar(avatarBase64: m.avatarBase64, name: m.fullName),
                  title: Text(m.fullName),
                  subtitle: Text(m.position ?? 'Chưa cập nhật vị trí'),
                  trailing: m.role == 'Captain'
                      ? const Chip(label: Text('Đội trưởng'), visualDensity: VisualDensity.compact)
                      : _isCaptain
                          ? IconButton(
                              icon: const Icon(Icons.person_remove, color: Colors.red),
                              tooltip: 'Xóa khỏi đội',
                              onPressed: () => _removeMember(m),
                            )
                          : null,
                ),
              )),
        ],
      ),
    );
  }

  // Nút thay đổi theo vai trò: đội trưởng / thành viên / người ngoài
  Widget _buildActions() {
    if (_isCaptain) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _edit,
              icon: const Icon(Icons.edit),
              label: const Text('Sửa đội'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _openRequests,
              icon: const Icon(Icons.how_to_reg),
              label: const Text('Duyệt thành viên'),
            ),
          ),
        ],
      );
    }
    if (_isMember) {
      return OutlinedButton.icon(
        onPressed: _leave,
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        icon: const Icon(Icons.logout),
        label: const Text('Rời đội'),
      );
    }
    if (_hasPending) {
      return const FilledButton(onPressed: null, child: Text('Đã gửi yêu cầu – chờ đội trưởng duyệt'));
    }
    return FilledButton.icon(
      onPressed: _requestJoin,
      icon: const Icon(Icons.group_add),
      label: const Text('Xin gia nhập đội'),
    );
  }
}
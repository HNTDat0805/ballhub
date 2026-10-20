import 'package:flutter/material.dart';
import '../../../../core/auth/auth_context.dart';
import '../../domain/models/tournament.dart';
import '../../domain/models/tournament_team.dart';

class TeamRegistrationDialog extends StatefulWidget {
  final Tournament tournament;
  final Function(TournamentTeam team) onRegister;

  const TeamRegistrationDialog({
    super.key,
    required this.tournament,
    required this.onRegister,
  });

  @override
  State<TeamRegistrationDialog> createState() => _TeamRegistrationDialogState();
}

class _TeamRegistrationDialogState extends State<TeamRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _captainNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  int _membersCount = 11;

  @override
  void initState() {
    super.initState();
    final user = AuthContext.instance.currentUser;
    _captainNameController.text = user.name;
    _emailController.text = user.email;
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _captainNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final user = AuthContext.instance.currentUser;
      final teamId = 'team_${DateTime.now().millisecondsSinceEpoch}';
      final registrationId = 'reg_${DateTime.now().millisecondsSinceEpoch}_${user.id}';

      final team = TournamentTeam(
        id: registrationId,
        tournamentId: widget.tournament.id,
        teamId: user.teamId ?? teamId,
        teamName: _teamNameController.text.trim(),
        captainId: user.id,
        captainName: _captainNameController.text.trim(),
        captainPhone: _phoneController.text.trim(),
        captainEmail: _emailController.text.trim(),
        membersCount: _membersCount,
        status: RegistrationStatus.pending,
        registeredAt: DateTime.now(),
      );

      widget.onRegister(team);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.group_add, color: Color(0xFF0F9D58)),
          const SizedBox(width: 8),
          const Text('Đăng ký đội tham gia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Giải đấu: ${widget.tournament.name}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _teamNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên đội bóng *',
                  hintText: 'Nhập tên đội (vd: FC Sông Lam)',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập tên đội bóng';
                  if (val.trim().length < 3) return 'Tên đội phải từ 3 ký tự trở lên';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _captainNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ tên đội trưởng *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập tên đội trưởng';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại liên hệ *',
                  hintText: '09xxxxxxxx',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                  if (!RegExp(r'^\d{9,11}$').hasMatch(val.trim())) {
                    return 'Số điện thoại không hợp lệ (9-11 chữ số)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email liên hệ *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập email';
                  if (!val.contains('@') || !val.contains('.')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số lượng thành viên:'),
                  DropdownButton<int>(
                    value: _membersCount,
                    items: [7, 9, 11, 14, 16, 20].map((count) {
                      return DropdownMenuItem<int>(
                        value: count,
                        child: Text('$count cầu thủ'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _membersCount = val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy bỏ'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Xác nhận đăng ký'),
        ),
      ],
    );
  }
}

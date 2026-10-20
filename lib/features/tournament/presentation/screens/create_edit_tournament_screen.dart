import 'package:flutter/material.dart';
import '../../../../core/auth/auth_context.dart';
import '../../domain/models/tournament.dart';
import '../controllers/tournament_controller.dart';

class CreateEditTournamentScreen extends StatefulWidget {
  final TournamentController controller;
  final Tournament? tournament;

  const CreateEditTournamentScreen({
    super.key,
    required this.controller,
    this.tournament,
  });

  @override
  State<CreateEditTournamentScreen> createState() => _CreateEditTournamentScreenState();
}

class _CreateEditTournamentScreenState extends State<CreateEditTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  late TournamentFormat _format;
  late TournamentStatus _status;
  late int _maxTeams;
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _registrationDeadline;

  bool get isEditing => widget.tournament != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tournament;
    final now = DateTime.now();

    if (t != null) {
      _nameController.text = t.name;
      _descController.text = t.description;
      _locationController.text = t.location;
      _format = t.format;
      _status = t.status;
      _maxTeams = t.maxTeams;
      _startDate = t.startDate;
      _endDate = t.endDate;
      _registrationDeadline = t.registrationDeadline;
    } else {
      _format = TournamentFormat.roundRobinSingle;
      _status = TournamentStatus.registrationOpen;
      _maxTeams = 8;
      _startDate = now.add(const Duration(days: 7));
      _endDate = now.add(const Duration(days: 21));
      _registrationDeadline = now.add(const Duration(days: 5));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({
    required BuildContext context,
    required DateTime initialDate,
    required Function(DateTime) onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => onSelected(picked));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày kết thúc không được trước ngày bắt đầu!')),
      );
      return;
    }

    if (_registrationDeadline.isAfter(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hạn đăng ký phải trước hoặc bằng ngày bắt đầu giải!')),
      );
      return;
    }

    final user = AuthContext.instance.currentUser;
    final now = DateTime.now();

    final tournament = Tournament(
      id: widget.tournament?.id ?? 'tour_${now.millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      location: _locationController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      registrationDeadline: _registrationDeadline,
      maxTeams: _maxTeams,
      format: _format,
      status: _status,
      organizerId: widget.tournament?.organizerId ?? user.id,
      organizerName: widget.tournament?.organizerName ?? user.name,
      createdAt: widget.tournament?.createdAt ?? now,
      updatedAt: now,
    );

    final success = isEditing
        ? await widget.controller.updateTournament(tournament)
        : await widget.controller.createTournament(tournament);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Đã cập nhật giải đấu!' : 'Đã tạo giải đấu thành công!')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.errorMessage ?? 'Có lỗi xảy ra')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa giải đấu' : 'Tạo giải đấu mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên giải đấu *',
                  hintText: 'Nhập tên giải (vd: Cup Mùa Xuân 2026)',
                  prefixIcon: Icon(Icons.emoji_events_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập tên giải đấu';
                  if (val.trim().length < 3) return 'Tên giải đấu phải từ 3 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Địa điểm tổ chức *',
                  hintText: 'Sân vận động, quận/thành phố',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập địa điểm tổ chức';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả giải đấu',
                  hintText: 'Thông tin thể thức, giải thưởng, quy định tham gia...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Format & Teams
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TournamentFormat>(
                      initialValue: _format,
                      decoration: const InputDecoration(labelText: 'Thể thức thi đấu'),
                      items: TournamentFormat.values.map((f) {
                        return DropdownMenuItem(value: f, child: Text(f.displayName, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _format = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _maxTeams,
                      decoration: const InputDecoration(labelText: 'Số đội tối đa'),
                      items: [4, 6, 8, 10, 12, 16, 24, 32].map((count) {
                        return DropdownMenuItem(value: count, child: Text('$count đội'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _maxTeams = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (isEditing) ...[
                DropdownButtonFormField<TournamentStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Trạng thái giải đấu'),
                  items: TournamentStatus.values.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s.displayName));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Dates Picker Cards
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.how_to_reg_outlined, color: Color(0xFFF57C00)),
                        title: const Text('Hạn chót đăng ký đội', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${_registrationDeadline.day}/${_registrationDeadline.month}/${_registrationDeadline.year}',
                        ),
                        trailing: const Icon(Icons.calendar_month, size: 20),
                        onTap: () => _selectDate(
                          context: context,
                          initialDate: _registrationDeadline,
                          onSelected: (d) => _registrationDeadline = d,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.event_available, color: Color(0xFF0F9D58)),
                        title: const Text('Ngày khai mạc (Bắt đầu)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                        trailing: const Icon(Icons.calendar_month, size: 20),
                        onTap: () => _selectDate(
                          context: context,
                          initialDate: _startDate,
                          onSelected: (d) => _startDate = d,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.event_busy, color: Color(0xFFD32F2F)),
                        title: const Text('Ngày bế mạc (Kết thúc)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                        trailing: const Icon(Icons.calendar_month, size: 20),
                        onTap: () => _selectDate(
                          context: context,
                          initialDate: _endDate,
                          onSelected: (d) => _endDate = d,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.controller.isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: widget.controller.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEditing ? 'Lưu cập nhật' : 'Tạo giải đấu ngay', style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/team.dart';
import '../../services/team_service.dart';
import '../../utils/ui_helpers.dart';

class TeamFormScreen extends StatefulWidget {
  final Team? team; // null = tạo mới, có = sửa
  const TeamFormScreen({super.key, this.team});

  @override
  State<TeamFormScreen> createState() => _TeamFormScreenState();
}

class _TeamFormScreenState extends State<TeamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  bool get _isEdit => widget.team != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.team?.teamName ?? '');
    _areaCtrl = TextEditingController(text: widget.team?.area ?? '');
    _descCtrl = TextEditingController(text: widget.team?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      final area = _areaCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      if (_isEdit) {
        await TeamService.updateTeam(widget.team!.teamId, name, area, desc);
      } else {
        await TeamService.createTeam(name, area, desc);
      }
      if (!mounted) return;
      showMessage(context, _isEdit ? 'Đã cập nhật đội' : 'Tạo đội thành công! Bạn là đội trưởng.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa thông tin đội' : 'Tạo đội bóng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên đội', prefixIcon: Icon(Icons.shield_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên đội' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaCtrl,
                decoration: const InputDecoration(
                    labelText: 'Khu vực (VD: Thủ Đức)', prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập khu vực' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Giới thiệu đội', alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEdit ? 'Lưu thay đổi' : 'Tạo đội'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
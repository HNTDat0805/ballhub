import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../utils/ui_helpers.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _positions = ['Thủ môn', 'Hậu vệ', 'Tiền vệ', 'Tiền đạo'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _areaCtrl;
  String? _position;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u.fullName);
    _phoneCtrl = TextEditingController(text: u.phone ?? '');
    _areaCtrl = TextEditingController(text: u.area ?? '');
    _position = _positions.contains(u.position) ? u.position : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updatedUser = await UserService.updateProfile(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        position: _position,
        area: _areaCtrl.text.trim(),
      );
      if (!mounted) return;
      showMessage(context, 'Đã lưu hồ sơ');
      Navigator.pop(context, updatedUser);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Họ tên'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaCtrl,
                decoration: const InputDecoration(labelText: 'Khu vực hay đá (VD: Quận 7, Thủ Đức)'),
              ),
              const SizedBox(height: 16),
              const Text('Vị trí sở trường'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _positions
                    .map((p) => ChoiceChip(
                          label: Text(p),
                          selected: _position == p,
                          onSelected: (s) => setState(() => _position = s ? p : null),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/booking_repository.dart';
import '../../domain/models/football_field.dart';
import '../controllers/booking_controllers.dart';

/// Form tạo/sửa sân bóng cho chủ sân
class OwnerFieldFormScreen extends StatefulWidget {
  final BookingRepository repository;
  final FootballField? existingField;
  final ValueChanged<FootballField>? onSaved;

  const OwnerFieldFormScreen({
    super.key,
    required this.repository,
    this.existingField,
    this.onSaved,
  });

  @override
  State<OwnerFieldFormScreen> createState() => _OwnerFieldFormScreenState();
}

class _OwnerFieldFormScreenState extends State<OwnerFieldFormScreen> {
  late final OwnerFieldController _controller;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _coverImageCtrl = TextEditingController();

  String _fieldType = '5 người';
  String _status = 'draft';
  int _slotDuration = 60;
  final List<String> _amenities = [];

  bool get _isEditing => widget.existingField != null;

  static const _fieldTypes = ['5 người', '7 người', '11 người'];
  static const _statuses = [
    ('draft', 'Nháp'),
    ('active', 'Đang hoạt động'),
    ('inactive', 'Tạm ngừng'),
    ('maintenance', 'Bảo trì'),
  ];
  static const _amenityOptions = [
    'wifi', 'parking', 'shower', 'lighting', 'locker', 'canteen', 'tribune'
  ];

  @override
  void initState() {
    super.initState();
    _controller = OwnerFieldController(repository: widget.repository);
    _controller.addListener(_onUpdate);
    _prefillFromExisting();
  }

  void _prefillFromExisting() {
    final field = widget.existingField;
    if (field == null) return;
    _nameCtrl.text = field.name;
    _descCtrl.text = field.description;
    _addressCtrl.text = field.address;
    _districtCtrl.text = field.district;
    _cityCtrl.text = field.city;
    _priceCtrl.text = field.basePrice.toString();
    _capacityCtrl.text = field.capacity.toString();
    _coverImageCtrl.text = field.coverImageUrl;
    _fieldType = field.fieldType;
    _status = field.status.name;
    _slotDuration = field.slotDurationMinutes;
    _amenities.addAll(field.amenities);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _districtCtrl.dispose();
    _cityCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    _coverImageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa sân' : 'Tạo sân mới'),
        actions: [
          if (_controller.isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_rounded),
              onPressed: _submit,
              tooltip: 'Lưu',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Error message
            if (_controller.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _controller.errorMessage!,
                  style: const TextStyle(color: AppTheme.dangerRed),
                ),
              ),
            _sectionTitle('Thông tin cơ bản'),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên sân *', hintText: 'Ví dụ: Sân bóng Hoàng Mai A'),
              validator: (v) => v == null || v.trim().length < 2 ? 'Tên sân tối thiểu 2 ký tự' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _coverImageCtrl,
              decoration: const InputDecoration(labelText: 'URL ảnh bìa', hintText: 'https://...'),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Địa chỉ'),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Địa chỉ *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _districtCtrl,
                    decoration: const InputDecoration(labelText: 'Quận/Huyện'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(labelText: 'Thành phố *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionTitle('Chi tiết sân'),
            // Field type dropdown
            DropdownButtonFormField<String>(
              initialValue: _fieldType,
              decoration: const InputDecoration(labelText: 'Loại sân *'),
              items: _fieldTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _fieldType = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _capacityCtrl,
                    decoration: const InputDecoration(labelText: 'Sức chứa *', suffixText: 'người'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Phải > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _slotDuration,
                    decoration: const InputDecoration(labelText: 'Thời lượng ca'),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 phút')),
                      DropdownMenuItem(value: 60, child: Text('60 phút')),
                      DropdownMenuItem(value: 90, child: Text('90 phút')),
                      DropdownMenuItem(value: 120, child: Text('120 phút')),
                    ],
                    onChanged: (v) => setState(() => _slotDuration = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(labelText: 'Giá cơ bản *', suffixText: 'VND/giờ'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Giá không hợp lệ';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Trạng thái'),
                    items: _statuses.map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2))).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionTitle('Tiện nghi'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _amenityOptions.map((a) {
                final selected = _amenities.contains(a);
                return FilterChip(
                  label: Text(a),
                  selected: selected,
                  selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  checkmarkColor: AppTheme.primaryGreen,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _amenities.add(a);
                      } else {
                        _amenities.remove(a);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _controller.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(
                  _isEditing ? 'Lưu thay đổi' : 'Tạo sân',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final data = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'coverImageUrl': _coverImageCtrl.text.trim(),
      'imageUrls': <String>[],
      'address': _addressCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'fieldType': _fieldType,
      'capacity': int.parse(_capacityCtrl.text.trim()),
      'basePrice': int.parse(_priceCtrl.text.trim()),
      'currency': 'VND',
      'slotDurationMinutes': _slotDuration,
      'status': _status,
      'amenities': _amenities,
      'openingHours': <String, List<String>>{},
      'timezone': 'Asia/Ho_Chi_Minh',
    };

    final bool success;
    if (_isEditing) {
      success = await _controller.updateField(widget.existingField!.id, data);
    } else {
      success = await _controller.createField(data);
    }

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Đã cập nhật sân thành công.' : 'Đã tạo sân mới thành công.'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      widget.onSaved?.call(_controller.fields.first);
      Navigator.pop(context);
    }
  }
}

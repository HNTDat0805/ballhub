import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/place_location.dart';
import '../../models/team.dart';
import '../../services/team_service.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/address_autocomplete_field.dart';

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
  PlaceLocation? _selectedPlaceLocation;
  bool _saving = false;

  bool get _isEdit => widget.team != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.team?.teamName ?? '');
    _areaCtrl = TextEditingController(text: widget.team?.area ?? '');
    _descCtrl = TextEditingController(text: widget.team?.description ?? '');
    if (widget.team != null) {
      final t = widget.team!;
      if (t.placeId != null || t.latitude != null || t.province != null) {
        _selectedPlaceLocation = PlaceLocation(
          placeId: t.placeId ?? '',
          name: t.area,
          formattedAddress: t.area,
          latitude: t.latitude,
          longitude: t.longitude,
          province: t.province,
          district: t.district,
          ward: t.ward,
        );
      }
    }
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit
                          ? 'Đang cập nhật đội bóng...'
                          : 'Đang tạo đội bóng...',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Đang đồng bộ dữ liệu vào hệ thống...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final name = _nameCtrl.text.trim();
      final area = _areaCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      if (_isEdit) {
        await TeamService.updateTeam(
          widget.team!.teamId,
          name,
          area,
          desc,
          placeId: _selectedPlaceLocation?.placeId ?? widget.team?.placeId,
          latitude: _selectedPlaceLocation?.latitude ?? widget.team?.latitude,
          longitude:
              _selectedPlaceLocation?.longitude ?? widget.team?.longitude,
          province: _selectedPlaceLocation?.province ?? widget.team?.province,
          district: _selectedPlaceLocation?.district ?? widget.team?.district,
          ward: _selectedPlaceLocation?.ward ?? widget.team?.ward,
        );
      } else {
        await TeamService.createTeam(
          name,
          area,
          desc,
          placeId: _selectedPlaceLocation?.placeId,
          latitude: _selectedPlaceLocation?.latitude,
          longitude: _selectedPlaceLocation?.longitude,
          province: _selectedPlaceLocation?.province,
          district: _selectedPlaceLocation?.district,
          ward: _selectedPlaceLocation?.ward,
        );
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Đóng loading dialog
      showMessage(
        context,
        _isEdit ? 'Đã cập nhật đội' : 'Tạo đội thành công! Bạn là đội trưởng.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Đóng loading dialog
        showMessage(context, errorText(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa thông tin đội' : 'Tạo đội bóng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên đội',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tên đội'
                    : null,
              ),
              const SizedBox(height: 20),

              // Mục chọn Khu vực hoạt động
              AddressAutocompleteField(
                controller: _areaCtrl,
                labelText: 'Khu vực hoạt động *',
                hintText:
                    'Nhập quận/huyện, thành phố hoặc sân bóng sinh hoạt...',
                prefixIcon: Icons.location_on_outlined,
                isRequired: true,
                onPlaceSelected: (place) {
                  setState(() {
                    _selectedPlaceLocation = place;
                    _areaCtrl.text = place.formattedAddress.isNotEmpty
                        ? place.formattedAddress
                        : place.name;
                  });
                },
                onCleared: () {
                  setState(() {
                    _selectedPlaceLocation = null;
                  });
                },
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng chọn khu vực đội bóng'
                    : null,
              ),
              const SizedBox(height: 10),

              // Gợi ý nhanh khu vực
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Gợi ý nhanh:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...[
                      'TP. Thủ Đức, TP. Hồ Chí Minh',
                      'Quận Bình Thạnh, TP. Hồ Chí Minh',
                      'Quận 7, TP. Hồ Chí Minh',
                      'Quận Cầu Giấy, Hà Nội',
                      'Quận Nam Từ Liêm, Hà Nội',
                      'Quận Hải Châu, Đà Nẵng',
                    ].map((loc) {
                      final shortName = loc.split(',').first.trim();
                      final isSelected = _areaCtrl.text.contains(shortName);
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(
                            shortName,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          backgroundColor: isSelected
                              ? AppTheme.primaryDarkGreen
                              : Colors.grey.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onPressed: () {
                            setState(() {
                              _areaCtrl.text = loc;
                              _selectedPlaceLocation =
                                  PlaceLocation.fromSimpleAddress(loc);
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Giới thiệu đội',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.primaryDarkGreen,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEdit ? 'Lưu thay đổi' : 'Tạo đội'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/user_avatar.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;

  Future<void> _changeAvatar() async {
    // Nén ảnh nhỏ lại để lưu vào Firestore
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 60,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      await UserService.updateAvatar(bytes);
      if (mounted) showMessage(context, 'Đã cập nhật ảnh đại diện');
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(context, 'Đăng xuất', 'Bạn có chắc muốn đăng xuất?');
    if (ok) await AuthService.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ảnh đại diện + nút đổi ảnh
          Center(
            child: Stack(
              children: [
                UserAvatar(avatarBase64: user.avatarBase64, name: user.fullName, radius: 50),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: cs.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _uploading ? null : _changeAvatar,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(user.fullName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(user.email, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _info(Icons.phone, 'Số điện thoại', user.phone),
                _info(Icons.sports_soccer, 'Vị trí sở trường', user.position),
                _info(Icons.location_on, 'Khu vực', user.area),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Chỉnh sửa hồ sơ'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String? value) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text((value == null || value.isEmpty) ? 'Chưa cập nhật' : value),
      );
}
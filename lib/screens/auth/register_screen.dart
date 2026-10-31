import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_helpers.dart';
import '../auth_gate.dart';

/// Màn hình Tạo tài khoản (Page 2 - figma.pdf)
///
/// Bố cục:
/// - Header: `← Tạo tài khoản`
/// - Tiêu đề: "Gia nhập sân chơi\ncủa bạn."
/// - Mô tả: "Tìm đội, đặt sân và sẵn sàng cho trận tiếp theo."
/// - Input:
///   - Họ và tên
///   - Số điện thoại
///   - Mật khẩu (ít nhất 8 ký tự)
///   - Xác nhận mật khẩu
/// - Checkbox: "Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật của Ballhub."
/// - Nút: `→ Tạo tài khoản`
/// - Chân trang: "Đã có tài khoản? Đăng nhập"
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      showMessage(context, 'Vui lòng đồng ý với Điều khoản sử dụng của Ballhub');
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      showMessage(context, 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim();

      await AuthService.register(
        fullName: _nameCtrl.text.trim(),
        email: email,
        password: _passCtrl.text,
      );
      if (mounted) {
        showMessage(context, 'Tạo tài khoản thành công! Đang chuyển hướng...');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tạo tài khoản'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Gia nhập sân chơi\ncủa bạn.',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tìm đội, đặt sân và sẵn sàng cho trận tiếp theo.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Họ và tên
                const Text(
                  'Họ và tên',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(hintText: 'Nhập họ và tên của bạn'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                ),
                const SizedBox(height: 18),

                // Email
                const Text(
                  'Email',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Nhập địa chỉ email (ví dụ: ban@example.com)',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Vui lòng nhập địa chỉ email';
                    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(val)) {
                      return 'Địa chỉ email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Mật khẩu
                const Text(
                  'Mật khẩu',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    hintText: 'Ít nhất 8 ký tự',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) => (v != null && v.length < 6) ? 'Mật khẩu cần ít nhất 6-8 ký tự' : null,
                ),
                const SizedBox(height: 18),

                // Xác nhận mật khẩu
                const Text(
                  'Xác nhận mật khẩu',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: 'Nhập lại mật khẩu',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng xác nhận mật khẩu' : null,
                ),
                const SizedBox(height: 20),

                // Checkbox Điều khoản
                InkWell(
                  onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreeTerms,
                          activeColor: AppTheme.primaryDarkGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật của Ballhub.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Nút Tạo tài khoản
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_forward, size: 18),
                            SizedBox(width: 8),
                            Text('Tạo tài khoản'),
                          ],
                        ),
                ),
                const SizedBox(height: 24),

                // Đã có tài khoản? Đăng nhập
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          color: AppTheme.primaryDarkGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_helpers.dart';
import '../auth_gate.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Màn hình Đăng nhập (Page 1 - figma.pdf)
///
/// Bố cục:
/// - Hero Header: Nền cầu thủ sân cỏ đêm, Logo tròn + chữ "ballhub", khẩu hiệu
///   "Chung đam mê. Cùng ra sân." và "Kết nối bóng đá phong trào Việt Nam"
/// - Thẻ trắng bo cong:
///   - "Chào mừng trở lại!"
///   - "Đăng nhập để không bỏ lỡ trận cầu nào."
///   - Trường "Số điện thoại hoặc email"
///   - Trường "Mật khẩu" kèm toggle ẩn/hiện
///   - Link "Quên mật khẩu?"
///   - Nút `→ Đăng nhập` xanh lá bo lớn
///   - "Chưa có tài khoản? Đăng ký ngay"
///   - "Một tài khoản. Cả cộng đồng bóng đá."
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _accountCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.login(_accountCtrl.text.trim(), _passCtrl.text);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText(e)),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HERO HEADER CẦU THỦ & BALLHUB BANNER ---
            Stack(
              children: [
                // Hình nền sân cỏ đêm với hiệu ứng gradient
                Container(
                  height: 310,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0F2B1D),
                        Color(0xFF133E2B),
                        Color(0xFF0D1B2A),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Họa tiết sân bóng / vân cỏ mờ
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.15,
                          child: CustomPaint(
                            painter: _PitchFieldPainter(),
                          ),
                        ),
                      ),
                      // Lớp phủ bóng mờ
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Nội dung trên Banner: Logo + Khẩu hiệu
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // Logo Ballhub
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFBBF24),
                              ),
                              child: const Icon(
                                Icons.sports_soccer,
                                size: 18,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ballhub',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),

                        // Khẩu hiệu lớn
                        const Text(
                          'Chung đam mê.\nCùng ra sân.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kết nối bóng đá phong trào Việt Nam',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- FORM ĐĂNG NHẬP TRẮNG ---
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Chào mừng trở lại!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Đăng nhập để không bỏ lỡ trận cầu nào.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Trường Email
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _accountCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'Nhập địa chỉ email của bạn',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Vui lòng nhập email';
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Vui lòng nhập định dạng email hợp lệ (ví dụ: ban@gmail.com)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Trường Mật khẩu
                    const Text(
                      'Mật khẩu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                    ),
                    const SizedBox(height: 12),

                    // Quên mật khẩu?
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: AppTheme.primaryDarkGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nút Đăng nhập
                    ElevatedButton(
                      onPressed: _loading ? null : _login,
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
                                Text('Đăng nhập'),
                              ],
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Chưa có tài khoản? Đăng ký ngay
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: const Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              color: AppTheme.primaryDarkGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Slogan cuối
                    const Text(
                      'Một tài khoản. Cả cộng đồng bóng đá.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vẽ vân sân cỏ minh họa
class _PitchFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Vòng tròn trung tâm
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 60, paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
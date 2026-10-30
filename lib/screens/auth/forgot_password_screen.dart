import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/ui_helpers.dart';

/// Màn hình Quên mật khẩu (Page 3 - figma.pdf)
///
/// Bố cục:
/// - AppBar: `← Quên mật khẩu`
/// - Icon minh họa: Khối tròn xanh lá nhạt với biểu tượng chìa khóa
/// - Tiêu đề: "Trở lại sân cỏ,\nchỉ vài bước."
/// - Mô tả: "Nhập số điện thoại hoặc email đã đăng ký. Chúng tôi sẽ gửi hướng dẫn để bạn đặt lại mật khẩu."
/// - Input: "Số điện thoại hoặc email", placeholder: "Nhập thông tin khôi phục"
/// - Nút CTA: `→ Gửi yêu cầu khôi phục`
/// - Thẻ an toàn: Khiên xanh + "Bảo vệ tài khoản của bạn: Không chia sẻ mã xác thực với bất kỳ ai, kể cả người tự xưng là Ballhub."
/// - Liên kết: `← Quay lại đăng nhập`
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      showMessage(context, 'Vui lòng nhập số điện thoại hoặc email');
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _loading = false;
        _sent = true;
      });
      showMessage(context, 'Mã xác thực đã được gửi tới $text');
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
        title: const Text('Quên mật khẩu'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Icon chìa khóa
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLightGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.vpn_key_outlined,
                    color: AppTheme.primaryDarkGreen,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tiêu đề & mô tả
              const Text(
                'Trở lại sân cỏ,\nchỉ vài bước.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nhập số điện thoại hoặc email đã đăng ký. Chúng tôi sẽ gửi hướng dẫn để bạn đặt lại mật khẩu.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Trường nhập
              const Text(
                'Số điện thoại hoặc email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Nhập thông tin khôi phục',
                ),
              ),
              const SizedBox(height: 24),

              // Nút CTA gửi yêu cầu
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_forward, size: 18),
                          const SizedBox(width: 8),
                          Text(_sent ? 'Gửi lại yêu cầu' : 'Gửi yêu cầu khôi phục'),
                        ],
                      ),
              ),
              const SizedBox(height: 32),

              // Thẻ cảnh báo bảo vệ tài khoản
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined, color: AppTheme.primaryDarkGreen, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bảo vệ tài khoản của bạn',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Không chia sẻ mã xác thực với bất kỳ ai, kể cả người tự xưng là Ballhub.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Nút quay lại đăng nhập
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18, color: AppTheme.primaryDarkGreen),
                  label: const Text(
                    'Quay lại đăng nhập',
                    style: TextStyle(
                      color: AppTheme.primaryDarkGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

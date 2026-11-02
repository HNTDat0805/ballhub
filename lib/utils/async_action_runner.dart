import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/theme/app_theme.dart';

/// Bộ điều phối thực thi các tác vụ bất đồng bộ (Async Action Runner).
///
/// Giải quyết các bài toán quan trọng theo quy chuẩn AGENTS.md:
/// 1. Hiển thị loading feedback rõ ràng cho người dùng (Loading Dialog hoặc Spinner).
/// 2. Chống gửi đúp / gửi trùng (double submission / multiple tap prevention).
/// 3. Bắt lỗi chuẩn hóa bằng tiếng Việt thân thiện, không làm sập ứng dụng.
/// 4. Kiểm tra an toàn `context.mounted` sau mỗi bước `await`.
class AsyncActionRunner {
  /// Thực thi một tác vụ bất đồng bộ [action] với hộp thoại tiến trình (Loading Dialog)
  /// và thông báo kết quả thân thiện.
  static Future<T?> run<T>(
    BuildContext context, {
    required Future<T> Function() action,
    String loadingTitle = 'Đang xử lý...',
    String loadingMessage = 'Vui lòng đợi trong giây lát...',
    String? successMessage,
    bool showLoadingDialog = true,
  }) async {
    bool dialogOpen = false;

    if (showLoadingDialog && context.mounted) {
      dialogOpen = true;
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
                const CircularProgressIndicator(
                  color: AppTheme.primaryDarkGreen,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loadingTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loadingMessage,
                        style: const TextStyle(
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
    }

    try {
      final result = await action();

      if (dialogOpen && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }

      if (successMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppTheme.primaryDarkGreen,
          ),
        );
      }

      return result;
    } catch (e) {
      if (dialogOpen && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }

      if (context.mounted) {
        String msg = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
        if (e is ApiException) {
          msg = e.message;
        } else {
          final errStr = e.toString().replaceFirst('Exception: ', '');
          if (errStr.isNotEmpty) msg = errStr;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.errorRed),
        );
      }
      return null;
    } finally {
      if (dialogOpen && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}

/// Nút bấm tương tác hỗ trợ xử lý tác vụ bất đồng bộ, tự động chống bấm đúp
/// và hiển thị vòng quay tải (Spinner) trong quá trình thực thi.
class AsyncElevatedButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool autofocus;

  const AsyncElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.autofocus = false,
  });

  @override
  State<AsyncElevatedButton> createState() => _AsyncElevatedButtonState();
}

class _AsyncElevatedButtonState extends State<AsyncElevatedButton> {
  bool _isBusy = false;

  Future<void> _handlePress() async {
    if (widget.onPressed == null || _isBusy) return;

    setState(() => _isBusy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.onPressed == null
          ? null
          : (_isBusy ? null : _handlePress),
      style: widget.style,
      autofocus: widget.autofocus,
      child: _isBusy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : widget.child,
    );
  }
}

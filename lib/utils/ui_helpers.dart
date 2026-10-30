import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void showMessage(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

// Đổi lỗi Firebase sang tiếng Việt
String errorText(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email này đã được đăng ký';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'weak-password':
        return 'Mật khẩu quá yếu (ít nhất 6 ký tự)';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Sai email hoặc mật khẩu';
      case 'too-many-requests':
        return 'Thử quá nhiều lần, vui lòng đợi một lát';
      case 'network-request-failed':
        return 'Không có kết nối mạng';
      default:
        return e.message ?? 'Lỗi đăng nhập';
    }
  }
  if (e is FirebaseException) return e.message ?? 'Lỗi Firebase';
  return e.toString();
}

String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
  if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$').hasMatch(v.trim())) return 'Email không hợp lệ';
  return null;
}

Future<bool> confirmDialog(BuildContext context, String title, String content) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
      ],
    ),
  );
  return ok ?? false;
}
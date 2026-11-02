import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tiện ích xử lý trì hoãn hành động bất đồng bộ (Debounce).
///
/// Thường dùng cho các ô nhập liệu tìm kiếm (search bar) hoặc các nút bấm tương tác
/// nhằm tránh gửi quá nhiều yêu cầu mạng liên tiếp (spam requests / race conditions).
class Debouncer {
  /// Thời gian trì hoãn mặc định (350 milliseconds)
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 350)});

  /// Thực thi hành động [action] sau khoảng thời gian [delay].
  /// Nếu có yêu cầu mới tới trước khi hết thời gian, yêu cầu cũ sẽ bị hủy.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Thực thi tác vụ bất đồng bộ [action] sau khoảng thời gian [delay].
  void runAsync(Future<void> Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, () async {
      try {
        await action();
      } catch (e) {
        debugPrint('Debouncer.runAsync error: $e');
      }
    });
  }

  /// Hủy bỏ tác vụ đang chờ thực thi nếu có
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Kiểm tra xem có tác vụ nào đang chờ thực thi hay không
  bool get isWaiting => _timer?.isActive ?? false;

  /// Giải phóng timer khi Widget bị dispose
  void dispose() {
    cancel();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../auth/auth_context.dart';

/// Đại diện cho lỗi trả về từ hệ thống REST API Backend của Ballhub.
/// Chứa mã lỗi máy tính (code), thông báo thân thiện (message),
/// mã HTTP trạng thái (statusCode) và chi tiết lỗi xác thực dữ liệu (details).
class ApiException implements Exception {
  /// Mã định danh lỗi (ví dụ: 'UNAUTHORIZED', 'MAX_TEAMS_REACHED', 'NOT_FOUND')
  final String code;

  /// Thông điệp lỗi chi tiết hiển thị cho người dùng
  final String message;

  /// Mã trạng thái HTTP (400, 401, 403, 404, 409, 500,...)
  final int statusCode;

  /// Chi tiết bổ sung (ví dụ: danh sách trường bị lỗi từ Zod validator)
  final dynamic details;

  ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.details,
  });

  @override
  String toString() => message;
}

/// HTTP REST Client trung tâm của ứng dụng Ballhub.
///
/// Chịu trách nhiệm:
/// 1. Tự động nhận diện Base URL (Localhost cho Web/Desktop, 10.0.2.2 cho Android Emulator).
/// 2. Gắn kèm Authorization Bearer Token và User Persona Headers vào từng request.
/// 3. Mã hóa/Giải mã JSON, chuẩn hóa phản hồi và bọc lỗi mạng thành [ApiException].
/// 4. Đặt thời gian chờ (timeout) 10 giây để chống treo kết nối phía client.
class ApiClient {
  /// Đường dẫn gốc của API Backend (mặc định: http://localhost:5001/api/v1 hoặc 10.0.2.2:5001/api/v1)
  final String baseUrl;

  /// Instance http.Client để thực hiện các cuộc gọi mạng HTTP
  final http.Client _client;

  ApiClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? _resolveDefaultBaseUrl(),
        _client = client ?? http.Client();

  /// Tự động phân giải Base URL phù hợp với nền tảng đang chạy
  static String _resolveDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:5001/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        // Android Emulator sử dụng 10.0.2.2 để trỏ về localhost của máy chủ host
        return 'http://10.0.2.2:5001/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:5001/api/v1';
  }

  /// Xây dựng headers chuẩn cho request bao gồm Content-Type, Accept và Authentication
  Map<String, String> _buildHeaders() {
    final user = AuthContext.instance.currentUser;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Gửi token xác thực cùng thông tin định danh (persona) đang hoạt động
      'Authorization': 'Bearer mock-token-${user.id}-${user.role.name}',
      'x-user-id': user.id,
      'x-user-role': user.role.name,
      'x-user-name': user.name,
      if (user.teamId != null) 'x-user-team': user.teamId!,
    };
  }

  /// Gửi HTTP GET request với các query parameters tùy chọn
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    Uri uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      final cleanParams = queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      uri = uri.replace(queryParameters: cleanParams);
    }

    try {
      final response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e, 'GET $path');
    }
  }

  /// Gửi HTTP POST request kèm JSON body
  Future<dynamic> post(String path, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e, 'POST $path');
    }
  }

  /// Gửi HTTP PATCH request để cập nhật một phần dữ liệu
  Future<dynamic> patch(String path, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .patch(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e, 'PATCH $path');
    }
  }

  /// Gửi HTTP PUT request để thay thế hoặc xác nhận dữ liệu (ví dụ: cập nhật kết quả trận đấu)
  Future<dynamic> put(String path, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e, 'PUT $path');
    }
  }

  /// Gửi HTTP DELETE request để xóa tài nguyên
  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .delete(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e, 'DELETE $path');
    }
  }

  /// Xử lý phản hồi từ server: bóc tách wrapper {success: true, data: ...}
  /// hoặc ném ra [ApiException] khi server trả về mã lỗi >= 400.
  dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      if (response.body.isNotEmpty) {
        jsonBody = jsonDecode(response.body);
      }
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('data')) {
        return jsonBody['data'];
      }
      return jsonBody;
    }

    // Error response
    String message = 'Lỗi kết nối máy chủ (${response.statusCode})';
    String code = 'API_ERROR';
    dynamic details;

    if (jsonBody is Map<String, dynamic> && jsonBody['error'] is Map) {
      final err = jsonBody['error'] as Map;
      message = err['message']?.toString() ?? message;
      code = err['code']?.toString() ?? code;
      details = err['details'];
    }

    throw ApiException(
      code: code,
      message: message,
      statusCode: response.statusCode,
      details: details,
    );
  }

  /// Chuẩn hóa tất cả các ngoại lệ mạng (TimeoutException, SocketException, ClientException)
  /// thành [ApiException] rõ ràng để UI có thể hiển thị thông báo phù hợp.
  Never _handleNetworkError(dynamic error, String operation) {
    if (error is ApiException) {
      throw error;
    }
    if (error is TimeoutException) {
      throw ApiException(
        code: 'TIMEOUT',
        message: 'Yêu cầu tới máy chủ quá thời gian chờ (10s). Vui lòng thử lại.',
        statusCode: 408,
      );
    }
    throw ApiException(
      code: 'NETWORK_ERROR',
      message: 'Không thể kết nối tới API Backend Ballhub ($operation): $error',
      statusCode: 503,
    );
  }
}

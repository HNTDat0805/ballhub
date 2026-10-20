import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../auth/auth_context.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;
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

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? _resolveDefaultBaseUrl(),
        _client = client ?? http.Client();

  static String _resolveDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:5001/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        // Android Emulator loops 10.0.2.2 back to host localhost
        return 'http://10.0.2.2:5001/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:5001/api/v1';
  }

  Map<String, String> _buildHeaders() {
    final user = AuthContext.instance.currentUser;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Send persona / ID headers for development and authenticated requests
      'Authorization': 'Bearer mock-token-${user.id}-${user.role.name}',
      'x-user-id': user.id,
      'x-user-role': user.role.name,
      'x-user-name': user.name,
      if (user.teamId != null) 'x-user-team': user.teamId!,
    };
  }

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

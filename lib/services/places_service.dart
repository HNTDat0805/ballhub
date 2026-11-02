import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api/api_client.dart';
import '../models/place_location.dart';
import '../data/seeds/places_seed_data.dart';
import 'province_service.dart';

/// Dịch vụ kết nối Google Places API với Session Token & Fallback Offline
class PlacesService {
  /// Đọc API Key từ môi trường cấu hình build Flutter (--dart-define=GOOGLE_MAPS_API_KEY=...)
  static const String _envApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  static ApiClient _api = ApiClient();
  @visibleForTesting
  static set apiClient(ApiClient client) => _api = client;

  static http.Client _httpClient = http.Client();
  @visibleForTesting
  static set httpClient(http.Client client) => _httpClient = client;

  /// Tạo Google Places Autocomplete Session Token (chuẩn UUID v4)
  /// để tối ưu chi phí billing (gom tất cả keystrokes và chi tiết Place Details vào 1 session SKU).
  static String generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant RFC 4122

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Tìm kiếm gợi ý địa điểm theo thời gian thực từ Google Places Autocomplete API
  /// hoặc Backend Proxy / Fallback khi offline.
  static Future<List<PlacePrediction>> getAutocompletePredictions(
    String query, {
    String? sessionToken,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const [];

    // 1. Nếu có cấu hình GOOGLE_MAPS_API_KEY ở client, gọi trực tiếp Google Places API
    if (_envApiKey.isNotEmpty) {
      try {
        final uri = Uri.https(
          'maps.googleapis.com',
          '/maps/api/place/autocomplete/json',
          {
            'input': cleanQuery,
            'key': _envApiKey,
            'language': 'vi',
            'components': 'country:vn',
            if (sessionToken != null && sessionToken.isNotEmpty)
              'sessiontoken': sessionToken,
          },
        );

        final response = await _httpClient
            .get(uri)
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final status = data['status'] as String? ?? '';
          if (status == 'OK' || status == 'ZERO_RESULTS') {
            final predictions = data['predictions'];
            if (predictions is List) {
              return predictions
                  .whereType<Map>()
                  .map(
                    (m) => PlacePrediction.fromGoogleJson(
                      Map<String, dynamic>.from(m),
                    ),
                  )
                  .toList();
            }
          }
        }
      } catch (e) {
        debugPrint(
          'PlacesService: Direct Google API call error, trying backend proxy: $e',
        );
      }
    }

    // 2. Thử gọi qua Backend REST API Proxy (/api/v1/places/autocomplete)
    try {
      final res = await _api.get(
        '/places/autocomplete',
        queryParams: {
          'input': cleanQuery,
          if (sessionToken != null && sessionToken.isNotEmpty)
            'sessiontoken': sessionToken,
        },
      );

      if (res is Map && res['predictions'] is List) {
        final list = (res['predictions'] as List)
            .whereType<Map>()
            .map(
              (m) =>
                  PlacePrediction.fromGoogleJson(Map<String, dynamic>.from(m)),
            )
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {
      // Backend offline hoặc chưa có API key trên server
    }

    // 3. Fallback Offline: Sử dụng ProvinceService kết hợp Hub bóng đá mẫu
    return _getLocalFallbackPredictions(cleanQuery);
  }

  /// Lấy thông tin chi tiết địa điểm (tọa độ, đơn vị hành chính) bằng Place Details API
  static Future<PlaceLocation?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    if (placeId.isEmpty) return null;

    // 1. Kiểm tra nếu là mã fallback nội bộ
    if (placeId.startsWith('hub_') || placeId.startsWith('local_')) {
      return _resolveLocalPlaceDetails(placeId);
    }

    // 2. Nếu có client API Key, gọi trực tiếp Google Places Details API
    if (_envApiKey.isNotEmpty) {
      try {
        final uri = Uri.https(
          'maps.googleapis.com',
          '/maps/api/place/details/json',
          {
            'place_id': placeId,
            'key': _envApiKey,
            'language': 'vi',
            'fields':
                'place_id,name,formatted_address,geometry,address_components',
            if (sessionToken != null && sessionToken.isNotEmpty)
              'sessiontoken': sessionToken,
          },
        );

        final response = await _httpClient
            .get(uri)
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data['status'] == 'OK' && data['result'] is Map) {
            return PlaceLocation.fromGooglePlaceDetails(
              Map<String, dynamic>.from(data['result'] as Map),
            );
          }
        }
      } catch (e) {
        debugPrint(
          'PlacesService: Direct Place Details error, trying proxy: $e',
        );
      }
    }

    // 3. Thử qua Backend Proxy (/api/v1/places/details)
    try {
      final res = await _api.get(
        '/places/details',
        queryParams: {
          'place_id': placeId,
          if (sessionToken != null && sessionToken.isNotEmpty)
            'sessiontoken': sessionToken,
        },
      );

      if (res is Map && res['result'] is Map) {
        return PlaceLocation.fromGooglePlaceDetails(
          Map<String, dynamic>.from(res['result'] as Map),
        );
      }
    } catch (_) {}

    // 4. Nếu không lấy được chi tiết, cố gắng phân giải fallback
    return _resolveLocalPlaceDetails(placeId);
  }

  /// Tìm kiếm gợi ý cục bộ hỗ trợ tiếng Việt có dấu và không dấu
  static Future<List<PlacePrediction>> _getLocalFallbackPredictions(
    String query,
  ) async {
    final cleanQ = ProvinceService.removeAccents(query.trim().toLowerCase());
    final matches = <PlacePrediction>[];

    // Khớp Hub bóng đá phổ biến
    for (final hub in PlacesSeedData.sampleHubPredictions) {
      final mainClean = ProvinceService.removeAccents(
        hub.mainText.toLowerCase(),
      );
      final descClean = ProvinceService.removeAccents(
        hub.description.toLowerCase(),
      );
      if (mainClean.contains(cleanQ) || descClean.contains(cleanQ)) {
        matches.add(hub);
      }
    }

    // Khớp từ ProvinceService (Tỉnh/Thành phố & Quận/Huyện)
    try {
      final provinces = await ProvinceService.getProvinces();
      for (final p in provinces) {
        final pClean = ProvinceService.removeAccents(
          p.displayName.toLowerCase(),
        );
        final districts = ProvinceService.getDistricts(p.displayName);

        // Khớp tỉnh thành
        if (pClean.contains(cleanQ)) {
          matches.add(
            PlacePrediction(
              placeId: 'local_p_${p.code}',
              mainText: p.displayName,
              secondaryText: 'Việt Nam',
              description: '${p.displayName}, Việt Nam',
              types: ['administrative_area_level_1', 'political'],
            ),
          );
        }

        // Khớp quận huyện
        for (final d in districts) {
          final dClean = ProvinceService.removeAccents(d.toLowerCase());
          if (dClean.contains(cleanQ) || '$dClean, $pClean'.contains(cleanQ)) {
            matches.add(
              PlacePrediction(
                placeId: 'local_d_${p.code}_${d.hashCode}',
                mainText: d,
                secondaryText: '${p.displayName}, Việt Nam',
                description: '$d, ${p.displayName}, Việt Nam',
                types: ['administrative_area_level_2', 'political'],
              ),
            );
          }
        }
      }
    } catch (_) {}

    return matches.take(10).toList();
  }

  /// Trích xuất PlaceLocation cho các mục fallback nội bộ
  static PlaceLocation _resolveLocalPlaceDetails(String placeId) {
    for (final hub in PlacesSeedData.sampleHubPredictions) {
      if (hub.placeId == placeId) {
        final parts = hub.description.split(',').map((s) => s.trim()).toList();
        return PlaceLocation(
          placeId: hub.placeId,
          name: hub.mainText,
          formattedAddress: hub.description,
          province: parts.length >= 2 ? parts[parts.length - 2] : null,
          district: parts.isNotEmpty ? parts.first : null,
        );
      }
    }

    return PlaceLocation(
      placeId: placeId,
      name: placeId,
      formattedAddress: placeId,
    );
  }
}

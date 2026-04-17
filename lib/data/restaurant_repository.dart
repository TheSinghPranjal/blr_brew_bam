// ============================================================
// Field Agent – Restaurant API Repository
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../domain/restaurant_model.dart';

class RestaurantApiException implements Exception {
  final int? statusCode;
  final String message;
  const RestaurantApiException({this.statusCode, required this.message});

  @override
  String toString() => 'RestaurantApiException($statusCode): $message';
}

class RestaurantRepository {
  static const _baseUrl =
      'https://5nysoztmt8.execute-api.us-west-1.amazonaws.com/default';

  static const _headers = {'Content-Type': 'application/json'};

  // ── Fetch all restaurants ─────────────────────────────────────────────
  Future<List<Restaurant>> fetchRestaurants() async {
    final url = '$_baseUrl/fetchRestaurants';
    dev.log('GET $url', name: 'RestaurantRepository');

    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw const RestaurantApiException(
            message: 'Request timed out. Please check your connection.',
          ),
        );

    dev.log(
      'Response ${response.statusCode} — ${response.body.length} bytes',
      name: 'RestaurantRepository',
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw RestaurantApiException(
      statusCode: response.statusCode,
      message: _extractError(response.body, response.statusCode),
    );
  }

  // ── Add a new restaurant ──────────────────────────────────────────────
  Future<Map<String, dynamic>> addRestaurant({
    required String name,
    required String type,
    required String city,
    required String area,
    required String address,
    required String createdBy,
    required List<String> superAdminEmails,
  }) async {
    final url = '$_baseUrl/addNewRastaurant';
    final payload = {
      'name': name,
      'type': type,
      'city': city,
      'area': area,
      'address': address,
      'created_by': createdBy,
      'super_admin_emails': superAdminEmails,
    };

    dev.log(
      'POST $url\nBody: ${jsonEncode(payload)}',
      name: 'RestaurantRepository',
    );

    final response = await http
        .post(Uri.parse(url), headers: _headers, body: jsonEncode(payload))
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw const RestaurantApiException(
            message: 'Request timed out. Please check your connection.',
          ),
        );

    dev.log(
      'Response ${response.statusCode} — ${response.body}',
      name: 'RestaurantRepository',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.body;
      if (body.isEmpty) return {'status': 'ok'};
      return jsonDecode(body) as Map<String, dynamic>;
    }

    throw RestaurantApiException(
      statusCode: response.statusCode,
      message: _extractError(response.body, response.statusCode),
    );
  }

  // ── Shared error extractor ────────────────────────────────────────────
  String _extractError(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'Unexpected error ($statusCode)';
    } catch (_) {
      return body.isNotEmpty ? body : 'Unexpected error ($statusCode)';
    }
  }
}


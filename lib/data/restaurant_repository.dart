// ============================================================
// Field Agent – Restaurant API Repository
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

class RestaurantApiException implements Exception {
  final int? statusCode;
  final String message;
  const RestaurantApiException({this.statusCode, required this.message});

  @override
  String toString() => 'RestaurantApiException($statusCode): $message';
}

class RestaurantRepository {
  static const _endpoint =
      'https://5nysoztmt8.execute-api.us-west-1.amazonaws.com/default/addNewRastaurant';

  static const _headers = {
    'Content-Type': 'application/json',
  };

  /// POSTs a new restaurant to the API.
  /// Returns the raw response body as a [Map] on success.
  /// Throws [RestaurantApiException] on failure.
  Future<Map<String, dynamic>> addRestaurant({
    required String name,
    required String type,       // RestaurantType.name  e.g. "cafe"
    required String city,
    required String area,
    required String address,
    required String createdBy,
    required List<String> superAdminEmails,
  }) async {
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
      '══════════════════════════════════════════════════\n'
      '  [RestaurantRepository] POST addNewRastaurant\n'
      '  URL   : $_endpoint\n'
      '  Body  : ${jsonEncode(payload)}\n'
      '══════════════════════════════════════════════════',
      name: 'RestaurantRepository',
    );

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw const RestaurantApiException(
            message: 'Request timed out. Please check your connection.',
          ),
        );

    dev.log(
      '  [RestaurantRepository] Response ${response.statusCode}\n'
      '  Body: ${response.body}',
      name: 'RestaurantRepository',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.body;
      if (body.isEmpty) return {'status': 'ok'};
      return jsonDecode(body) as Map<String, dynamic>;
    }

    // Try to extract a server error message
    String serverMessage = 'Unexpected error (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      serverMessage = decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          serverMessage;
    } catch (_) {
      if (response.body.isNotEmpty) serverMessage = response.body;
    }

    throw RestaurantApiException(
      statusCode: response.statusCode,
      message: serverMessage,
    );
  }
}

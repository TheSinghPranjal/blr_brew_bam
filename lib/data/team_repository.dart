// ============================================================
// Team – Invite Members API Repository (Super Admin)
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

class TeamApiException implements Exception {
  final int? statusCode;
  final String message;
  const TeamApiException({this.statusCode, required this.message});

  @override
  String toString() => 'TeamApiException($statusCode): $message';
}

class TeamRepository {
  static const _baseUrl =
      'https://5nysoztmt8.execute-api.us-west-1.amazonaws.com/default';

  static const _headers = {'Content-Type': 'application/json'};

  Future<Map<String, dynamic>> fetchMembersFromMyRestaurant({
    required String restaurantId,
  }) async {
    final url = '$_baseUrl/fetchMembersFromMyRestaurant?restaurantId=$restaurantId';
    dev.log('GET $url', name: 'TeamRepository');

    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw const TeamApiException(
            message: 'Request timed out. Please check your connection.',
          ),
        );

    dev.log(
      'Response ${response.statusCode} — ${response.body}',
      name: 'TeamRepository',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return const {'count': 0, 'users': []};
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return const {'count': 0, 'users': []};
    }

    throw TeamApiException(
      statusCode: response.statusCode,
      message: _extractError(response.body, response.statusCode),
    );
  }

  Future<String> sendInviteToAddMembersForARestaurant({
    required String email,
    required String role,
    required String restaurantId,
    required String superAdminId,
    required String superAdminName,
  }) async {
    final url = '$_baseUrl/sendInviteToAddMembersForARestaurant';

    final payload = {
      'email': email.trim().toLowerCase(),
      'role': role,
      'restaurantId': restaurantId,
      'superAdminId': superAdminId,
      'superAdminName': superAdminName,
    };

    dev.log(
      'POST $url\nBody: ${jsonEncode(payload)}',
      name: 'TeamRepository',
    );

    final response = await http
        .post(Uri.parse(url), headers: _headers, body: jsonEncode(payload))
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw const TeamApiException(
            message: 'Request timed out. Please check your connection.',
          ),
        );

    dev.log(
      'Response ${response.statusCode} — ${response.body}',
      name: 'TeamRepository',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) return 'Invite sent';
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ?? 'Invite sent';
      }
      return 'Invite sent';
    }

    throw TeamApiException(
      statusCode: response.statusCode,
      message: _extractError(response.body, response.statusCode),
    );
  }

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


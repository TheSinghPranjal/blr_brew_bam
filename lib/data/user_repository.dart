import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

class UserApiException implements Exception {
  final int? statusCode;
  final String message;
  const UserApiException({this.statusCode, required this.message});

  @override
  String toString() => 'UserApiException($statusCode): $message';
}

/// Profile returned from syncUserOnLogin / user_table.
class UserProfile {
  final String userId;
  final String email;
  final String role;
  final String restaurantId;
  final String status;
  final String? name;
  final String? mobile;
  final bool profileComplete;
  final List<String> cognitoGroups;
  final String? staffRole;
  final bool isRestaurantStaff;

  const UserProfile({
    required this.userId,
    required this.email,
    required this.role,
    required this.restaurantId,
    required this.status,
    this.name,
    this.mobile,
    this.profileComplete = false,
    this.cognitoGroups = const [],
    this.staffRole,
    this.isRestaurantStaff = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    final groups = (json['groups'] as List<dynamic>?)
            ?.map((g) => g.toString())
            .toList() ??
        const [];

    if (profile == null) {
      return UserProfile(
        userId: '',
        email: json['email']?.toString() ?? '',
        role: 'customer',
        restaurantId: 'none',
        status: 'active',
        cognitoGroups: groups,
      );
    }

    return UserProfile(
      userId: profile['user_id']?.toString() ?? '',
      email: profile['email']?.toString() ?? '',
      role: profile['role']?.toString().toLowerCase() ?? 'customer',
      restaurantId: profile['restaurant_id']?.toString() ?? 'none',
      status: profile['status']?.toString() ?? '',
      name: profile['name']?.toString(),
      mobile: profile['mobile']?.toString(),
      profileComplete: profile['profile_complete'] == true,
      cognitoGroups: groups,
      staffRole: profile['staff_role']?.toString(),
      isRestaurantStaff: profile['is_restaurant_staff'] == true,
    );
  }
}

class UserRepository {
  static const _baseUrl =
      'https://5nysoztmt8.execute-api.us-west-1.amazonaws.com/default';

  static const _headers = {'Content-Type': 'application/json'};

  /// Links invited user in DynamoDB + Cognito groups. Call after Google sign-in.
  Future<UserProfile> syncUserOnLogin({
    required String email,
    required String cognitoSub,
    String? cognitoUsername,
    String? accessToken,
  }) async {
    final url = '$_baseUrl/syncUserOnLogin';
    final payload = {
      'email': email.trim().toLowerCase(),
      'cognitoSub': cognitoSub,
      if (cognitoUsername != null) 'cognitoUsername': cognitoUsername,
    };

    final headers = Map<String, String>.from(_headers);
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    dev.log('POST $url\nBody: ${jsonEncode(payload)}', name: 'UserRepository');

    final response = await http
        .post(Uri.parse(url), headers: headers, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 30));

    dev.log(
      'syncUserOnLogin ${response.statusCode} — ${response.body}',
      name: 'UserRepository',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return UserProfile.fromJson(decoded);
    }

    throw UserApiException(
      statusCode: response.statusCode,
      message: _extractError(response.body, response.statusCode),
    );
  }

  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String mobile,
    List<String>? languages,
    String? about,
  }) async {
    final url = '$_baseUrl/updateUserProfile';
    final payload = {
      'userId': userId,
      'name': name,
      'mobile': mobile,
      if (languages != null) 'languages': languages,
      if (about != null) 'about': about,
    };

    dev.log('POST $url', name: 'UserRepository');

    final response = await http
        .post(Uri.parse(url), headers: _headers, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw UserApiException(
        statusCode: response.statusCode,
        message: _extractError(response.body, response.statusCode),
      );
    }
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

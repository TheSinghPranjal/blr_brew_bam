import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import 'app_logger.dart';

// ════════════════════════════════════════════════════════════════════════════
// AuthTokenClaims — parsed payload from the Cognito ID token
// ════════════════════════════════════════════════════════════════════════════

/// Holds all claims decoded from the Cognito ID token JWT.
///
/// Cognito injects `cognito:groups` as a JSON array, so we keep groups
/// separately from the flat scalar map.
class AuthTokenClaims {
  final Map<String, String> scalars;
  final List<String> groups;

  const AuthTokenClaims({required this.scalars, required this.groups});

  factory AuthTokenClaims.empty() =>
      const AuthTokenClaims(scalars: {}, groups: []);

  // ── Convenience getters ───────────────────────────────────────────────
  String? get email    => scalars['email'];
  String? get sub      => scalars['sub'];
  String? get picture  => scalars['picture'];

  String get displayName =>
      scalars['name'] ??
      scalars['given_name'] ??
      scalars['cognito:username'] ??
      scalars['preferred_username'] ??
      (email?.split('@').first ?? '');

  // ── Cognito group → UserRole mapping ──────────────────────────────────

  /// Maps Cognito group names (lowercase, underscored) to app roles.
  /// Must match exactly what you named the groups in the Cognito console.
  static const _groupRoleMap = <String, UserRole>{
    'super_admin':   UserRole.superAdmin,
    'manager':       UserRole.manager,
    'head_chef':     UserRole.headChef,
    'chef':          UserRole.chef,
    'kitchen':       UserRole.kitchen,
    'senior_waiter': UserRole.seniorWaiter,
    'waiter':        UserRole.waiter,
    'service_desk':  UserRole.serviceDesk,
    'cleaning':      UserRole.cleaning,
    'inventory':     UserRole.inventory,
    'field_agent':   UserRole.fieldAgent,
    'customer':      UserRole.customer,
  };

  /// Priority list: first match wins (highest privilege first).
  static const _rolePriority = [
    UserRole.superAdmin,
    UserRole.manager,
    UserRole.headChef,
    UserRole.chef,
    UserRole.kitchen,
    UserRole.seniorWaiter,
    UserRole.waiter,
    UserRole.serviceDesk,
    UserRole.fieldAgent,
    UserRole.cleaning,
    UserRole.inventory,
    UserRole.customer,
  ];

  /// Converts snake_case group name to camelCase enum name.
  /// Example: 'field_agent' → 'fieldAgent'
  static String _toCamelCase(String snakeCase) {
    return snakeCase.split('_').asMap().entries.fold<String>('', (acc, e) {
      if (e.key == 0) return e.value;
      return acc + (e.value.isEmpty ? '' : e.value[0].toUpperCase() + e.value.substring(1));
    });
  }

  /// Tries to find a matching UserRole for the given group name.
  /// First checks the explicit [_groupRoleMap], then tries to match by name conversion.
  static UserRole? _mapGroupToRole(String groupName) {
    // Try explicit mapping first
    if (_groupRoleMap.containsKey(groupName)) {
      return _groupRoleMap[groupName];
    }

    // Try to find a UserRole by matching the camelCase name
    try {
      final camelCaseName = _toCamelCase(groupName);
      for (final role in UserRole.values) {
        if (role.name == camelCaseName) return role;
      }
    } catch (_) {
      // Ignore conversion errors
    }

    return null;
  }

  /// Returns the highest-privilege role from the user's Cognito groups.
  /// Falls back to [UserRole.customer] if no matching group is found.
  UserRole get highestPriorityRole {
    final userRoles = groups
        .map((g) => _mapGroupToRole(g))
        .whereType<UserRole>()
        .toSet();

    for (final role in _rolePriority) {
      if (userRoles.contains(role)) return role;
    }

    return UserRole.customer; // safe default
  }

  @override
  String toString() =>
      'AuthTokenClaims(email: $email, groups: $groups, role: ${highestPriorityRole.name})';
}

// ════════════════════════════════════════════════════════════════════════════
// AmplifyAuthService
// ════════════════════════════════════════════════════════════════════════════

/// Central service for all Cognito / Amplify Auth operations.
///
/// Flow:
///   1. [signInWithGoogle]      → opens Cognito Hosted UI
///   2. [fetchTokenClaims]      → decodes ID token (email, name, groups, role)
///   3. [getCurrentUser]        → returns AuthUser? for session check
///   4. [getAccessToken]        → raw JWT for API Authorization header
///   5. [signOut]               → global sign-out
class AmplifyAuthService {
  static const _log = AppLogger('AmplifyAuthService');

  // ── Sign-in ──────────────────────────────────────────────────────────

  /// Opens the Cognito Hosted UI with Google as the identity provider.
  Future<SignInResult> signInWithGoogle() async {
    _log.info('Initiating Google sign-in via Cognito Hosted UI…');
    try {
      final result = await Amplify.Auth.signInWithWebUI(
        provider: AuthProvider.google,
        options: const SignInWithWebUIOptions(
          pluginOptions: CognitoSignInWithWebUIPluginOptions(
            isPreferPrivateSession: false,
          ),
        ),
      );
      _log.info('signInWithWebUI complete — isSignedIn: ${result.isSignedIn}');
      return result;
    } catch (e, st) {
      _log.error('signInWithGoogle failed', e, st);
      rethrow;
    }
  }

  // ── Session check ─────────────────────────────────────────────────────

  /// Returns [AuthUser] if a valid Cognito session exists, null otherwise.
  Future<AuthUser?> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      _log.info('getCurrentUser → uid: ${user.userId}');
      return user;
    } on SignedOutException {
      _log.debug('getCurrentUser → no active session');
      return null;
    } catch (e) {
      _log.error('getCurrentUser error', e);
      return null;
    }
  }

  /// Quick boolean check for auth state.
  Future<bool> get isSignedIn async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      final signedIn = session.isSignedIn;
      _log.debug('isSignedIn: $signedIn');
      return signedIn;
    } catch (_) {
      return false;
    }
  }

  // ── JWT Decoding ──────────────────────────────────────────────────────

  /// Decodes the raw JWT payload (base64url) and returns the dynamic map.
  static Map<String, dynamic> _decodeJwtRaw(String jwt) {
    final parts = jwt.split('.');
    if (parts.length < 2) return {};
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    switch (payload.length % 4) {
      case 2: payload += '=='; break;
      case 3: payload += '=';  break;
      default: break;
    }
    final decoded = utf8.decode(base64.decode(payload));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  // ── Token claims ──────────────────────────────────────────────────────

  /// Decodes the ID token JWT and returns a typed [AuthTokenClaims].
  ///
  /// The `cognito:groups` claim is an array in the JWT — we preserve it as
  /// a [List<String>] so [AuthTokenClaims.highestPriorityRole] can work.
  ///
  /// Requires only `openid` + `email` scopes — no extra API call.
  Future<AuthTokenClaims> fetchTokenClaims() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(forceRefresh: false),
      ) as CognitoAuthSession;

      final rawIdToken =
          session.userPoolTokensResult.value.idToken.raw;
      final payload = _decodeJwtRaw(rawIdToken);

      final scalars   = <String, String>{};
      final groups    = <String>[];

      for (final entry in payload.entries) {
        final value = entry.value;
        if (value == null) continue;

        if (entry.key == 'cognito:groups' && value is List) {
          groups.addAll(value.map((g) => g.toString()));
        } else if (value is! List && value is! Map) {
          scalars[entry.key] = value.toString();
        }
      }

      final claims = AuthTokenClaims(scalars: scalars, groups: groups);
      _log.info('Token claims → $claims');
      return claims;
    } catch (e, st) {
      _log.error('fetchTokenClaims failed', e, st);
      return AuthTokenClaims.empty();
    }
  }

  /// Backwards-compatible helper: scalar claims as a flat string map.
  Future<Map<String, String>> fetchUserInfoFromToken() async =>
      (await fetchTokenClaims()).scalars;

  /// Convenience: email from ID token.
  Future<String?> fetchEmail() async => (await fetchTokenClaims()).email;

  /// Convenience: display name from ID token.
  Future<String?> fetchName() async =>
      (await fetchTokenClaims()).displayName;

  // ── Tokens ────────────────────────────────────────────────────────────

  /// Returns the raw access token JWT.
  /// Attach to API requests: `Authorization: Bearer <token>`
  Future<String?> getAccessToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(forceRefresh: false),
      ) as CognitoAuthSession;
      final token = session.userPoolTokensResult.value.accessToken.raw;
      _log.debug('Access token retrieved (${token.length} chars)');
      return token;
    } catch (e) {
      _log.error('getAccessToken error', e);
      return null;
    }
  }

  /// Returns the raw ID token JWT.
  Future<String?> getIdToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(forceRefresh: false),
      ) as CognitoAuthSession;
      return session.userPoolTokensResult.value.idToken.raw;
    } catch (e) {
      _log.error('getIdToken error', e);
      return null;
    }
  }

  // ── Sign-out ──────────────────────────────────────────────────────────

  /// Signs the user out globally (invalidates tokens on all devices).
  Future<void> signOut() async {
    _log.info('Initiating global sign-out…');
    try {
      final result = await Amplify.Auth.signOut(
        options: const SignOutOptions(globalSignOut: true),
      );
      if (result is CognitoFailedSignOut) {
        _log.error('Sign-out failed: ${result.exception.message}');
        throw Exception('Sign-out failed: ${result.exception.message}');
      }
      _log.info('Sign-out successful');
    } catch (e, st) {
      _log.error('signOut error', e, st);
      rethrow;
    }
  }
}

import '../core/auth_service.dart';
import '../core/app_logger.dart';
import '../domain/models.dart';
import '../data/mock_data.dart';
import '../data/user_repository.dart';

const _log = AppLogger('AuthUserResolver');

/// Resolves a [RestaurantUser] after Cognito sign-in.
///
/// 1. Sync with backend (links invited users + Cognito groups)
/// 2. Force-refresh JWT so cognito:groups appear in the token
/// 3. Merge JWT groups with user_table role as fallback
class AuthUserResolver {
  final AmplifyAuthService _auth;
  final UserRepository _userRepo;

  AuthUserResolver(this._auth, this._userRepo);

  Future<RestaurantUser> resolveAfterSignIn() async {
    final cognitoUser = await _auth.getCurrentUser();
    final accessToken = await _auth.getAccessToken();

    var claims = await _auth.fetchTokenClaims(forceRefresh: false);
    final email = claims.email ?? '';
    final cognitoSub = claims.sub ?? cognitoUser?.userId ?? email;
    final cognitoUsername =
        claims.cognitoUsername ?? cognitoUser?.username ?? cognitoSub;

    _log.info(
      'Resolving user email=$email sub=$cognitoSub cognitoUsername=$cognitoUsername',
    );

    UserProfile? profile;
    Object? syncError;
    try {
      profile = await _userRepo.syncUserOnLogin(
        email: email,
        cognitoSub: cognitoSub,
        cognitoUsername: cognitoUsername,
        accessToken: accessToken,
      );
      _log.info(
        'syncUserOnLogin OK → role=${profile.role} staff=${profile.staffRole} '
        'restaurant=${profile.restaurantId} groups=${profile.cognitoGroups}',
      );
    } catch (e, st) {
      syncError = e;
      _log.error(
        'syncUserOnLogin FAILED — role will fall back to JWT only. '
        'Deploy POST /syncUserOnLogin and attach Post Authentication trigger.',
        e,
        st,
      );
    }

    if (profile != null || claims.groups.isEmpty) {
      claims = await _auth.fetchTokenClaims(forceRefresh: true);
      _log.info('Token after refresh → groups: ${claims.groups}');
    }

    final groups = _mergeGroups(claims.groups, profile);
    final staffSlug = profile?.staffRole ?? profile?.role;
    final role = _resolveRole(groups, staffSlug);
    final name = profile?.name ?? claims.displayName;

    final knownEmployee = mockUsers
        .where((u) => u.email.toLowerCase() == email.toLowerCase())
        .firstOrNull;

    return RestaurantUser(
      employeeId: profile?.userId.isNotEmpty == true
          ? profile!.userId
          : (cognitoUser?.userId ?? cognitoSub),
      name: name.isNotEmpty ? name : (knownEmployee?.name ?? email.split('@').first),
      username: email.split('@').first,
      mobileNumber: profile?.mobile ?? knownEmployee?.mobileNumber ?? '',
      email: email,
      designation: role.displayName,
      role: role,
      photoUrl: _safePhotoUrl(claims.picture ?? knownEmployee?.photoUrl),
      age: knownEmployee?.age ?? 0,
      languagesSpoken: knownEmployee?.languagesSpoken ?? [],
      metadata: {
        'cognito_groups': groups.join(','),
        'restaurant_id': profile?.restaurantId ?? 'none',
        'profile_complete': profile?.profileComplete ?? false,
        'db_role': profile?.role ?? '',
        'staff_role': staffSlug ?? '',
        'is_restaurant_staff': profile?.isRestaurantStaff ?? role.isStaffRole,
        if (syncError != null) 'sync_error': syncError.toString(),
      },
    );
  }

  List<String> _mergeGroups(List<String> jwtGroups, UserProfile? profile) {
    final merged = {...jwtGroups};
    if (profile != null) {
      merged.add('customer');
      final staff = profile.staffRole ?? profile.role;
      if (staff.isNotEmpty && staff != 'customer') merged.add(staff);
      merged.addAll(profile.cognitoGroups);
    }
    return merged.toList();
  }

  UserRole _resolveRole(List<String> groups, String? dbRole) {
    final fromJwt = AuthTokenClaims(scalars: {}, groups: groups).highestPriorityRole;
    if (fromJwt != UserRole.customer) return fromJwt;

    if (dbRole != null && dbRole.isNotEmpty) {
      final fromDb = AuthTokenClaims(scalars: {}, groups: [dbRole]).highestPriorityRole;
      if (fromDb != UserRole.customer) return fromDb;
    }

    return UserRole.customer;
  }

  String _safePhotoUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '';
  }
}

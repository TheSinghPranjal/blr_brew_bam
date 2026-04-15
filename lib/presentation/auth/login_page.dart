import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_logger.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../data/providers.dart';
import '../../domain/models.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  static const _log = AppLogger('LoginPage');

  // ── Google Sign-in ─────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final service = ref.read(amplifyAuthServiceProvider);

      _log.info('User tapped "Continue with Google"');

      // 1. Open Cognito Hosted UI → Google OAuth → callback
      final result = await service.signInWithGoogle();

      if (!result.isSignedIn) {
        _log.warn('signInWithWebUI returned isSignedIn=false');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign-in was not completed. Please try again.';
        });
        return;
      }

      // 2. Decode ID token — get email, name, AND cognito:groups
      final claims = await service.fetchTokenClaims();
      _log.info('Claims received → $claims');

      final email = claims.email ?? '';
      final name  = claims.displayName;
      // Role is authoritative from Cognito group membership
      final role  = claims.highestPriorityRole;
      _log.info('Resolved role from JWT groups: ${role.name}');

      // 3. Enrich with mock data if the email matches a known employee
      //    (backfills phone, age, languages — remove once you have a real API)
      final cognitoUser = await service.getCurrentUser();
      final knownEmployee = mockUsers.where(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      ).firstOrNull;

      final resolved = RestaurantUser(
        employeeId: cognitoUser?.userId ?? email,
        name:       knownEmployee?.name ?? name,
        username:   email.split('@').first,
        mobileNumber: knownEmployee?.mobileNumber ?? '',
        email:      email,
        designation: role.displayName,
        role:       role,          // ← always from Cognito group
        photoUrl:   claims.picture ?? knownEmployee?.photoUrl ?? '',
        age:        knownEmployee?.age ?? 0,
        languagesSpoken: knownEmployee?.languagesSpoken ?? [],
        metadata:   {'cognito_groups': claims.groups.join(',')},
      );

      _log.info('RestaurantUser resolved → ${resolved.name} | ${resolved.role.name}');
      ref.read(currentUserProvider.notifier).state = resolved;

      if (!mounted) return;
      context.go('/gateway');
    } catch (e, st) {
      _log.error('_signInWithGoogle failed', e, st);
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final raw = e.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('cancelled') || lower.contains('usercancelled')) {
      return 'Sign-in cancelled.';
    }
    if (lower.contains('network') || lower.contains('socketexception')) {
      return 'Network error. Check your connection.';
    }
    // Show the raw Amplify error so we can diagnose it
    return raw;
  }

  // ── Sign-out (for sign-in page if Amplify state is stale) ──────────
  Future<void> _signOut() async {
    try {
      await ref.read(amplifyAuthServiceProvider).signOut();
      ref.read(currentUserProvider.notifier).state = null;
    } catch (_) {}
  }

  // ── Build ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // ── Branding ─────────────────────────────────────────
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Welcome to\nBLR Brew Bam',
                  style: GoogleFonts.outfit(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  'Sign in to manage your restaurant\nor browse our menu.',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                // ── Error banner ─────────────────────────────────────
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      border:
                          Border.all(color: AppColors.error.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.error, size: 16),
                          onPressed: () =>
                              setState(() => _errorMessage = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Google sign-in button ─────────────────────────────
                _GoogleSignInButton(
                  isLoading: _isLoading,
                  onPressed: _signInWithGoogle,
                ),
                const SizedBox(height: 14),

                // ── Terms note ────────────────────────────────────────
                Center(
                  child: Text(
                    'By continuing you agree to our Terms of Service\nand Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Google Sign-In Button ──────────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 2,
          shadowColor: Colors.black12,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" logo via SVG-equivalent
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

// Minimal hand-drawn Google "G" mark (four coloured quadrants)
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cx;

    const colors = [
      Color(0xFF4285F4), // blue   – right
      Color(0xFF34A853), // green  – bottom
      Color(0xFFFBBC05), // yellow – bottom-left
      Color(0xFFEA4335), // red    – top-left
    ];
    const sweeps = [90.0, 90.0, 90.0, 90.0];
    const starts = [-90.0, 0.0, 90.0, 180.0];

    for (var i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.4;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.8),
        _toRad(starts[i]),
        _toRad(sweeps[i]),
        false,
        paint,
      );
    }

    // White cut-out bar (the cross of the G)
    final barPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = r * 0.4;
    canvas.drawLine(
      Offset(cx + r * 0.2, cy),
      Offset(cx + r * 0.9, cy),
      barPaint,
    );
  }

  double _toRad(double deg) => deg * 3.14159265 / 180.0;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

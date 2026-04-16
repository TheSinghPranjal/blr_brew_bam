import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';

class GatewayPage extends ConsumerWidget {
  const GatewayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gradientStart, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Greeting
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage(user.photoUrl),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user.name.split(' ').first}! 👋',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            user.designation,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                     TextButton.icon(
                       onPressed: () async {
                         try {
                           await ref
                               .read(amplifyAuthServiceProvider)
                               .signOut();
                         } catch (_) {}
                         ref.read(currentUserProvider.notifier).state = null;
                         if (context.mounted) context.go('/login');
                       },
                       icon: const Icon(Icons.logout_rounded, size: 18),
                       label: const Text('Logout'),
                     ),
                  ],
                ),
                const SizedBox(height: 48),
                Text(
                  'Dive deep as?',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to experience the app today.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // ── Customer Card ─────────────────────────────────────
                _GatewayCard(
                  title: 'Customer',
                  subtitle: 'Browse menu, order food & drinks',
                  icon: Icons.shopping_bag_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  ),
                  onTap: () => context.go('/customer'),
                ),
                const SizedBox(height: 16),

                // ── Restaurant Card ───────────────────────────────────
                _GatewayCard(
                  title: 'Restaurant',
                  subtitle: 'Manage operations, staff & catalogue',
                  icon: Icons.storefront_outlined,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  onTap: () => context.go('/restaurant'),
                ),
                const SizedBox(height: 16),

                // ── Field Agent Card ──────────────────────────────────
                _GatewayCard(
                  title: 'Field Agent',
                  subtitle: 'Onboard & manage restaurant partners',
                  icon: Icons.badge_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                  ),
                  onTap: () => context.go('/field-agent'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GatewayCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _GatewayCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 36, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

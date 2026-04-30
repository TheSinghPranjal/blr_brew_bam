import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/providers.dart';
import '../../../domain/models.dart';
import '../../shared/widgets.dart';
import 'category_management.dart';
import 'product_management.dart';

class ManagerDashboard extends ConsumerWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || !user.role.isManagerOrAbove) {
      return const UnauthorizedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/gateway'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(currentUserProvider.notifier).state = null;
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(user.photoUrl),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user.name.split(' ').first}!',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        user.designation,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                DashboardActionCard(
                  label: 'Add Category',
                  icon: Icons.category_outlined,
                  color: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryManagementScreen(),
                    ),
                  ),
                ),
                DashboardActionCard(
                  label: 'Add Product',
                  icon: Icons.fastfood_outlined,
                  color: const Color(0xFFF59E0B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductManagementScreen(),
                    ),
                  ),
                ),
                DashboardActionCard(
                  label: 'Add Notification',
                  icon: Icons.notifications_outlined,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    _comingSoonSnack('Notifications'),
                  ),
                ),
                DashboardActionCard(
                  label: 'Add Event',
                  icon: Icons.event_outlined,
                  color: const Color(0xFF0EA5E9),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    _comingSoonSnack('Events'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SnackBar _comingSoonSnack(String name) => SnackBar(
        content: Text('$name module coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
}

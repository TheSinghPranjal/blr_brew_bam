import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../domain/models.dart';

// ── Slide-from-right page transition ─────────────────────────────────────
Route<void> customerProfileRoute() {
  return PageRouteBuilder<void>(
    pageBuilder: (context, animation, secondaryAnimation) =>
        const CustomerProfileScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;
      final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 320),
  );
}

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    void handleLogout() {
      ref.read(currentUserProvider.notifier).logout();
      context.go('/login');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: CustomScrollView(
        slivers: [
          _ProfileAppBar(user: user),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 12),
                _QuickActionsGrid(),
                const SizedBox(height: 12),
                _MenuSection(onLogout: handleLogout),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── App Bar + Hero Header ─────────────────────────────────────────────────
class _ProfileAppBar extends StatelessWidget {
  final RestaurantUser user;
  const _ProfileAppBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFFFAEDE4),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          ),
          child: Text(
            'Help',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded,
              color: Color(0xFF1A1A1A)),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: const Color(0xFFFAEDE4),
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 18),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+91 – ${user.mobileNumber}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Actions Grid ────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  static const _actions = [
    _QuickAction(
        icon: Icons.location_on_outlined, label: 'Saved\nAddress'),
    _QuickAction(
        icon: Icons.payment_outlined, label: 'Payment\nModes'),
    _QuickAction(
        icon: Icons.assignment_return_outlined, label: 'My\nRefunds'),
    _QuickAction(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Brew\nWallet'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: _actions
            .map((a) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _QuickActionTile(action: a),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  const _QuickAction({required this.icon, required this.label});
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 24, color: const Color(0xFF1A1A1A)),
            const SizedBox(height: 6),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Menu Section ──────────────────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  final VoidCallback onLogout;
  const _MenuSection({required this.onLogout});

  static const _menuItems = [
    _MenuItem(icon: Icons.card_membership_outlined, label: 'Membership & Benefits'),
    _MenuItem(icon: Icons.confirmation_num_outlined, label: 'My Vouchers'),
    _MenuItem(icon: Icons.receipt_long_outlined, label: 'Order History'),
    _MenuItem(icon: Icons.favorite_border_rounded, label: 'Favourites'),
    _MenuItem(icon: Icons.star_border_rounded, label: 'Loyalty Points'),
    _MenuItem(icon: Icons.help_outline_rounded, label: 'Help & Support'),
    _MenuItem(icon: Icons.settings_outlined, label: 'Account Settings'),
    _MenuItem(icon: Icons.shield_outlined, label: 'Privacy Policy'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ..._menuItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _MenuTile(item: item),
                if (i < _menuItems.length - 1)
                  const Divider(height: 1, indent: 52),
              ],
            );
          }),
          const Divider(height: 1),
          // Logout at the bottom
          _MenuTile(
            item: const _MenuItem(
                icon: Icons.logout_rounded, label: 'Log Out', isDestructive: true),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final bool isDestructive;
  const _MenuItem(
      {required this.icon, required this.label, this.isDestructive = false});
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback? onTap;
  const _MenuTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = item.isDestructive ? AppColors.error : const Color(0xFF1A1A1A);
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, size: 22, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: item.isDestructive
                    ? AppColors.error.withValues(alpha: 0.6)
                    : const Color(0xFFAAAAAA),
                size: 20),
          ],
        ),
      ),
    );
  }
}

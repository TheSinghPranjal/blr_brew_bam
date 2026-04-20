import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/providers.dart';
import '../../../domain/models.dart';
import '../../shared/widgets.dart';
import '../manager/manager_dashboard.dart';

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final allUsers = ref.watch(mutableUsersProvider);

    // RBAC Guard
    if (user == null || !user.role.isSuperAdmin) {
      return const UnauthorizedScreen();
    }

    final filtered = allUsers
        .where((u) =>
            u.name.toLowerCase().contains(_query) ||
            u.username.toLowerCase().contains(_query) ||
            u.employeeId.toLowerCase().contains(_query) ||
            u.designation.toLowerCase().contains(_query))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/gateway'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildProfileButton(user),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search ────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${allUsers.length} Team Members',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                AppSearchBar(
                  hint: 'Search name, ID, designation…',
                  onChanged: (v) =>
                      setState(() => _query = v.toLowerCase()),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── User List ─────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    message: 'No users found',
                    subMessage: 'Try a different search term',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, i) =>
                        _UserCard(user: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Profile / switcher button ─────────────────────────────────────────
  Widget _buildProfileButton(RestaurantUser user) {
    return GestureDetector(
      onTap: () => _showDashboardSwitcher(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(user.photoUrl),
          ),
          // Small swap indicator
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.swap_horiz_rounded,
                  size: 7, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDashboardSwitcher() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DashboardSwitcherSheet(
        currentRole: ref.read(currentUserProvider)!.role,
        onSwitch: (role) {
          Navigator.of(context).pop(); // close sheet
          _navigateToDashboard(role);
        },
      ),
    );
  }

  void _navigateToDashboard(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        break; // already here
      case UserRole.manager:
        // ManagerDashboard passes the isManagerOrAbove guard for superAdmin
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ManagerDashboard()),
        );
      case UserRole.headChef:
        _pushPreview(
          'Head Chef Dashboard',
          Icons.soup_kitchen_outlined,
          'Head Chef',
        );
      case UserRole.chef:
        _pushPreview(
          'Chef Dashboard',
          Icons.restaurant_outlined,
          'Chef',
        );
      case UserRole.kitchen:
        _pushPreview(
          'Kitchen Dashboard',
          Icons.countertops_outlined,
          'Kitchen',
        );
      default:
        break;
    }
  }

  void _pushPreview(String label, IconData icon, String role) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _RolePreviewScreen(
          roleLabel: label,
          icon: icon,
          role: role,
        ),
      ),
    );
  }
}

// ── User Card ──────────────────────────────────────────────────────────────
class _UserCard extends ConsumerWidget {
  final RestaurantUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _openRoleSheet(context, ref),
      child: Row(
        children: [
          UserAvatar(url: user.photoUrl, radius: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.designation,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      user.employeeId,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    RoleChip(label: user.role.displayName),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined,
              size: 20, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  void _openRoleSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoleAssignSheet(user: user, ref: ref),
    );
  }
}

// ── Role Assignment Bottom Sheet ───────────────────────────────────────────
class _RoleAssignSheet extends StatefulWidget {
  final RestaurantUser user;
  final WidgetRef ref;
  const _RoleAssignSheet({required this.user, required this.ref});

  @override
  State<_RoleAssignSheet> createState() => _RoleAssignSheetState();
}

class _RoleAssignSheetState extends State<_RoleAssignSheet> {
  late UserRole _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                UserAvatar(url: widget.user.photoUrl, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Assign a role',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // Role list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: UserRole.values.length,
              itemBuilder: (ctx, i) {
                final role = UserRole.values[i];
                final isSelected = role == _selected;
                return ListTile(
                  title: Text(
                    role.displayName,
                    style: GoogleFonts.outfit(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : const Icon(Icons.radio_button_unchecked_rounded,
                          color: AppColors.border),
                  onTap: () => setState(() => _selected = role),
                );
              },
            ),
          ),

          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).viewPadding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.ref
                      .read(mutableUsersProvider.notifier)
                      .reassignRole(widget.user.employeeId, _selected);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Assigned ${_selected.displayName} to ${widget.user.name}',
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: const Text('Save Role'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Switcher Bottom Sheet ────────────────────────────────────────
class _DashboardSwitcherSheet extends StatelessWidget {
  final UserRole currentRole;
  final ValueChanged<UserRole> onSwitch;

  const _DashboardSwitcherSheet({
    required this.currentRole,
    required this.onSwitch,
  });

  static final _options = [
    _SwitcherOption(
      role: UserRole.superAdmin,
      label: 'Super Admin',
      subtitle: 'Users, roles & system settings',
      icon: Icons.admin_panel_settings_outlined,
      colors: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    ),
    _SwitcherOption(
      role: UserRole.manager,
      label: 'Manager',
      subtitle: 'Categories, products & events',
      icon: Icons.manage_accounts_outlined,
      colors: const [Color(0xFF0D9488), Color(0xFF0F766E)],
    ),
    _SwitcherOption(
      role: UserRole.headChef,
      label: 'Head Chef',
      subtitle: 'Kitchen orders & recipe queue',
      icon: Icons.soup_kitchen_outlined,
      colors: const [Color(0xFFD97706), Color(0xFFB45309)],
    ),
    _SwitcherOption(
      role: UserRole.chef,
      label: 'Chef',
      subtitle: 'Assigned orders & prep status',
      icon: Icons.restaurant_outlined,
      colors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
    ),
    _SwitcherOption(
      role: UserRole.kitchen,
      label: 'Kitchen',
      subtitle: 'Live order tickets & dispatch',
      icon: Icons.countertops_outlined,
      colors: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gradientStart,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Switch Dashboard',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Preview any role\'s interface',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Role option rows
            ..._options.map((opt) {
              final isCurrent = opt.role == currentRole;
              return InkWell(
                onTap: isCurrent ? null : () => onSwitch(opt.role),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Gradient icon badge
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCurrent
                                ? [AppColors.border, AppColors.border]
                                : opt.colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          opt.icon,
                          color: isCurrent
                              ? AppColors.textSecondary
                              : Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  opt.label,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isCurrent
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Current',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt.subtitle,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isCurrent)
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Simple data class for switcher options (avoids record literal const issues)
class _SwitcherOption {
  final UserRole role;
  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  const _SwitcherOption({
    required this.role,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });
}

// ── Role Preview Screen ────────────────────────────────────────────────────
// Shown when super admin previews chef / kitchen dashboards (under construction)
class _RolePreviewScreen extends StatelessWidget {
  final String roleLabel;
  final IconData icon;
  final String role;
  const _RolePreviewScreen({
    required this.roleLabel,
    required this.icon,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(roleLabel),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Preview mode badge
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_outlined,
                    size: 13, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  'Preview Mode',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppColors.gradientStart,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                '$role Dashboard',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This interface is under construction.\nComing soon!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

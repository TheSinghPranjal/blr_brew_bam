import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/providers.dart';
import '../../../domain/models.dart';
import '../../shared/widgets.dart';

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
            child: _buildCurrentUserAvatar(user),
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
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, i) =>
                        _UserCard(user: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserAvatar(RestaurantUser user) {
    return GestureDetector(
      onTap: () {
        ref.read(currentUserProvider.notifier).state = null;
        context.go('/login');
      },
      child: Row(
        children: [
          Text(
            'Logout',
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(user.photoUrl),
          ),
        ],
      ),
    );
  }
}

// ── User Card ──────────────────────────────────────────────────────────
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

// ── Role Assignment Bottom Sheet ──────────────────────────────────────
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

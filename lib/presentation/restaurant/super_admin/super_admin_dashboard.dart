import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/providers.dart';
import '../../../data/team_providers.dart';
import '../../../domain/models.dart';
import '../../../domain/team_models.dart';
import '../../shared/widgets.dart';
import '../manager/manager_dashboard.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Super Admin Dashboard  –  Tabbed Layout
// ═══════════════════════════════════════════════════════════════════════════

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  static const _tabLabels = ['Team', 'Categories', 'Events', 'Finances', 'Manage'];
  static const _tabIcons = [
    Icons.people_alt_outlined,
    Icons.category_outlined,
    Icons.event_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.settings_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabLabels.length, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null || !user.role.isSuperAdmin) {
      return const UnauthorizedScreen();
    }

    // Seed default team categories once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(teamCategoryProvider.notifier)
          .seedDefaults(user.employeeId); // use employeeId as restaurantId stub
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(user),
      body: TabBarView(
        controller: _tabs,
        children: [
          _TeamTab(restaurantId: user.employeeId),
          _TeamCategoryTab(restaurantId: user.employeeId),
          const _PlaceholderTab(icon: Icons.event_outlined, label: 'Events'),
          const _PlaceholderTab(
              icon: Icons.account_balance_wallet_outlined, label: 'Finances'),
          _ManageTab(user: user),
        ],
      ),
    );
  }

  AppBar _buildAppBar(RestaurantUser user) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.go('/gateway'),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Super Admin',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary),
          ),
          Text(
            user.name,
            style: GoogleFonts.outfit(
                fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildProfileButton(user),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: _buildTabBar(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _tabLabels.length,
        itemBuilder: (ctx, i) {
          final selected = _tabs.index == i;
          return GestureDetector(
            onTap: () => _tabs.animateTo(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _tabIcons[i],
                    size: 13,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _tabLabels[i],
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileButton(RestaurantUser user) {
    return GestureDetector(
      onTap: () => _showDashboardSwitcher(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(user.photoUrl),
            backgroundColor: AppColors.gradientStart,
          ),
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
          Navigator.of(context).pop();
          _navigateToDashboard(role);
        },
      ),
    );
  }

  void _navigateToDashboard(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        break;
      case UserRole.manager:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ManagerDashboard()),
        );
      case UserRole.headChef:
        _pushPreview('Head Chef Dashboard', Icons.soup_kitchen_outlined, 'Head Chef');
      case UserRole.chef:
        _pushPreview('Chef Dashboard', Icons.restaurant_outlined, 'Chef');
      case UserRole.kitchen:
        _pushPreview('Kitchen Dashboard', Icons.countertops_outlined, 'Kitchen');
      default:
        break;
    }
  }

  void _pushPreview(String label, IconData icon, String role) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _RolePreviewScreen(roleLabel: label, icon: icon, role: role),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TAB 1 – Team
// ═══════════════════════════════════════════════════════════════════════════

class _TeamTab extends ConsumerWidget {
  final String restaurantId;
  const _TeamTab({required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(teamMemberProvider);
    final categories = ref.watch(teamCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: members.isEmpty
          ? _TeamEmptyState(
              onAdd: () => _showAddMemberSheet(context, ref, categories),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: members.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _TeamMemberCard(
                member: members[i],
                onRemove: () =>
                    ref.read(teamMemberProvider.notifier).remove(members[i].id),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: categories.isEmpty
            ? null
            : () => _showAddMemberSheet(context, ref, categories),
        backgroundColor:
        categories.isEmpty ? AppColors.border : AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }
  

  void _showAddMemberSheet(
    BuildContext context,
    WidgetRef ref,
    List<TeamCategory> categories,
  ) {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Create at least one team category before adding members.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMemberSheet(
        restaurantId: restaurantId,
        categories: categories,
        onAdd: (member) {
          ref.read(teamMemberProvider.notifier).add(member);
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Invite sent to ${member.email}',
                  style: GoogleFonts.outfit(color: Colors.white)),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────
class _TeamEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _TeamEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                  color: AppColors.gradientStart, shape: BoxShape.circle),
              child: const Icon(Icons.people_alt_outlined,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('No team members yet',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Add your first member by tapping the\nbutton below.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member card ────────────────────────────────────────────────────────────
class _TeamMemberCard extends StatelessWidget {
  final TeamMember member;
  final VoidCallback onRemove;
  const _TeamMemberCard({required this.member, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar with initials
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              member.email[0].toUpperCase(),
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.email,
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        member.teamCategoryName,
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (member.isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Invite Pending',
                          style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmRemove(context),
            icon: const Icon(Icons.remove_circle_outline_rounded,
                color: AppColors.error, size: 20),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Member?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Remove ${member.email} from the team?',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRemove();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ── Add Member Bottom Sheet ────────────────────────────────────────────────
class _AddMemberSheet extends StatefulWidget {
  final String restaurantId;
  final List<TeamCategory> categories;
  final ValueChanged<TeamMember> onAdd;
  const _AddMemberSheet({
    required this.restaurantId,
    required this.categories,
    required this.onAdd,
  });

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  TeamCategory? _selectedCategory;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.categories.isNotEmpty ? widget.categories.first : null;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.gradientStart,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Add Team Member',
                  style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Email field
            _FieldLabel(label: 'Email Address', required: true),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. john@restaurant.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (!_submitted) return null;
                if (v == null || v.trim().isEmpty) return 'Email is required';
                final reg = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
                if (!reg.hasMatch(v.trim())) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category picker
            _FieldLabel(label: 'Team Category', required: true),
            const SizedBox(height: 6),
            DropdownButtonFormField<TeamCategory>(
              value: _selectedCategory,
              onChanged: (v) => setState(() => _selectedCategory = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              borderRadius: BorderRadius.circular(12),
              items: widget.categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Text(c.emoji,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(c.name,
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  'Send Invite',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return;

    widget.onAdd(createTeamMember(
      email: _emailCtrl.text,
      restaurantId: widget.restaurantId,
      category: _selectedCategory!,
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TAB 2 – Team Categories
// ═══════════════════════════════════════════════════════════════════════════

class _TeamCategoryTab extends ConsumerWidget {
  final String restaurantId;
  const _TeamCategoryTab({required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(teamCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: categories.isEmpty
          ? _CategoryEmptyState(
              onAdd: () =>
                  _showAddCategorySheet(context, ref, restaurantId))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: categories.length,
              itemBuilder: (ctx, i) => _CategoryCard(
                category: categories[i],
                onDelete: () => ref
                    .read(teamCategoryProvider.notifier)
                    .remove(categories[i].id),
                onEdit: () => _showEditCategorySheet(
                    context, ref, categories[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategorySheet(context, ref, restaurantId),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('New Category',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
    );
  }

  static void _showAddCategorySheet(
      BuildContext context, WidgetRef ref, String restaurantId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryFormSheet(
        restaurantId: restaurantId,
        onSave: (name, emoji) {
          ref.read(teamCategoryProvider.notifier).add(
                createCategory(
                    name: name, restaurantId: restaurantId, emoji: emoji),
              );
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "$name" created',
                  style: GoogleFonts.outfit(color: Colors.white)),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  static void _showEditCategorySheet(
      BuildContext context, WidgetRef ref, TeamCategory category) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryFormSheet(
        restaurantId: category.restaurantId,
        existingName: category.name,
        existingEmoji: category.emoji,
        onSave: (name, emoji) {
          ref
              .read(teamCategoryProvider.notifier)
              .rename(category.id, name, emoji);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

// ── Category Empty State ───────────────────────────────────────────────────
class _CategoryEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _CategoryEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                  color: AppColors.gradientStart, shape: BoxShape.circle),
              child: const Icon(Icons.category_outlined,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('No categories yet',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Create team categories like Waiters,\nCooks, Bartenders etc.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Category'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Card ──────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final TeamCategory category;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _CategoryCard(
      {required this.category,
      required this.onDelete,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.gradientStart,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(category.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 15, color: AppColors.error),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              category.name,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              '${category.memberCount} member${category.memberCount == 1 ? '' : 's'}',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Category?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Delete "${category.name}"? Members in this category will also need to be reassigned.',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Category Form Sheet ────────────────────────────────────────────────────
class _CategoryFormSheet extends StatefulWidget {
  final String restaurantId;
  final String? existingName;
  final String? existingEmoji;
  final void Function(String name, String emoji) onSave;

  const _CategoryFormSheet({
    required this.restaurantId,
    this.existingName,
    this.existingEmoji,
    required this.onSave,
  });

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _nameCtrl = TextEditingController();
  late String _selectedEmoji;
  bool _submitted = false;

  static const _emojiOptions = [
    '👥', '🍽️', '👨‍🍳', '🍺', '🤝', '🧹', '📦', '🎂', '🍸', '🔧',
    '🛎️', '🎵', '🚀', '💼', '🌟',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.existingName ?? '';
    _selectedEmoji = widget.existingEmoji ?? '👥';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingName != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.gradientStart,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(_selectedEmoji,
                    style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Edit Category' : 'New Team Category',
                style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Emoji picker
          Text('Pick an Icon',
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _emojiOptions.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 6),
              itemBuilder: (ctx, i) {
                final e = _emojiOptions[i];
                final sel = e == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? AppColors.primary : AppColors.border,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Center(
                        child: Text(e,
                            style: const TextStyle(fontSize: 22))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Name
          _FieldLabel(label: 'Category Name', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'e.g. Waiters, Cooks, Bakers…',
              prefixIcon: const Icon(Icons.label_outline_rounded),
              errorText: (_submitted && _nameCtrl.text.trim().isEmpty)
                  ? 'Category name is required'
                  : null,
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(isEdit ? Icons.check_rounded : Icons.add_rounded,
                  size: 18),
              label: Text(
                isEdit ? 'Save Changes' : 'Create Category',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    setState(() => _submitted = true);
    if (_nameCtrl.text.trim().isEmpty) return;
    widget.onSave(_nameCtrl.text.trim(), _selectedEmoji);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TAB 3,4 – Placeholder
// ═══════════════════════════════════════════════════════════════════════════

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
                color: AppColors.gradientStart, shape: BoxShape.circle),
            child: Icon(icon, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('$label Coming Soon',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('This section is under development.',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TAB 5 – Manage (users + role assign, previously the whole screen)
// ═══════════════════════════════════════════════════════════════════════════

class _ManageTab extends ConsumerStatefulWidget {
  final RestaurantUser user;
  const _ManageTab({required this.user});

  @override
  ConsumerState<_ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends ConsumerState<_ManageTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allUsers = ref.watch(mutableUsersProvider);
    final filtered = allUsers
        .where((u) =>
            u.name.toLowerCase().contains(_query) ||
            u.username.toLowerCase().contains(_query) ||
            u.employeeId.toLowerCase().contains(_query) ||
            u.designation.toLowerCase().contains(_query))
        .toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${allUsers.length} Team Members',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              AppSearchBar(
                hint: 'Search name, ID, designation…',
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  message: 'No users found',
                  subMessage: 'Try a different search term')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) =>
                      const SizedBox(height: 10),
                  itemBuilder: (ctx, i) =>
                      _UserCard(user: filtered[i]),
                ),
        ),
      ],
    );
  }
}

// ── User Card (from original, unchanged) ──────────────────────────────────
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
                Text(user.name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(user.designation,
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(user.employeeId,
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: AppColors.textSecondary)),
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

// ── Role Assign Sheet (unchanged logic) ───────────────────────────────────
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
                  borderRadius: BorderRadius.circular(2))),
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
                      Text(widget.user.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('Assign a role',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: UserRole.values.length,
              itemBuilder: (ctx, i) {
                final role = UserRole.values[i];
                final isSel = role == _selected;
                return ListTile(
                  title: Text(role.displayName,
                      style: GoogleFonts.outfit(
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w400,
                          color: isSel
                              ? AppColors.primary
                              : AppColors.textPrimary)),
                  trailing: isSel
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Assigned ${_selected.displayName} to ${widget.user.name}'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ));
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

// ═══════════════════════════════════════════════════════════════════════════
//  Dashboard Switcher Sheet
// ═══════════════════════════════════════════════════════════════════════════

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

class _DashboardSwitcherSheet extends StatelessWidget {
  final UserRole currentRole;
  final ValueChanged<UserRole> onSwitch;
  const _DashboardSwitcherSheet(
      {required this.currentRole, required this.onSwitch});

  static final _options = [
    _SwitcherOption(
      role: UserRole.superAdmin, label: 'Super Admin',
      subtitle: 'Users, roles & system settings',
      icon: Icons.admin_panel_settings_outlined,
      colors: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    ),
    _SwitcherOption(
      role: UserRole.manager, label: 'Manager',
      subtitle: 'Categories, products & events',
      icon: Icons.manage_accounts_outlined,
      colors: const [Color(0xFF0D9488), Color(0xFF0F766E)],
    ),
    _SwitcherOption(
      role: UserRole.headChef, label: 'Head Chef',
      subtitle: 'Kitchen orders & recipe queue',
      icon: Icons.soup_kitchen_outlined,
      colors: const [Color(0xFFD97706), Color(0xFFB45309)],
    ),
    _SwitcherOption(
      role: UserRole.chef, label: 'Chef',
      subtitle: 'Assigned orders & prep status',
      icon: Icons.restaurant_outlined,
      colors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
    ),
    _SwitcherOption(
      role: UserRole.kitchen, label: 'Kitchen',
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
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.gradientStart,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.swap_horiz_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Switch Dashboard',
                          style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text('Preview any role\'s interface',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ..._options.map((opt) {
              final isCurrent = opt.role == currentRole;
              return InkWell(
                onTap: isCurrent ? null : () => onSwitch(opt.role),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
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
                        child: Icon(opt.icon,
                            color: isCurrent
                                ? AppColors.textSecondary
                                : Colors.white,
                            size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(opt.label,
                                    style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isCurrent
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary)),
                                if (isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text('Current',
                                        style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(opt.subtitle,
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
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

// ═══════════════════════════════════════════════════════════════════════════
//  Role Preview Screen
// ═══════════════════════════════════════════════════════════════════════════

class _RolePreviewScreen extends StatelessWidget {
  final String roleLabel;
  final IconData icon;
  final String role;
  const _RolePreviewScreen(
      {required this.roleLabel, required this.icon, required this.role});

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
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_outlined,
                    size: 13, color: AppColors.warning),
                const SizedBox(width: 4),
                Text('Preview Mode',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning)),
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
                    color: AppColors.gradientStart, shape: BoxShape.circle),
                child: Icon(icon, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text('$role Dashboard',
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('This interface is under construction.\nComing soon!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small helper widget ────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        if (required) ...[
          const SizedBox(width: 3),
          const Text('*',
              style: TextStyle(color: AppColors.error, fontSize: 13)),
        ],
      ],
    );
  }
}

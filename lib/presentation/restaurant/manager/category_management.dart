import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme.dart';
import '../../../data/providers.dart';
import '../../../domain/category_model.dart';
import '../../shared/widgets.dart';

const _uuid = Uuid();

// ── Colour palette for cards ───────────────────────────────────────────
const _cardPalette = [
  Color(0xFF0D9488), // teal
  Color(0xFF0EA5E9), // sky
  Color(0xFF8B5CF6), // violet
  Color(0xFFF59E0B), // amber
  Color(0xFFEC4899), // pink
  Color(0xFF10B981), // emerald
  Color(0xFFEF4444), // red
  Color(0xFF6366F1), // indigo
];

Color _cardColor(int index) => _cardPalette[index % _cardPalette.length];

// ══════════════════════════════════════════════════════════════════════
//  Main Screen
// ══════════════════════════════════════════════════════════════════════
class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(apiCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(apiCategoriesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _SearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 10),

          // ── Body ───────────────────────────────────────────────────
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorView(
                message: err.toString().replaceFirst('Exception: ', ''),
                onRetry: () =>
                    ref.read(apiCategoriesProvider.notifier).refresh(),
              ),
              data: (categories) {
                final filtered = _query.isEmpty
                    ? categories
                    : categories
                        .where((c) =>
                            c.categoryName
                                .toLowerCase()
                                .contains(_query) ||
                            c.subcategories.any((s) =>
                                s.toLowerCase().contains(_query)))
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: _query.isEmpty
                        ? Icons.category_outlined
                        : Icons.search_off_rounded,
                    message: _query.isEmpty
                        ? 'No categories yet'
                        : 'No results for "$_query"',
                    subMessage: _query.isEmpty
                        ? 'Tap + to add your first category'
                        : null,
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(apiCategoriesProvider.notifier).refresh(),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _CategoryCard(
                      category: filtered[i],
                      colorIndex: i,
                      onTap: () =>
                          _openDetail(context, filtered[i], i),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
       floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context),
    child: const Icon(Icons.add_rounded),
    ),
    );
  }

  void _openDetail(
      BuildContext context, ApiCategory category, int colorIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryDetailSheet(
        category: category,
        colorIndex: colorIndex,
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    final count = ref.read(apiCategoriesProvider).valueOrNull?.length ?? 0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(nextDisplayOrder: count + 1),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Search Bar
// ══════════════════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.outfit(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search categories or sub-categories…',
          hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textSecondary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Category Card
// ══════════════════════════════════════════════════════════════════════
class _CategoryCard extends StatelessWidget {
  final ApiCategory category;
  final int colorIndex;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.colorIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _cardColor(colorIndex);
    final isImageValid = category.image.startsWith('http') &&
        !category.image.contains('example.com');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image / Gradient Header ──────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: isImageValid
                    ? Image.network(
                        category.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _GradientPlaceholder(color: accent),
                      )
                    : _GradientPlaceholder(color: accent),
              ),
            ),

            // ── Info ─────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      category.categoryName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Tags row
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (category.isVegetarian)
                          _MiniTag(
                              label: 'Veg',
                              color: AppColors.success),
                        if (category.isCocktail)
                          _MiniTag(
                              label: 'Cocktail',
                              color: const Color(0xFF8B5CF6)),
                        if (category.isMocktail)
                          _MiniTag(
                              label: 'Mocktail',
                              color: const Color(0xFF0EA5E9)),
                        if (!category.isActive)
                          _MiniTag(
                              label: 'Inactive',
                              color: AppColors.error),
                      ],
                    ),
                    const Spacer(),

                    // Sub-categories count
                    if (category.hasSubcategory &&
                        category.subcategories.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.account_tree_outlined,
                              size: 12, color: accent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${category.subcategories.length} sub-categor${category.subcategories.length == 1 ? 'y' : 'ies'}',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  final Color color;
  const _GradientPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.fastfood_rounded,
            size: 40, color: Colors.white.withOpacity(0.85)),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Category Detail Sheet
// ══════════════════════════════════════════════════════════════════════
class _CategoryDetailSheet extends ConsumerWidget {
  final ApiCategory category;
  final int colorIndex;

  const _CategoryDetailSheet({
    required this.category,
    required this.colorIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _cardColor(colorIndex);
    final isImageValid = category.image.startsWith('http') &&
        !category.image.contains('example.com');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Image ─────────────────────────────────────
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24)),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: isImageValid
                            ? Image.network(
                                category.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _GradientPlaceholder(color: accent),
                              )
                            : _GradientPlaceholder(color: accent),
                      ),
                    ),
                    // Close + Edit buttons
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Row(
                        children: [
                          _CircleAction(
                            icon: Icons.edit_outlined,
                            onTap: () {
                              Navigator.pop(context);
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _CategoryFormSheet(
                                  existing: category,
                                  nextDisplayOrder:
                                      category.displayOrder,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _CircleAction(
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Active/Inactive badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: category.isActive
                              ? AppColors.success
                              : AppColors.error,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category.isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        category.categoryName,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${category.categoryId}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Attribute chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DetailChip(
                            icon: Icons.eco_rounded,
                            label: category.isVegetarian
                                ? 'Vegetarian'
                                : 'Non-Vegetarian',
                            color: category.isVegetarian
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          if (category.isCocktail)
                            const _DetailChip(
                              icon: Icons.local_bar_rounded,
                              label: 'Cocktail',
                              color: Color(0xFF8B5CF6),
                            ),
                          if (category.isMocktail)
                            const _DetailChip(
                              icon: Icons.emoji_food_beverage_rounded,
                              label: 'Mocktail',
                              color: Color(0xFF0EA5E9),
                            ),
                          _DetailChip(
                            icon: Icons.sort_rounded,
                            label:
                                'Display order: ${category.displayOrder}',
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Sub-categories
                      if (category.hasSubcategory &&
                          category.subcategories.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.account_tree_outlined,
                                size: 18, color: accent),
                            const SizedBox(width: 8),
                            Text(
                              'Sub-categories',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: category.subcategories
                              .map(
                                (s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.08),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                        color:
                                            accent.withOpacity(0.25)),
                                  ),
                                  child: Text(
                                    s,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      const Divider(),
                      const SizedBox(height: 12),

                      // Edit CTA
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => _CategoryFormSheet(
                                existing: category,
                                nextDisplayOrder:
                                    category.displayOrder,
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Category'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _DetailChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Add / Edit Form Sheet
// ══════════════════════════════════════════════════════════════════════
class _CategoryFormSheet extends ConsumerStatefulWidget {
  /// null → Add mode   |   non-null → Edit mode
  final ApiCategory? existing;
  final int nextDisplayOrder;

  const _CategoryFormSheet({
    this.existing,
    required this.nextDisplayOrder,
  });

  @override
  ConsumerState<_CategoryFormSheet> createState() =>
      _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _subCtrl = TextEditingController();

  bool _isVeg = true;
  bool _isMocktail = false;
  bool _isCocktail = false;
  bool _hasSubcategory = false;
  bool _isActive = true;
  final List<String> _subcategories = [];

  bool _isLoading = false;
  String? _errorMsg;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.categoryName;
      _isVeg = e.isVegetarian;
      _isMocktail = e.isMocktail;
      _isCocktail = e.isCocktail;
      _hasSubcategory = e.hasSubcategory;
      _isActive = e.isActive;
      _subcategories.addAll(e.subcategories);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditMode
                                ? 'Edit Category'
                                : 'Add Category',
                            style:
                                Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            _isEditMode
                                ? 'Update the details below'
                                : 'A UUID will be auto-generated',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isEditMode)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Edit',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Category Name ──────────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    hintText: 'e.g. Bangalore Special Food',
                    prefixIcon:
                        Icon(Icons.label_outline_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Category name is required'
                          : null,
                ),
                const SizedBox(height: 12),

                // ── Image stub ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image_outlined,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Image upload (stub)',
                          style: GoogleFonts.outfit(
                              color: AppColors.textSecondary),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Browse'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Toggles ────────────────────────────────────────
                FormToggleRow(
                  label: 'Vegetarian',
                  value: _isVeg,
                  onChanged: (v) => setState(() => _isVeg = v),
                ),
                const SizedBox(height: 10),
                FormToggleRow(
                  label: 'Is Mocktail',
                  value: _isMocktail,
                  onChanged: (v) => setState(() => _isMocktail = v),
                ),
                const SizedBox(height: 10),
                FormToggleRow(
                  label: 'Is Cocktail',
                  value: _isCocktail,
                  onChanged: (v) => setState(() => _isCocktail = v),
                ),
                const SizedBox(height: 10),
                FormToggleRow(
                  label: 'Has Sub-categories',
                  value: _hasSubcategory,
                  onChanged: (v) =>
                      setState(() => _hasSubcategory = v),
                ),
                const SizedBox(height: 10),
                FormToggleRow(
                  label: 'Active',
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),

                // ── Sub-category chips ─────────────────────────────
                if (_hasSubcategory) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _subCtrl,
                          textCapitalization:
                              TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Sub-category name',
                            hintText: 'e.g. South Indian',
                          ),
                          onFieldSubmitted: (_) =>
                              _addSubchip(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: _addSubchip,
                        icon: const Icon(Icons.add_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (_subcategories.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _subcategories
                          .map((s) => Chip(
                                label: Text(s),
                                deleteIcon: const Icon(
                                    Icons.close, size: 14),
                                onDeleted: () => setState(
                                    () => _subcategories.remove(s)),
                              ))
                          .toList(),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add sub-categories',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],

                // ── Error banner ───────────────────────────────────
                if (_errorMsg != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Save button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditMode
                            ? 'Update Category'
                            : 'Save Category'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────
  void _addSubchip() {
    final name = _subCtrl.text.trim();
    if (name.isNotEmpty && !_subcategories.contains(name)) {
      setState(() {
        _subcategories.add(name);
        _subCtrl.clear();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hasSubcategory && _subcategories.isEmpty) {
      setState(() => _errorMsg =
          'Add at least one sub-category, or disable the toggle.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final body = {
      'category_name': _nameCtrl.text.trim(),
      'image': 'https://example.com/image.png',
      'is_vegetarian': _isVeg,
      'is_mocktail': _isMocktail,
      'is_cocktail': _isCocktail,
      'has_subcategory': _hasSubcategory,
      'subcategories': _subcategories,
      'display_order': widget.nextDisplayOrder,
      'is_active': _isActive,
    };

    try {
      final notifier = ref.read(apiCategoriesProvider.notifier);
      if (_isEditMode) {
        await notifier.updateCategory(widget.existing!.categoryId, body);
      } else {
        // Generate UUID client-side and include it
        body['category_id'] = _uuid.v4();
        await notifier.addCategory(body);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Category updated ✓'
                : '${_nameCtrl.text.trim()} saved ✓',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Error View
// ══════════════════════════════════════════════════════════════════════
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              'Failed to load categories',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

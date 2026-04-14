import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/providers.dart';
import '../../../domain/models.dart';
import '../../shared/widgets.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState
    extends ConsumerState<ProductManagementScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final products = ref.watch(productsProvider);
    final rootCats = categories.where((c) => c.parentId == null).toList();
    final hasCategories = rootCats.isNotEmpty;

    final filtered = products
        .where((p) =>
            p.name.toLowerCase().contains(_query) ||
            _categoryName(categories, p.categoryId)
                .toLowerCase()
                .contains(_query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: Column(
        children: [
          if (!hasCategories)
            _NoCategoryBanner()
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AppSearchBar(
                hint: 'Search product or category…',
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.fastfood_outlined,
                    message: 'No products yet',
                    subMessage: hasCategories
                        ? 'Tap + to add your first product'
                        : 'Add a category first',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) =>
                        _ProductCard(
                          product: filtered[i],
                          categories: categories,
                        ),
                  ),
          ),
        ],
      ),
      floatingActionButton: hasCategories
          ? FloatingActionButton(
              onPressed: () => _showProductForm(context, ref, rootCats),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  String _categoryName(List<Category> cats, String id) {
    try {
      return cats.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return '';
    }
  }

  void _showProductForm(
      BuildContext context, WidgetRef ref, List<Category> rootCats) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormSheet(rootCats: rootCats, ref: ref),
    );
  }
}

class _NoCategoryBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You must add at least one category before adding products.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product Card ───────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  final List<Category> categories;
  const _ProductCard({required this.product, required this.categories});

  String _catName(String id) {
    try {
      return categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.gradientStart,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fastfood_rounded,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.description,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    RoleChip(label: _catName(product.categoryId)),
                    const SizedBox(width: 6),
                    Text(
                      '${product.calories} kcal',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₹${product.price.toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product Form Sheet ─────────────────────────────────────────────────
class _ProductFormSheet extends StatefulWidget {
  final List<Category> rootCats;
  final WidgetRef ref;
  const _ProductFormSheet({required this.rootCats, required this.ref});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _calsCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  Category? _selectedCategory;
  Category? _selectedSubCategory;
  RestaurantUser? _selectedChef;

  List<Category> _subCats = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _calsCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allCats = widget.ref.read(categoriesProvider);
    final chefs = widget.ref
        .read(mutableUsersProvider)
        .where((u) =>
            u.role == UserRole.chef || u.role == UserRole.headChef)
        .toList();

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
                Text('Add Product',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),

                // Calories + Price
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _calsCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Calories (kcal)'),
                        validator: (v) =>
                            (v != null && v.isNotEmpty &&
                                    int.tryParse(v) == null)
                                ? 'Invalid'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Price (₹) *'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Assign Chef
                DropdownButtonFormField<RestaurantUser>(
                  decoration:
                      const InputDecoration(labelText: 'Assign Chef *'),
                  items: chefs
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${c.name} (${c.role.displayName})',
                            style: GoogleFonts.outfit(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedChef = v),
                  validator: (v) =>
                      v == null ? 'Please select a chef' : null,
                ),
                const SizedBox(height: 12),

                // Category
                DropdownButtonFormField<Category>(
                  decoration:
                      const InputDecoration(labelText: 'Category *'),
                  items: widget.rootCats
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name,
                              style: GoogleFonts.outfit(fontSize: 14)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedCategory = v;
                      _selectedSubCategory = null;
                      _subCats = v == null
                          ? []
                          : allCats
                              .where((c) => c.parentId == v.id)
                              .toList();
                    });
                  },
                  validator: (v) =>
                      v == null ? 'Please select a category' : null,
                ),
                const SizedBox(height: 12),

                // Sub-Category (optional)
                if (_subCats.isNotEmpty) ...[
                  DropdownButtonFormField<Category>(
                    decoration: const InputDecoration(
                        labelText: 'Sub-category (optional)'),
                    value: _selectedSubCategory,
                    items: _subCats
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name,
                                style: GoogleFonts.outfit(fontSize: 14)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedSubCategory = v),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save Product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChef == null || _selectedCategory == null) return;

    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      calories: int.tryParse(_calsCtrl.text) ?? 0,
      price: double.tryParse(_priceCtrl.text) ?? 0.0,
      assignedChefId: _selectedChef!.employeeId,
      categoryId: _selectedCategory!.id,
      subCategoryId: _selectedSubCategory?.id,
    );

    widget.ref.read(productsProvider.notifier).add(product);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Product "${_nameCtrl.text.trim()}" added'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

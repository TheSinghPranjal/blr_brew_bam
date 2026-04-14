import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/theme.dart';
import '../../../data/providers.dart';
import '../../../domain/models.dart';
import '../../shared/widgets.dart';

// ── API ────────────────────────────────────────────────────────────────
const _kAddCategoryUrl =
    'https://5nysoztmt8.execute-api.us-west-1.amazonaws.com/default/addCategory';

const _uuid = Uuid();

class _AddCategoryRequest {
  final String categoryName;
  final String image;
  final bool isVegetarian;
  final bool isMocktail;
  final bool isCocktail;
  final bool hasSubcategory;
  final List<String> subcategories;
  final int displayOrder;
  final bool isActive;

  _AddCategoryRequest({
    required this.categoryName,
    required this.image,
    required this.isVegetarian,
    required this.isMocktail,
    required this.isCocktail,
    required this.hasSubcategory,
    required this.subcategories,
    required this.displayOrder,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
        'category_name': categoryName,
        'image': image,
        'is_vegetarian': isVegetarian,
        'is_mocktail': isMocktail,
        'is_cocktail': isCocktail,
        'has_subcategory': hasSubcategory,
        'subcategories': subcategories,
        'display_order': displayOrder,
        'is_active': isActive,
      };
}

Future<void> _postCategory(_AddCategoryRequest req) async {
  final uri = Uri.parse(_kAddCategoryUrl);
  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(req.toJson()),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Server error ${response.statusCode}: ${response.body}',
    );
  }
}

// ── Screen ─────────────────────────────────────────────────────────────
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final roots = categories.where((c) => c.parentId == null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: roots.isEmpty
          ? const EmptyState(
              icon: Icons.category_outlined,
              message: 'No categories yet',
              subMessage: 'Tap + to add your first category',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemCount: roots.length,
              itemBuilder: (ctx, i) {
                final cat = roots[i];
                final subs = categories
                    .where((c) => c.parentId == cat.id)
                    .toList();
                return _CategoryCard(
                    category: cat, subCount: subs.length);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryForm(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showCategoryForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(ref: ref),
    );
  }
}

// ── Category Card ──────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final Category category;
  final int subCount;
  const _CategoryCard({required this.category, required this.subCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.gradientStart,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.fastfood_rounded,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _VegDot(isVeg: category.isVeg),
                if (subCount > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$subCount sub',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VegDot extends StatelessWidget {
  final bool isVeg;
  const _VegDot({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? AppColors.success : AppColors.error;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

// ── Category Form Sheet ────────────────────────────────────────────────
class _CategoryFormSheet extends StatefulWidget {
  final WidgetRef ref;
  const _CategoryFormSheet({required this.ref});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _subCtrl = TextEditingController();

  bool _isVeg = true;
  bool _isMocktail = false;
  bool _isCocktail = false;
  bool _hasSubcategory = false;

  /// Chip-based list of sub-category names
  final List<String> _subcategories = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Display order auto-increments from current category count
  int get _displayOrder =>
      widget.ref.read(categoriesProvider).length + 1;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────
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

                // Title
                Text(
                  'Add Category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'A UUID will be auto-generated for this category',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Category Name ──────────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    hintText: 'e.g. Bangalore Special Food',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Category name is required'
                          : null,
                ),
                const SizedBox(height: 12),

                // ── Image URL (stub, sent as placeholder) ─────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
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
                            color: AppColors.textSecondary,
                          ),
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

                // ── Sub-category input ─────────────────────────────
                if (_hasSubcategory) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _subCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Sub-category name',
                            hintText: 'e.g. South Indian',
                          ),
                          onFieldSubmitted: (_) => _addSubcategoryChip(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: _addSubcategoryChip,
                        icon: const Icon(Icons.add_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // Chips
                  if (_subcategories.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _subcategories
                          .map(
                            (s) => Chip(
                              label: Text(s),
                              deleteIcon: const Icon(Icons.close,
                                  size: 14),
                              onDeleted: () => setState(
                                  () => _subcategories.remove(s)),
                            ),
                          )
                          .toList(),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Add at least one sub-category',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],

                // ── Error message ──────────────────────────────────
                if (_errorMessage != null) ...[
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
                            _errorMessage!,
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

                // ── Save Button ────────────────────────────────────
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
                        : const Text('Save Category'),
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
  void _addSubcategoryChip() {
    final name = _subCtrl.text.trim();
    if (name.isNotEmpty && !_subcategories.contains(name)) {
      setState(() {
        _subcategories.add(name);
        _subCtrl.clear();
      });
    }
  }

  // ── Save: API call + local state update ───────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate sub-categories: if toggle is on, at least one required
    if (_hasSubcategory && _subcategories.isEmpty) {
      setState(() => _errorMessage =
          'Please add at least one sub-category, or disable the toggle.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Generate a v4 UUID for this category
    final categoryId = _uuid.v4();

    final request = _AddCategoryRequest(
      categoryName: _nameCtrl.text.trim(),
      image: 'https://example.com/image.png', // placeholder until real upload
      isVegetarian: _isVeg,
      isMocktail: _isMocktail,
      isCocktail: _isCocktail,
      hasSubcategory: _hasSubcategory,
      subcategories: _subcategories,
      displayOrder: _displayOrder,
      isActive: true,
    );

    try {
      // ── API call ────────────────────────────────────────────────
      await _postCategory(request);

      // ── Persist locally on success ──────────────────────────────
      final notifier = widget.ref.read(categoriesProvider.notifier);

      final cat = Category(
        id: categoryId,
        name: request.categoryName,
        isVeg: request.isVegetarian,
        isMocktail: request.isMocktail,
        isCocktail: request.isCocktail,
      );
      notifier.add(cat);

      // Add each sub-category as a child entry
      for (final subName in request.subcategories) {
        notifier.add(Category(
          id: _uuid.v4(),          // unique UUID per sub-category
          name: subName,
          isVeg: request.isVegetarian,
          parentId: categoryId,
        ));
      }

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "${request.categoryName}" saved ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }
}

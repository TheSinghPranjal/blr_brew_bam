import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/providers.dart';
import '../../../domain/models.dart';
import '../../shared/widgets.dart';

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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                return _CategoryCard(category: cat, subCount: subs.length);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryForm(context, ref, null),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showCategoryForm(
      BuildContext context, WidgetRef ref, String? parentId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _CategoryFormSheet(parentId: parentId, ref: ref),
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
                if (category.isVeg)
                  const _VegDot(isVeg: true)
                else
                  const _VegDot(isVeg: false),
                const SizedBox(width: 6),
                if (subCount > 0)
                  Text(
                    '$subCount sub',
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Category Form Sheet ────────────────────────────────────────────────
class _CategoryFormSheet extends StatefulWidget {
  final String? parentId;
  final WidgetRef ref;
  const _CategoryFormSheet({this.parentId, required this.ref});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _isVeg = true;
  bool _isMocktail = false;
  bool _isCocktail = false;
  bool _addSubCategory = false;
  final _subNameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subNameCtrl.dispose();
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
                Text(
                  widget.parentId == null
                      ? 'Add Category'
                      : 'Add Sub-Category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    hintText: 'e.g. South Indian',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Category name is required'
                      : null,
                ),
                const SizedBox(height: 12),

                // Image Upload (Stub)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image_outlined,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        'Upload Image (mock)',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Browse'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Toggles
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

                // Optional Sub-category
                if (widget.parentId == null) ...[
                  FormToggleRow(
                    label: 'Add Sub-category',
                    value: _addSubCategory,
                    onChanged: (v) => setState(() => _addSubCategory = v),
                  ),
                  if (_addSubCategory) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _subNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sub-category Name',
                        hintText: 'e.g. South Indian',
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save Category'),
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

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final cat = Category(
      id: id,
      name: _nameCtrl.text.trim(),
      isVeg: _isVeg,
      isMocktail: _isMocktail,
      isCocktail: _isCocktail,
      parentId: widget.parentId,
    );
    widget.ref.read(categoriesProvider.notifier).add(cat);

    // Auto-add sub-category if provided
    if (_addSubCategory && _subNameCtrl.text.trim().isNotEmpty) {
      final subId =
          (DateTime.now().millisecondsSinceEpoch + 1).toString();
      final sub = Category(
        id: subId,
        name: _subNameCtrl.text.trim(),
        isVeg: _isVeg,
        parentId: id,
      );
      widget.ref.read(categoriesProvider.notifier).add(sub);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category "${_nameCtrl.text.trim()}" added'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

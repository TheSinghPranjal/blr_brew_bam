import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../domain/category_model.dart';
import 'category_repository.dart';
import 'mock_data.dart';

// ── Auth / Session ─────────────────────────────────────────────────────
final currentUserProvider = StateProvider<RestaurantUser?>((ref) => null);

// ── Gateway selection ──────────────────────────────────────────────────
final gatewaySelectionProvider = StateProvider<String?>((ref) => null);

// ── Users (raw + mutable) ──────────────────────────────────────────────
final usersProvider = Provider<List<RestaurantUser>>((ref) => mockUsers);

final mutableUsersProvider =
    StateNotifierProvider<MutableUsersNotifier, List<RestaurantUser>>(
  (ref) => MutableUsersNotifier(mockUsers),
);

class MutableUsersNotifier extends StateNotifier<List<RestaurantUser>> {
  MutableUsersNotifier(List<RestaurantUser> initial) : super(initial);

  void reassignRole(String employeeId, UserRole newRole) {
    state = [
      for (final u in state)
        if (u.employeeId == employeeId) u.copyWith(role: newRole) else u,
    ];
  }
}

// ── Local Categories (used by product forms, synced from API) ──────────
final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>(
  (ref) => CategoriesNotifier(),
);

class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier() : super([]);

  void add(Category category) => state = [...state, category];
  void remove(String id) =>
      state = state.where((c) => c.id != id).toList();

  List<Category> get roots =>
      state.where((c) => c.parentId == null).toList();

  List<Category> subCategoriesOf(String parentId) =>
      state.where((c) => c.parentId == parentId).toList();
}

// ── Products ───────────────────────────────────────────────────────────
final productsProvider =
    StateNotifierProvider<ProductsNotifier, List<Product>>(
  (ref) => ProductsNotifier(),
);

class ProductsNotifier extends StateNotifier<List<Product>> {
  ProductsNotifier() : super([]);

  void add(Product product) => state = [...state, product];
  void remove(String id) =>
      state = state.where((p) => p.id != id).toList();
}

// ── Category Repository singleton ──────────────────────────────────────
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (_) => CategoryRepository(),
);

// ── API Categories (AsyncNotifier) ────────────────────────────────────
final apiCategoriesProvider =
    AsyncNotifierProvider<ApiCategoriesNotifier, List<ApiCategory>>(
  ApiCategoriesNotifier.new,
);

class ApiCategoriesNotifier extends AsyncNotifier<List<ApiCategory>> {
  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  @override
  Future<List<ApiCategory>> build() => _repo.fetchCategories();

  /// Optimistically prepend, then re-sync from server
  Future<void> addCategory(Map<String, dynamic> body) async {
    final created = await _repo.addCategory(body);
    state = AsyncData([created, ...state.valueOrNull ?? []]);
    ref.invalidateSelf();
  }

  /// Optimistic in-place update, then re-sync
  Future<void> updateCategory(String id, Map<String, dynamic> body) async {
    await _repo.updateCategory(id, body);
    state = state.whenData(
      (list) => [
        for (final c in list)
          if (c.categoryId == id)
            c.copyWith(
              categoryName: body['category_name'] as String?,
              isVegetarian: body['is_vegetarian'] as bool?,
              isMocktail: body['is_mocktail'] as bool?,
              isCocktail: body['is_cocktail'] as bool?,
              hasSubcategory: body['has_subcategory'] as bool?,
              subcategories:
                  List<String>.from(body['subcategories'] ?? []),
            )
          else
            c,
      ],
    );
  }

  /// Optimistically remove from list, call API, then re-sync
  Future<void> deleteCategory(String id) async {
    // Optimistic removal
    state = state.whenData(
      (list) => list.where((c) => c.categoryId != id).toList(),
    );
    // API call — POST with category_id in body
    await _repo.deleteCategory(id);
    // Re-sync for server-authoritative state
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

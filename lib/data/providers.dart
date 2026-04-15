import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../domain/category_model.dart';
import 'category_repository.dart';
import 'mock_data.dart';

// ══════════════════════════════════════════════════════════════════════
//  Auth / Session
//  Riverpod 3: StateProvider → NotifierProvider
// ══════════════════════════════════════════════════════════════════════
final currentUserProvider =
    NotifierProvider<CurrentUserNotifier, RestaurantUser?>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends Notifier<RestaurantUser?> {
  @override
  RestaurantUser? build() => null;
}

// ══════════════════════════════════════════════════════════════════════
//  Gateway selection  ('Customer' | 'Restaurant')
// ══════════════════════════════════════════════════════════════════════
final gatewaySelectionProvider =
    NotifierProvider<GatewayNotifier, String?>(GatewayNotifier.new);

class GatewayNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

// ══════════════════════════════════════════════════════════════════════
//  Users
// ══════════════════════════════════════════════════════════════════════
final usersProvider = Provider<List<RestaurantUser>>((ref) => mockUsers);

final mutableUsersProvider =
    NotifierProvider<MutableUsersNotifier, List<RestaurantUser>>(
  MutableUsersNotifier.new,
);

/// Riverpod 3: StateNotifier → Notifier (with build() returning initial state)
class MutableUsersNotifier extends Notifier<List<RestaurantUser>> {
  @override
  List<RestaurantUser> build() => mockUsers;

  void reassignRole(String employeeId, UserRole newRole) {
    state = [
      for (final u in state)
        if (u.employeeId == employeeId) u.copyWith(role: newRole) else u,
    ];
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Local Categories  (used by product forms, seeded from API)
// ══════════════════════════════════════════════════════════════════════
final categoriesProvider =
    NotifierProvider<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);

class CategoriesNotifier extends Notifier<List<Category>> {
  @override
  List<Category> build() => [];

  void add(Category category) => state = [...state, category];
  void remove(String id) =>
      state = state.where((c) => c.id != id).toList();

  List<Category> get roots =>
      state.where((c) => c.parentId == null).toList();

  List<Category> subCategoriesOf(String parentId) =>
      state.where((c) => c.parentId == parentId).toList();
}

// ══════════════════════════════════════════════════════════════════════
//  Products
// ══════════════════════════════════════════════════════════════════════
final productsProvider =
    NotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);

class ProductsNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() => [];

  void add(Product product) => state = [...state, product];
  void remove(String id) =>
      state = state.where((p) => p.id != id).toList();
}

// ══════════════════════════════════════════════════════════════════════
//  Category Repository  (singleton)
// ══════════════════════════════════════════════════════════════════════
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (_) => CategoryRepository(),
);

// ══════════════════════════════════════════════════════════════════════
//  API Categories  (AsyncNotifier — unchanged in Riverpod 3)
//  NOTE: AsyncValue no longer has .valueOrNull in Riverpod 3.
//        Use .asData?.value instead.
// ══════════════════════════════════════════════════════════════════════
final apiCategoriesProvider =
    AsyncNotifierProvider<ApiCategoriesNotifier, List<ApiCategory>>(
  ApiCategoriesNotifier.new,
);

class ApiCategoriesNotifier extends AsyncNotifier<List<ApiCategory>> {
  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  @override
  Future<List<ApiCategory>> build() => _repo.fetchCategories();

  /// Optimistically prepend the new category, then re-sync from server
  Future<void> addCategory(Map<String, dynamic> body) async {
    final created = await _repo.addCategory(body);
    // Riverpod 3: use .asData?.value instead of .valueOrNull
    final current = state.asData?.value ?? [];
    state = AsyncData([created, ...current]);
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

  /// Optimistic removal, then re-sync
  Future<void> deleteCategory(String id) async {
    state = state.whenData(
      (list) => list.where((c) => c.categoryId != id).toList(),
    );
    await _repo.deleteCategory(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

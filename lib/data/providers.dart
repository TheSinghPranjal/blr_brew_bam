import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import 'mock_data.dart';

// ── Raw mock data ──────────────────────────────────────────────────────
final usersProvider = Provider<List<RestaurantUser>>((ref) => mockUsers);

// ── Auth / Session ─────────────────────────────────────────────────────
final currentUserProvider = StateProvider<RestaurantUser?>((ref) => null);

// ── Gateway selection: 'Customer' | 'Restaurant' ───────────────────────
final gatewaySelectionProvider = StateProvider<String?>((ref) => null);

// ── Mutable users list (so role-reassignment persists in-session) ──────
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

// ── Categories ─────────────────────────────────────────────────────────
final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>(
  (ref) => CategoriesNotifier(),
);

class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier() : super([]);

  void add(Category category) => state = [...state, category];

  void remove(String id) =>
      state = state.where((c) => c.id != id).toList();

  /// Top-level categories only
  List<Category> get roots =>
      state.where((c) => c.parentId == null).toList();

  /// Sub-categories that belong to [parentId]
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

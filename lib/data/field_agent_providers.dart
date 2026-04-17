// ============================================================
// Field Agent – Riverpod Providers
// ============================================================

import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/restaurant_model.dart';
import '../data/providers.dart';
import '../data/restaurant_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────
final restaurantRepositoryProvider = Provider<RestaurantRepository>(
  (_) => RestaurantRepository(),
);

// ══════════════════════════════════════════════════════════════════════════
//  Fetch Restaurants  (AsyncNotifier — loads on open, refreshes after add)
// ══════════════════════════════════════════════════════════════════════════
class FetchRestaurantsNotifier extends AsyncNotifier<List<Restaurant>> {
  @override
  Future<List<Restaurant>> build() => _load();

  Future<List<Restaurant>> _load() =>
      ref.read(restaurantRepositoryProvider).fetchRestaurants();

  /// Force a fresh fetch from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final fetchRestaurantsProvider =
    AsyncNotifierProvider<FetchRestaurantsNotifier, List<Restaurant>>(
  FetchRestaurantsNotifier.new,
);

// ══════════════════════════════════════════════════════════════════════════
//  Add Restaurant State
// ══════════════════════════════════════════════════════════════════════════
enum AddRestaurantStatus { idle, loading, success, error }

class AddRestaurantState {
  final AddRestaurantStatus status;
  final String? errorMessage;

  const AddRestaurantState({
    this.status = AddRestaurantStatus.idle,
    this.errorMessage,
  });

  AddRestaurantState copyWith({
    AddRestaurantStatus? status,
    String? errorMessage,
  }) =>
      AddRestaurantState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────
class FieldAgentNotifier extends Notifier<AddRestaurantState> {
  static const _uuid = Uuid();

  @override
  AddRestaurantState build() => const AddRestaurantState();

  Future<void> addRestaurant({
    required String name,
    required RestaurantType type,
    required String city,
    required String area,
    required String address,
    required List<String> superAdminEmails,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    final repo = ref.read(restaurantRepositoryProvider);

    state = state.copyWith(status: AddRestaurantStatus.loading);

    final restaurant = Restaurant(
      restaurantId: _uuid.v4(),
      name: name.trim(),
      type: type,
      city: city.trim(),
      area: area.trim(),
      address: address.trim(),
      createdBy: currentUser?.employeeId ?? 'unknown',
      createdAt: DateTime.now(),
      superAdminEmails: superAdminEmails
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList(),
    );

    try {
      await repo.addRestaurant(
        name: restaurant.name,
        type: restaurant.type.name,
        city: restaurant.city,
        area: restaurant.area,
        address: restaurant.address,
        createdBy: restaurant.createdBy,
        superAdminEmails: restaurant.superAdminEmails,
      );

      dev.log(
        '✅ Restaurant "${restaurant.name}" onboarded (id: ${restaurant.restaurantId})',
        name: 'FieldAgent',
      );

      // ── Re-fetch the list so the dashboard shows the latest data ──
      ref.invalidate(fetchRestaurantsProvider);

      state = state.copyWith(status: AddRestaurantStatus.success);
    } on RestaurantApiException catch (e) {
      dev.log('❌ API error: ${e.message}', name: 'FieldAgent');
      state = state.copyWith(
          status: AddRestaurantStatus.error, errorMessage: e.message);
    } catch (e) {
      dev.log('❌ Unexpected: $e', name: 'FieldAgent');
      state = state.copyWith(
          status: AddRestaurantStatus.error,
          errorMessage: 'Something went wrong. Please try again.');
    }
  }

  void resetStatus() =>
      state = state.copyWith(status: AddRestaurantStatus.idle, errorMessage: null);
}

final fieldAgentProvider =
    NotifierProvider<FieldAgentNotifier, AddRestaurantState>(
  FieldAgentNotifier.new,
);


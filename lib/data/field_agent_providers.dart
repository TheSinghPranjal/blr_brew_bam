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

// ── State for the Add Restaurant form ────────────────────────────────────
enum AddRestaurantStatus { idle, loading, success, error }

class AddRestaurantState {
  final AddRestaurantStatus status;
  final String? errorMessage;
  final List<Restaurant> restaurants;

  const AddRestaurantState({
    this.status = AddRestaurantStatus.idle,
    this.errorMessage,
    this.restaurants = const [],
  });

  AddRestaurantState copyWith({
    AddRestaurantStatus? status,
    String? errorMessage,
    List<Restaurant>? restaurants,
  }) =>
      AddRestaurantState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        restaurants: restaurants ?? this.restaurants,
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

    // Build local model for in-app list (UUID generated client-side)
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
      // ── Real API call ──────────────────────────────────────────────
      await repo.addRestaurant(
        name: restaurant.name,
        type: restaurant.type.name,          // "cafe" | "fineDining" | …
        city: restaurant.city,
        area: restaurant.area,
        address: restaurant.address,
        createdBy: restaurant.createdBy,
        superAdminEmails: restaurant.superAdminEmails,
      );

      dev.log(
        '✅ Restaurant "${restaurant.name}" onboarded successfully '
        '(id: ${restaurant.restaurantId})',
        name: 'FieldAgent',
      );

      state = state.copyWith(
        status: AddRestaurantStatus.success,
        restaurants: [...state.restaurants, restaurant],
      );
    } on RestaurantApiException catch (e) {
      dev.log(
        '❌ API error: ${e.message} (status: ${e.statusCode})',
        name: 'FieldAgent',
      );
      state = state.copyWith(
        status: AddRestaurantStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      dev.log(
        '❌ Unexpected error: $e',
        name: 'FieldAgent',
      );
      state = state.copyWith(
        status: AddRestaurantStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  void resetStatus() {
    state = state.copyWith(status: AddRestaurantStatus.idle, errorMessage: null);
  }
}

final fieldAgentProvider =
    NotifierProvider<FieldAgentNotifier, AddRestaurantState>(
  FieldAgentNotifier.new,
);

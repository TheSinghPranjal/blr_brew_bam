// ============================================================
// Field Agent – Riverpod Providers
// ============================================================

import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/restaurant_model.dart';
import '../data/providers.dart';

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
    state = state.copyWith(status: AddRestaurantStatus.loading);

    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 1200));

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

    // Simulate API call — print full payload
    dev.log(
      '═══════════════════════════════════════\n'
      '  [Field Agent] Restaurant Payload\n'
      '═══════════════════════════════════════\n'
      '${restaurant.toJson()}\n'
      '═══════════════════════════════════════',
      name: 'FieldAgent.addRestaurant',
    );

    state = state.copyWith(
      status: AddRestaurantStatus.success,
      restaurants: [...state.restaurants, restaurant],
    );
  }

  void resetStatus() {
    state = state.copyWith(status: AddRestaurantStatus.idle, errorMessage: null);
  }
}

final fieldAgentProvider =
    NotifierProvider<FieldAgentNotifier, AddRestaurantState>(
  FieldAgentNotifier.new,
);

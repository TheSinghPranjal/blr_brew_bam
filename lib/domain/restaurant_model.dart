// ============================================================
// Domain Model – Restaurant (Field Agent onboarding)
// ============================================================

enum RestaurantType { cafe, fineDining, bar, cloudKitchen }

extension RestaurantTypeX on RestaurantType {
  String get displayName {
    switch (this) {
      case RestaurantType.cafe:
        return 'Cafe';
      case RestaurantType.fineDining:
        return 'Fine Dining';
      case RestaurantType.bar:
        return 'Bar';
      case RestaurantType.cloudKitchen:
        return 'Cloud Kitchen';
    }
  }

  String get emoji {
    switch (this) {
      case RestaurantType.cafe:
        return '☕';
      case RestaurantType.fineDining:
        return '🍽️';
      case RestaurantType.bar:
        return '🍺';
      case RestaurantType.cloudKitchen:
        return '📦';
    }
  }
}

class Restaurant {
  final String restaurantId;   // UUID
  final String name;
  final RestaurantType type;
  final String city;
  final String area;
  final String address;
  final String createdBy;      // employeeId of the field agent
  final DateTime createdAt;
  final bool isActive;
  final List<String> superAdminEmails; // 1–3 emails

  const Restaurant({
    required this.restaurantId,
    required this.name,
    required this.type,
    required this.city,
    required this.area,
    required this.address,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
    required this.superAdminEmails,
  });

  Map<String, dynamic> toJson() => {
        'restaurant_id': restaurantId,
        'name': name,
        'type': type.name,
        'city': city,
        'area': area,
        'address': address,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'is_active': isActive,
        'super_admin_emails': superAdminEmails,
      };

  @override
  String toString() => 'Restaurant(id: $restaurantId, name: $name)';
}

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
  final String restaurantId;
  final String name;
  final RestaurantType type;
  final String city;
  final String area;
  final String address;
  final String createdBy;
  final DateTime createdAt;
  final bool isActive;
  final List<String> superAdminEmails;

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

  /// Parses the fetchRestaurants GET response.
  /// Handles both "super_admins" (GET) and "super_admin_emails" (POST) keys.
  /// Type matching is case-insensitive: "Cafe" == "cafe".
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final rawEmails = json['super_admins'] ?? json['super_admin_emails'] ?? [];
    return Restaurant(
      restaurantId: json['restaurant_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: _typeFromString(json['type'] as String? ?? ''),
      city: json['city'] as String? ?? '',
      area: json['area'] as String? ?? '',
      address: json['address'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
      superAdminEmails: List<String>.from(rawEmails as List),
    );
  }

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

/// Maps any casing of the type string to [RestaurantType].
RestaurantType _typeFromString(String raw) {
  switch (raw.toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '')) {
    case 'finedining':
      return RestaurantType.fineDining;
    case 'bar':
      return RestaurantType.bar;
    case 'cloudkitchen':
      return RestaurantType.cloudKitchen;
    case 'cafe':
    default:
      return RestaurantType.cafe;
  }
}

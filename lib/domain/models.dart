// ============================================================
// Domain Models – Restaurant Management System
// ============================================================

enum UserRole {
  superAdmin,
  manager,
  headChef,
  chef,
  kitchen,
  seniorWaiter,
  waiter,
  serviceDesk,
  cleaning,
  inventory,
  customer,
}

extension UserRoleX on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.headChef:
        return 'Head Chef';
      case UserRole.seniorWaiter:
        return 'Senior Waiter';
      case UserRole.serviceDesk:
        return 'Service Desk';
      default:
        final s = toString().split('.').last;
        return s[0].toUpperCase() + s.substring(1);
    }
  }

  /// Whether this role can access Super Admin UI
  bool get isSuperAdmin => this == UserRole.superAdmin;

  /// Whether this role can access Manager UI
  bool get isManagerOrAbove =>
      this == UserRole.superAdmin || this == UserRole.manager;
}

// -------------------------------------------------------
// User
// -------------------------------------------------------
class RestaurantUser {
  final String employeeId;
  final String name;
  final String username;
  final String mobileNumber;
  final String? alternateMobileNumber;
  final String email;
  final String designation;
  UserRole role; // mutable so Super Admin can reassign
  final String photoUrl;
  final String? about;
  final int age;
  final List<String> languagesSpoken;
  final Map<String, dynamic> metadata;

  RestaurantUser({
    required this.employeeId,
    required this.name,
    required this.username,
    required this.mobileNumber,
    this.alternateMobileNumber,
    required this.email,
    required this.designation,
    required this.role,
    required this.photoUrl,
    this.about,
    required this.age,
    required this.languagesSpoken,
    this.metadata = const {},
  });

  RestaurantUser copyWith({
    String? employeeId,
    String? name,
    String? username,
    String? mobileNumber,
    String? alternateMobileNumber,
    String? email,
    String? designation,
    UserRole? role,
    String? photoUrl,
    String? about,
    int? age,
    List<String>? languagesSpoken,
    Map<String, dynamic>? metadata,
  }) {
    return RestaurantUser(
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      username: username ?? this.username,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      alternateMobileNumber:
          alternateMobileNumber ?? this.alternateMobileNumber,
      email: email ?? this.email,
      designation: designation ?? this.designation,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      about: about ?? this.about,
      age: age ?? this.age,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      metadata: metadata ?? this.metadata,
    );
  }
}

// -------------------------------------------------------
// Category
// -------------------------------------------------------
class Category {
  final String id;
  final String name;
  final String imageUrl;
  final bool isVeg;
  final bool isMocktail;
  final bool isCocktail;
  final String? parentId; // null = top-level category

  Category({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.isVeg = true,
    this.isMocktail = false,
    this.isCocktail = false,
    this.parentId,
  });

  bool get isSubCategory => parentId != null;
}

// -------------------------------------------------------
// Product
// -------------------------------------------------------
class Product {
  final String id;
  final String name;
  final String description;
  final int calories;
  final String assignedChefId;
  final String categoryId;
  final String? subCategoryId;
  final double price;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.calories,
    required this.assignedChefId,
    required this.categoryId,
    this.subCategoryId,
    required this.price,
    this.imageUrl = '',
  });
}

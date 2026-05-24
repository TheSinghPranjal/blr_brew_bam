/// Mirrors the API response schema from fetchCategories / addCategory
class ApiCategory {
  final String categoryId;
  final String categoryName;
  final String image;
  final bool isVegetarian;
  final bool isMocktail;
  final bool isCocktail;
  final bool hasSubcategory;
  final List<String> subcategories;
  final int displayOrder;
  final bool isActive;

  const ApiCategory({
    required this.categoryId,
    required this.categoryName,
    required this.image,
    required this.isVegetarian,
    required this.isMocktail,
    required this.isCocktail,
    required this.hasSubcategory,
    required this.subcategories,
    required this.displayOrder,
    required this.isActive,
  });

  factory ApiCategory.fromJson(Map<String, dynamic> json) {
    return ApiCategory(
      categoryId: json['category_id'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      isVegetarian: json['is_vegetarian'] as bool? ?? true,
      isMocktail: json['is_mocktail'] as bool? ?? false,
      isCocktail: json['is_cocktail'] as bool? ?? false,
      hasSubcategory: json['has_subcategory'] as bool? ?? false,
      subcategories: List<String>.from(json['subcategories'] ?? []),
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'category_name': categoryName,
        'image': image,
        'is_vegetarian': isVegetarian,
        'is_mocktail': isMocktail,
        'is_cocktail': isCocktail,
        'has_subcategory': hasSubcategory,
        'subcategories': subcategories,
        'display_order': displayOrder,
        'is_active': isActive,
      };

  ApiCategory copyWith({
    String? categoryId,
    String? categoryName,
    String? image,
    bool? isVegetarian,
    bool? isMocktail,
    bool? isCocktail,
    bool? hasSubcategory,
    List<String>? subcategories,
    int? displayOrder,
    bool? isActive,
  }) {
    return ApiCategory(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      image: image ?? this.image,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isMocktail: isMocktail ?? this.isMocktail,
      isCocktail: isCocktail ?? this.isCocktail,
      hasSubcategory: hasSubcategory ?? this.hasSubcategory,
      subcategories: subcategories ?? this.subcategories,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}

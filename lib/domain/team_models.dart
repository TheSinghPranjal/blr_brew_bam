// ============================================================
// Domain Models – Team & Team Category (Super Admin)
// ============================================================

import 'package:uuid/uuid.dart';

// ── Team Category ─────────────────────────────────────────────────────────
class TeamCategory {
  final String id;
  final String name;
  final String restaurantId;
  final String emoji;        // visual identifier chosen by admin
  final int memberCount;
  final DateTime createdAt;

  const TeamCategory({
    required this.id,
    required this.name,
    required this.restaurantId,
    this.emoji = '👥',
    this.memberCount = 0,
    required this.createdAt,
  });

  TeamCategory copyWith({
    String? name,
    String? emoji,
    int? memberCount,
  }) =>
      TeamCategory(
        id: id,
        name: name ?? this.name,
        restaurantId: restaurantId,
        emoji: emoji ?? this.emoji,
        memberCount: memberCount ?? this.memberCount,
        createdAt: createdAt,
      );
}

// ── Team Member ───────────────────────────────────────────────────────────
class TeamMember {
  final String id;
  final String restaurantId;
  final String email;
  final String? name;           // resolved once invited / joined
  final String teamCategoryId;  // which TeamCategory they belong to
  final String teamCategoryName;
  final bool isPending;         // true = invite sent, not yet accepted
  final DateTime addedAt;

  const TeamMember({
    required this.id,
    required this.restaurantId,
    required this.email,
    this.name,
    required this.teamCategoryId,
    required this.teamCategoryName,
    this.isPending = true,
    required this.addedAt,
  });
}

// ── Remote member (from fetchMembersFromMyRestaurant) ──────────────────────
class RestaurantMember {
  final String userId;
  final String email;
  final String role; // e.g. waiter, super_admin
  final String restaurantId;
  final String status; // e.g. INVITED, invited, ACTIVE, etc
  final String? addedById;
  final String? addedByName;
  final DateTime createdAt;

  const RestaurantMember({
    required this.userId,
    required this.email,
    required this.role,
    required this.restaurantId,
    required this.status,
    required this.createdAt,
    this.addedById,
    this.addedByName,
  });

  factory RestaurantMember.fromJson(Map<String, dynamic> json) {
    return RestaurantMember(
      userId: json['user_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      restaurantId: json['restaurant_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      addedById: json['added_by_id']?.toString(),
      addedByName: json['added_by_name']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

// ── Convenience factory ───────────────────────────────────────────────────
const _uuid = Uuid();

TeamCategory createCategory({
  required String name,
  required String restaurantId,
  String emoji = '👥',
}) =>
    TeamCategory(
      id: _uuid.v4(),
      name: name,
      restaurantId: restaurantId,
      emoji: emoji,
      createdAt: DateTime.now(),
    );

TeamMember createTeamMember({
  required String email,
  required String restaurantId,
  required TeamCategory category,
}) =>
    TeamMember(
      id: _uuid.v4(),
      restaurantId: restaurantId,
      email: email.trim().toLowerCase(),
      teamCategoryId: category.id,
      teamCategoryName: category.name,
      addedAt: DateTime.now(),
    );

// ── Default seed categories for a new restaurant ──────────────────────────
List<TeamCategory> defaultCategories(String restaurantId) => [
      TeamCategory(
        id: _uuid.v4(),
        name: 'Waiters',
        restaurantId: restaurantId,
        emoji: '🍽️',
        createdAt: DateTime.now(),
      ),
      TeamCategory(
        id: _uuid.v4(),
        name: 'Cooks',
        restaurantId: restaurantId,
        emoji: '👨‍🍳',
        createdAt: DateTime.now(),
      ),
      TeamCategory(
        id: _uuid.v4(),
        name: 'Bartenders',
        restaurantId: restaurantId,
        emoji: '🍺',
        createdAt: DateTime.now(),
      ),
      TeamCategory(
        id: _uuid.v4(),
        name: 'Helpers',
        restaurantId: restaurantId,
        emoji: '🤝',
        createdAt: DateTime.now(),
      ),
    ];

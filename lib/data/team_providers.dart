// ============================================================
// Team Providers – Riverpod state for TeamCategory & TeamMember
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/team_models.dart';
import 'team_repository.dart';

// ── Team Categories ───────────────────────────────────────────────────────
class TeamCategoryNotifier extends Notifier<List<TeamCategory>> {
  @override
  List<TeamCategory> build() => [];

  /// Seed default categories for a restaurant (called when restaurant is set)
  void seedDefaults(String restaurantId) {
    if (state.isNotEmpty) return; // already seeded
    state = defaultCategories(restaurantId);
  }

  void add(TeamCategory category) {
    state = [...state, category];
  }

  void remove(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void rename(String id, String newName, String newEmoji) {
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(name: newName, emoji: newEmoji) else c,
    ];
  }

  void _updateMemberCount(String categoryId, int delta) {
    state = [
      for (final c in state)
        if (c.id == categoryId)
          c.copyWith(memberCount: (c.memberCount + delta).clamp(0, 9999))
        else
          c,
    ];
  }
}

final teamCategoryProvider =
    NotifierProvider<TeamCategoryNotifier, List<TeamCategory>>(
  TeamCategoryNotifier.new,
);

// ── Team Members ──────────────────────────────────────────────────────────
class TeamMemberNotifier extends Notifier<List<TeamMember>> {
  @override
  List<TeamMember> build() => [];

  void add(TeamMember member) {
    state = [...state, member];
    // Increment the category count
    ref
        .read(teamCategoryProvider.notifier)
        ._updateMemberCount(member.teamCategoryId, 1);
  }

  void remove(String memberId) {
    final member = state.firstWhere((m) => m.id == memberId);
    state = state.where((m) => m.id != memberId).toList();
    ref
        .read(teamCategoryProvider.notifier)
        ._updateMemberCount(member.teamCategoryId, -1);
  }

  List<TeamMember> byCategory(String categoryId) =>
      state.where((m) => m.teamCategoryId == categoryId).toList();
}

final teamMemberProvider =
    NotifierProvider<TeamMemberNotifier, List<TeamMember>>(
  TeamMemberNotifier.new,
);

// ── Team Repository (API) ────────────────────────────────────────────────
final teamRepositoryProvider = Provider<TeamRepository>((_) => TeamRepository());

// ── Remote Team Members (API) ──────────────────────────────────────────────
final fetchRestaurantMembersProvider =
    FutureProvider.family<List<RestaurantMember>, String>((ref, restaurantId) async {
  final repo = ref.read(teamRepositoryProvider);
  final raw = await repo.fetchMembersFromMyRestaurant(restaurantId: restaurantId);
  final users = (raw['users'] as List<dynamic>? ?? const []);
  return users
      .whereType<Map<String, dynamic>>()
      .map(RestaurantMember.fromJson)
      .toList();
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../../../data/order_providers.dart';
import '../../../data/providers.dart';
import '../../../domain/order_models.dart';

class CookDashboard extends ConsumerWidget {
  const CookDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final orders = ref.watch(kitchenOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Kitchen — ${user?.name.split(' ').first ?? 'Cook'}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(kitchenOrdersProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: orders.isEmpty
          ? Center(
              child: Text(
                'No active orders',
                style: GoogleFonts.outfit(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                if (order.status == TableOrderStatus.completed) {
                  return const SizedBox.shrink();
                }
                return _TableOrderCard(order: order);
              },
            ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(amplifyAuthServiceProvider).signOut();
    } catch (_) {}
    ref.read(currentUserProvider.notifier).state = null;
    if (context.mounted) context.go('/login');
  }
}

class _TableOrderCard extends ConsumerWidget {
  final TableOrder order;
  const _TableOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.tableName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(order.orderedAt),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...order.dishes.map((dish) => _DishRow(orderId: order.id, dish: dish)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _DishRow extends ConsumerWidget {
  final String orderId;
  final OrderDish dish;

  const _DishRow({required this.orderId, required this.dish});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = switch (dish.status) {
      DishStatus.pending => AppColors.textSecondary,
      DishStatus.started => Colors.orange,
      DishStatus.cooking => Colors.deepOrange,
      DishStatus.prepared => Colors.green,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dish.name} × ${dish.quantity}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                Text(
                  dish.status.label,
                  style: GoogleFonts.outfit(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
          if (dish.status.next != null)
            FilledButton.tonal(
              onPressed: () {
                ref
                    .read(kitchenOrdersProvider.notifier)
                    .advanceDish(orderId, dish.id);

                if (dish.status == DishStatus.cooking) {
                  ref.read(preparedDishAlertsProvider.notifier).notifyPrepared(
                        '${dish.name} prepared for order $orderId',
                      );
                }
              },
              child: Text(
                dish.status == DishStatus.pending
                    ? 'Start'
                    : dish.status == DishStatus.started
                        ? 'Cooking'
                        : 'Prepared',
              ),
            )
          else
            const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }
}

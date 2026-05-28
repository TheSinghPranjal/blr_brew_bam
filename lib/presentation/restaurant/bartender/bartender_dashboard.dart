import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../../../data/order_providers.dart';
import '../../../data/providers.dart';
import '../../../domain/order_models.dart';

/// Bar / drink prep screen — same order flow as kitchen, bar-focused label.
class BartenderDashboard extends ConsumerWidget {
  const BartenderDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final orders = ref.watch(kitchenOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Bar — ${user?.name.split(' ').first ?? 'Bartender'}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: orders.isEmpty
          ? Center(
              child: Text(
                'No bar orders',
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
                return _BarOrderCard(order: order);
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

class _BarOrderCard extends ConsumerWidget {
  final TableOrder order;
  const _BarOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.tableName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...order.dishes.map((dish) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(dish.name),
                subtitle: Text(dish.status.label),
                trailing: dish.status.next != null
                    ? FilledButton.tonal(
                        onPressed: () => ref
                            .read(kitchenOrdersProvider.notifier)
                            .advanceDish(order.id, dish.id),
                        child: Text(
                          dish.status == DishStatus.pending ? 'Start' : 'Next',
                        ),
                      )
                    : const Icon(Icons.check_circle, color: Colors.green),
              );
            }),
          ],
        ),
      ),
    );
  }
}

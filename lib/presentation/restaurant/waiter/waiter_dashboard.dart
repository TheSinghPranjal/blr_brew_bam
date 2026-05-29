import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../../../data/order_providers.dart';
import '../../../data/providers.dart';
import '../../../domain/order_models.dart';

class WaiterDashboard extends ConsumerWidget {
  const WaiterDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final orders = ref.watch(kitchenOrdersProvider);
    final alerts = ref.watch(preparedDishAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Waiter — ${user?.name.split(' ').first ?? 'Staff'}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          if (alerts.isNotEmpty) _AlertsBanner(alerts: alerts),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return _WaiterTableCard(order: orders[index]);
              },
            ),
          ),
        ],
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

class _AlertsBanner extends ConsumerWidget {
  final List<String> alerts;
  const _AlertsBanner({required this.alerts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Text(
                'Dishes ready to serve',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...List.generate(alerts.length.clamp(0, 3), (i) {
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• ${alerts[i]}',
                style: GoogleFonts.outfit(fontSize: 13),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WaiterTableCard extends ConsumerWidget {
  final TableOrder order;
  const _WaiterTableCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = switch (order.status) {
      TableOrderStatus.preparing => Colors.orange,
      TableOrderStatus.ready => Colors.green,
      TableOrderStatus.completed => AppColors.textSecondary,
    };

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
                Text(
                  order.tableName,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.itemCount} items • Ordered ${_formatTime(order.orderedAt)}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: order.dishes
                  .map(
                    (d) => Chip(
                      label: Text('${d.name} (${d.status.label})'),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            if (order.status == TableOrderStatus.ready) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => ref
                      .read(kitchenOrdersProvider.notifier)
                      .markOrderCompleted(order.id),
                  child: const Text('Mark order served'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours} hr ago';
  }
}

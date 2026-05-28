import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers.dart';
import '../../domain/models.dart';
import '../shared/widgets.dart';
import '../restaurant/bartender/bartender_dashboard.dart';
import '../restaurant/cook/cook_dashboard.dart';
import '../restaurant/waiter/waiter_dashboard.dart';
import '../restaurant/super_admin/super_admin_dashboard.dart';
import '../restaurant/manager/manager_dashboard.dart';

class RestaurantDashboard extends ConsumerWidget {
  const RestaurantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }


    void logout() async {
      try {
        await ref.read(amplifyAuthServiceProvider).signOut();
      } catch (_) {}
      ref.read(currentUserProvider.notifier).state = null;
      if (context.mounted) context.go('/login');
    }

    return switch (user.role) {
      UserRole.superAdmin => const SuperAdminDashboard(),
      UserRole.manager    => const ManagerDashboard(),
      UserRole.headChef   => const CookDashboard(),
      UserRole.chef       => const CookDashboard(),
      UserRole.kitchen    => const CookDashboard(),
      UserRole.bartender  => const BartenderDashboard(),
      UserRole.seniorWaiter => const WaiterDashboard(),
      UserRole.waiter     => const WaiterDashboard(),
      UserRole.serviceDesk => PlaceholderRoleScreen(
          role: 'Service Desk Interface', onLogout: logout),
      UserRole.cashier    => PlaceholderRoleScreen(
          role: 'Cashier Interface', onLogout: logout),
      UserRole.cleaning   => PlaceholderRoleScreen(
          role: 'Cleaning Interface', onLogout: logout),
      UserRole.inventory  => PlaceholderRoleScreen(
          role: 'Inventory Interface', onLogout: logout),
      UserRole.customer   => PlaceholderRoleScreen(
          role: 'Customer', onLogout: logout),
      UserRole.fieldAgent => throw UnimplementedError(),
    };
  }
}

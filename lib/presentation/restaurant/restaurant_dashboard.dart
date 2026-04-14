import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers.dart';
import '../../domain/models.dart';
import '../shared/widgets.dart';
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

    void logout() {
      ref.read(currentUserProvider.notifier).state = null;
      context.go('/login');
    }

    switch (user.role) {
      case UserRole.superAdmin:
        return const SuperAdminDashboard();
      case UserRole.manager:
        return const ManagerDashboard();
      case UserRole.headChef:
        return PlaceholderRoleScreen(
            role: 'Head Chef Interface', onLogout: logout);
      case UserRole.chef:
        return PlaceholderRoleScreen(
            role: 'Chef Interface', onLogout: logout);
      case UserRole.kitchen:
        return PlaceholderRoleScreen(
            role: 'Kitchen Interface', onLogout: logout);
      case UserRole.seniorWaiter:
        return PlaceholderRoleScreen(
            role: 'Senior Waiter Interface', onLogout: logout);
      case UserRole.waiter:
        return PlaceholderRoleScreen(
            role: 'Waiter Interface', onLogout: logout);
      case UserRole.serviceDesk:
        return PlaceholderRoleScreen(
            role: 'Service Desk Interface', onLogout: logout);
      case UserRole.cleaning:
        return PlaceholderRoleScreen(
            role: 'Cleaning Interface', onLogout: logout);
      case UserRole.inventory:
        return PlaceholderRoleScreen(
            role: 'Inventory Interface', onLogout: logout);
      case UserRole.customer:
        // customers shouldn't be here, redirect to customer app
        return PlaceholderRoleScreen(
            role: 'Customer', onLogout: logout);
    }
  }
}

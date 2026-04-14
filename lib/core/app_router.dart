import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../presentation/auth/login_page.dart';
import '../presentation/auth/gateway_page.dart';
import '../presentation/customer/user_interface.dart';
import '../presentation/restaurant/restaurant_dashboard.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state changes to rebuild the router when login changes
  ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final isOnLogin = state.uri.path == '/login';

      if (user == null && !isOnLogin) return '/login';
      if (user != null && isOnLogin) return '/gateway';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/gateway',
        name: 'gateway',
        builder: (_, __) => const GatewayPage(),
      ),
      GoRoute(
        path: '/customer',
        name: 'customer',
        builder: (_, __) => const UserInterface(),
      ),
      GoRoute(
        path: '/restaurant',
        name: 'restaurant',
        builder: (_, __) => const RestaurantDashboard(),
      ),
    ],
  );
});

import 'package:flutter/material.dart';
import '../../domain/models.dart';

class RoleWrapper extends StatelessWidget {
  final UserRole userRole;
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleWrapper({
    super.key,
    required this.userRole,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (allowedRoles.contains(userRole)) {
      return child;
    }
    return fallback ?? const Scaffold(
      body: Center(
        child: Text('Unauthorized Access.\nYou do not have permission to view this page.'),
      ),
    );
  }
}

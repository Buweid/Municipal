import 'package:flutter/material.dart';
import 'admin/admin_home_screen.dart';
import 'fo/fo_home_screen.dart';
import 'user/user_home_screen.dart';


class RoleRouter extends StatelessWidget {
  final String role;
  const RoleRouter({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const AdminHomeScreen();
      case 'fo':
        return const FOHomeScreen();
      case 'user':
      default:
        return const UserHomeScreen();
    }
  }
}
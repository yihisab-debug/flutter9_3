import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/admin_notifications_watcher.dart';
import '../../admin/screens/admin_root_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _watching = false;

  void _syncWatcher() {
    final auth = context.read<AuthService>();
    if (auth.isLoggedIn && auth.role == UserRole.admin) {
      if (!_watching) {
        AdminNotificationsWatcher.instance.start();
        _watching = true;
      }
    } else {
      if (_watching) {
        AdminNotificationsWatcher.instance.stop();
        _watching = false;
      }
    }
  }

  @override
  void dispose() {
    AdminNotificationsWatcher.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWatcher());

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    if (auth.role == UserRole.admin) {
      return const AdminRootScreen();
    }

    return const _WrongRoleScreen();
  }
}

class _WrongRoleScreen extends StatelessWidget {
  const _WrongRoleScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isCustomer = auth.role == UserRole.customer;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.admin.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  isCustomer ? '🛍️' : '🛵',
                  style: const TextStyle(fontSize: 48),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Это приложение для администраторов',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                isCustomer
                    ? 'Вы вошли как покупатель. Используйте приложение «Беш Доставка».'
                    : 'Вы вошли как курьер. Используйте приложение «Беш Курьер».',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => auth.logout(),
                  child: const Text('Выйти'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

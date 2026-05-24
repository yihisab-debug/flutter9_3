import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/services/auth_service.dart';
import '../../../main.dart' show globalFirebaseError;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _diag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirebase();
    });
  }

  void _checkFirebase() {
    try {
      Firebase.app();
      setState(() => _diag = globalFirebaseError);
    } catch (e) {
      setState(() => _diag =
          '⚠️ Firebase не инициализирован.\nЗапустите flutterfire configure');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход администратора',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  size: 40, color: AppColors.admin),
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text('Беш Админ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('👑 Панель управления',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 24),
          if (_diag != null) ...[
            _ErrorBox(text: _diag!),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.lock_outline, size: 18, color: AppColors.admin),
                    SizedBox(width: 8),
                    Text('Доступ только для администрации',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Войдите под аккаунтом администратора, чтобы открыть панель управления',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 12),
                _AdminButton(
                  loading: auth.loading,
                  onTap: _doAdminLogin,
                ),
                const SizedBox(height: 10),
                _GoogleSignInButton(
                  loading: auth.loading,
                  onTap: _doGoogleLogin,
                ),
              ],
            ),
          ),
          if (auth.error != null) ...[
            const SizedBox(height: 14),
            _ErrorBox(text: auth.error!),
          ],
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Версия для администрации\nБеш Доставка',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doAdminLogin() async {
    context.read<AuthService>().clearError();
    await context.read<AuthService>().loginAsAdmin();

  }

  Future<void> _doGoogleLogin() async {
    context.read<AuthService>().clearError();
    await context
        .read<AuthService>()
        .signInWithGoogle(roleOnFirstLogin: UserRole.admin);

  }
}

class _ErrorBox extends StatelessWidget {
  final String text;
  const _ErrorBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(color: AppColors.error, fontSize: 13))),
        ],
      ),
    );
  }
}

class _AdminButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;

  const _AdminButton({required this.onTap, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.admin.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('👑', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Войти как администратор',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    SizedBox(height: 2),
                    Text('Демо-доступ',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.arrow_forward,
                    size: 18, color: AppColors.admin),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;

  const _GoogleSignInButton({required this.onTap, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const _GoogleLogo(size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Войти через Google',
                      style: TextStyle(
                        color: Color(0xFF1F1F1F),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Быстрый вход с аккаунтом Google',
                      style: TextStyle(
                        color: Color(0xFF5F6368),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF1F1F1F)),
                  ),
                )
              else
                const Icon(Icons.arrow_forward,
                    size: 18, color: Color(0xFF1F1F1F)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const Text(
        'G',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Color(0xFF4285F4),
          height: 1.05,
        ),
      ),
    );
  }
}

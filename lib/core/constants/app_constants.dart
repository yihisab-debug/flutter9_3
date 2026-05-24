import 'package:flutter/material.dart';

class AppColors {

  static const Color background = Color(0xFF0E0F12);
  static const Color surface = Color(0xFF181A1F);
  static const Color surfaceElevated = Color(0xFF20232A);

  static const Color primary = Color(0xFFE63462);
  static const Color primaryDark = Color(0xFFB81E48);

  static const Color price = Color(0xFFFFA940);

  static const Color catRed = Color(0xFF6E2A2A);
  static const Color catGreen = Color(0xFF2A5A3A);
  static const Color catPurple = Color(0xFF3A2A6E);
  static const Color catOrange = Color(0xFF6E4A2A);

  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF8E9098);
  static const Color textMuted = Color(0xFF5A5C64);

  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFEF4444);
  static const Color border = Color(0xFF2A2D35);

  static const Color star = Color(0xFFFFD33C);

  static const Color admin = Color(0xFF9D5FFF);
}

class AppStrings {

  static const List<String> categories = [
    'Все',
    'Мясное',
    'Тесто',
    'Супы',
    'Хлеб',
    'Сладкое',
    'Напитки',
  ];

  static const int freeDeliveryFrom = 2000;

  static const int topUpAmount = 10000;

  static const List<String> cities = [
    'Алматы',
    'Астана',
    'Шымкент',
    'Караганда',
    'Актобе',
    'Тараз',
    'Павлодар',
    'Усть-Каменогорск',
    'Семей',
    'Атырау',
    'Костанай',
    'Кызылорда',
    'Уральск',
    'Петропавловск',
    'Актау',
    'Темиртау',
    'Туркестан',
    'Кокшетау',
    'Талдыкорган',
  ];

  static const String defaultCity = 'Алматы';
}

enum UserRole {
  customer,
  courier,
  admin,
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Покупатель';
      case UserRole.courier:
        return 'Курьер';
      case UserRole.admin:
        return 'Администратор';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.customer:
        return '🛍️';
      case UserRole.courier:
        return '🛵';
      case UserRole.admin:
        return '👑';
    }
  }

  static UserRole fromString(String? s) {
    return UserRole.values.firstWhere(
      (e) => e.name == s,
      orElse: () => UserRole.customer,
    );
  }
}

class DemoAccounts {
  static const String customerEmail = 'client@besh.kz';
  static const String customerPassword = 'client123';
  static const String customerName = 'Айбек Тестов';

  static const String courierEmail = 'courier@besh.kz';
  static const String courierPassword = 'courier123';
  static const String courierName = 'Ерлан Курьеров';

  static const String adminEmail = 'admin@besh.kz';
  static const String adminPassword = 'admin_secret_2026';
  static const String adminName = 'Главный администратор';
}

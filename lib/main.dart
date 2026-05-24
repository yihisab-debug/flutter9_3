import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/services/auth_service.dart';
import 'data/services/complaints_service.dart';
import 'data/services/admin_menu_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/admin_notifications_watcher.dart';
import 'features/auth/screens/auth_gate.dart';
import 'firebase_options.dart';

String? globalFirebaseError;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0E0F12),
  ));

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      await FirebaseFirestore.instance
          .collection('_diagnostic')
          .doc('ping')
          .get()
          .timeout(const Duration(seconds: 5));
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('PERMISSION_DENIED')) {
        globalFirebaseError =
            'Firestore: нет прав на чтение.\nОткройте Firebase Console → Firestore → Rules и опубликуйте правила (см. README).';
      } else if (msg.contains('NOT_FOUND')) {
        globalFirebaseError =
            'Firestore Database не создана.\nОткройте Firebase Console → Build → Firestore Database → Create database.';
      } else if (msg.contains('SERVICE_DISABLED') ||
          msg.contains('has not been used') ||
          msg.contains('not enabled')) {
        globalFirebaseError =
            'Cloud Firestore API не включён в проекте.\nИспользуйте flutterfire configure ещё раз.';
      } else if (msg.contains('TimeoutException') || msg.contains('network')) {
        globalFirebaseError = 'Нет интернета или Firebase недоступен.';
      }
    }
  } on FirebaseException catch (e) {
    globalFirebaseError = 'Firebase ошибка: ${e.code}\n${e.message ?? ''}';
  } catch (e) {
    globalFirebaseError =
        'Firebase не инициализирован.\n${e.toString()}\nЗапустите: flutterfire configure';
  }

  await NotificationService.instance.init(
    channelId: 'besh_admin',
    channelName: 'Беш Админ — жалобы',
    channelDescription: 'Уведомления о новых жалобах от клиентов',
  );

  runApp(const BeshDeliveryAdminApp());
}

class BeshDeliveryAdminApp extends StatelessWidget {
  const BeshDeliveryAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ComplaintsService()),
        ChangeNotifierProvider(create: (_) => AdminMenuService()),
      ],
      child: MaterialApp(
        title: 'Беш Админ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru', 'RU'),
          Locale('en', 'US'),
        ],
        locale: const Locale('ru', 'RU'),
      ),
    );
  }
}

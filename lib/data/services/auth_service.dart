import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_constants.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  User? _user;
  String? _displayName;
  String? _phone;
  String _city = AppStrings.defaultCity;
  UserRole _role = UserRole.customer;
  int _balance = 0;
  double _courierRating = 0.0;
  int _courierReviewsCount = 0;
  bool _loading = false;
  String? _error;
  bool _profileBeingCreated = false;

  User? get user => _user;
  String? get displayName => _displayName;
  String? get phone => _phone;
  String get city => _city;
  UserRole get role => _role;
  int get balance => _balance;
  double get courierRating => _courierRating;
  int get courierReviewsCount => _courierReviewsCount;
  bool get isLoggedIn => _user != null;
  bool get isCourier => _role == UserRole.courier;
  bool get isCustomer => _role == UserRole.customer;
  bool get isAdmin => _role == UserRole.admin;
  bool get loading => _loading;
  String? get error => _error;

  AuthService() {
    _auth.authStateChanges().listen((u) async {
      _user = u;
      if (u != null) {
        if (!_profileBeingCreated) await _loadProfile(u.uid);
      } else {
        _resetProfile();
      }
      notifyListeners();
    });
  }

  void _resetProfile() {
    _displayName = null;
    _phone = null;
    _city = AppStrings.defaultCity;
    _role = UserRole.customer;
    _balance = 0;
    _courierRating = 0.0;
    _courierReviewsCount = 0;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setCity(String city) {
    _city = city;
    notifyListeners();
    if (_user != null) {
      _db.collection('users').doc(_user!.uid).update({'city': city}).catchError(
          (e) => debugPrint('city save err: $e'));
    }
  }

  Future<void> _loadProfile(String uid) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 6));
      if (doc.exists) {
        final data = doc.data()!;
        _displayName = data['name'] as String?;
        _phone = data['phone'] as String?;
        _city = (data['city'] as String?) ?? AppStrings.defaultCity;
        _role = UserRoleX.fromString(data['role'] as String?);
        _balance = (data['balance'] ?? 0) as int;
        _courierRating = (data['rating'] ?? 0).toDouble();
        _courierReviewsCount = (data['reviewsCount'] ?? 0) as int;
      }
    } catch (e) {
      debugPrint('Ошибка загрузки профиля: $e');
    }
  }

  Future<void> refreshProfile() async {
    if (_user != null) {
      await _loadProfile(_user!.uid);
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      try {
        await _auth
            .signInWithEmailAndPassword(email: email.trim(), password: password)
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        if (!_isPigeonCastError(e)) rethrow;
      }
      final user = _auth.currentUser;
      if (user == null) {
        _error = 'Не удалось войти';
        return false;
      }
      await _loadProfile(user.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _humanizeAuthError(e.code, e.message);
      return false;
    } catch (e) {
      _error = _humanizeGenericError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle({required UserRole roleOnFirstLogin}) async {
    _loading = true;
    _error = null;
    _profileBeingCreated = true;
    notifyListeners();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      try {
        await _auth
            .signInWithCredential(credential)
            .timeout(const Duration(seconds: 15));
      } catch (e) {

        if (!_isPigeonCastError(e)) rethrow;
      }
      final user = _auth.currentUser;
      if (user == null) {
        _error = 'Не удалось выполнить вход';
        return false;
      }
      final docRef = _db.collection('users').doc(user.uid);
      final doc = await docRef.get().timeout(const Duration(seconds: 8));
      if (!doc.exists) {
        await docRef.set({
          'name': user.displayName ?? googleUser.displayName ?? 'Пользователь',
          'email': user.email ?? googleUser.email,
          'phone': '',
          'role': roleOnFirstLogin.name,
          'city': AppStrings.defaultCity,
          'balance': 0,
          'rating': 0,
          'reviewsCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'authProvider': 'google',
        }).timeout(const Duration(seconds: 8));
      }
      await _loadProfile(user.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _humanizeAuthError(e.code, e.message);
      return false;
    } catch (e) {
      _error = _humanizeGenericError(e);
      return false;
    } finally {
      _profileBeingCreated = false;
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> loginAsDemo(UserRole role) async {
    final email = role == UserRole.courier
        ? DemoAccounts.courierEmail
        : DemoAccounts.customerEmail;
    final password = role == UserRole.courier
        ? DemoAccounts.courierPassword
        : DemoAccounts.customerPassword;
    final name = role == UserRole.courier
        ? DemoAccounts.courierName
        : DemoAccounts.customerName;
    return _signInOrCreateDemo(
      email: email,
      password: password,
      name: name,
      role: role,
      extraData: {
        'phone': role == UserRole.courier
            ? '+7 700 000 0002'
            : '+7 700 000 0001',
        'balance': role == UserRole.customer ? 5000 : 0,
        'rating': role == UserRole.courier ? 4.8 : 0,
        'reviewsCount': role == UserRole.courier ? 12 : 0,
        'isDemo': true,
      },
    );
  }

  Future<bool> loginAsAdmin() async {
    return _signInOrCreateDemo(
      email: DemoAccounts.adminEmail,
      password: DemoAccounts.adminPassword,
      name: DemoAccounts.adminName,
      role: UserRole.admin,
      extraData: {
        'phone': '+7 700 000 0000',
        'balance': 0,
        'rating': 0,
        'reviewsCount': 0,
        'isAdmin': true,
      },
    );
  }

  Future<bool> _signInOrCreateDemo({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    required Map<String, dynamic> extraData,
  }) async {
    _loading = true;
    _error = null;
    _profileBeingCreated = true;
    notifyListeners();
    try {

      try {
        await _auth
            .signInWithEmailAndPassword(email: email, password: password)
            .timeout(const Duration(seconds: 15));
      } on FirebaseAuthException catch (e) {

        if (e.code == 'user-not-found' ||
            e.code == 'invalid-credential' ||
            e.code == 'invalid-login-credentials') {
          try {
            await _auth
                .createUserWithEmailAndPassword(
                    email: email, password: password)
                .timeout(const Duration(seconds: 15));
          } catch (createErr) {

            if (!_isPigeonCastError(createErr)) rethrow;
          }

          final u = _auth.currentUser;
          if (u != null) {
            try {
              await u.updateDisplayName(name);
            } catch (_) {}
            await _db.collection('users').doc(u.uid).set({
              'name': name,
              'email': email,
              'role': role.name,
              'city': AppStrings.defaultCity,
              'createdAt': FieldValue.serverTimestamp(),
              ...extraData,
            }).timeout(const Duration(seconds: 8));
          }
        } else {
          rethrow;
        }
      } catch (signInErr) {

        if (!_isPigeonCastError(signInErr)) rethrow;
      }

      final user = _auth.currentUser;
      if (user == null) {
        _error = 'Не удалось войти';
        return false;
      }
      await _loadProfile(user.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _humanizeAuthError(e.code, e.message);
      return false;
    } catch (e) {
      _error = _humanizeGenericError(e);
      return false;
    } finally {
      _profileBeingCreated = false;
      _loading = false;
      notifyListeners();
    }
  }

  bool _isPigeonCastError(Object e) {
    final s = e.toString();
    return s.contains('PigeonUserDetails') ||
        s.contains("is not a subtype of type 'PigeonUserInfo");
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? city,
  }) async {
    if (_user == null) {
      _error = 'Войдите в аккаунт';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final updates = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty && name != _displayName) {
        updates['name'] = name.trim();
      }
      if (phone != null && phone != _phone) {
        updates['phone'] = phone.trim();
      }
      if (city != null && city.isNotEmpty && city != _city) {
        updates['city'] = city;
      }
      if (email != null &&
          email.trim().isNotEmpty &&
          email.trim() != _user!.email) {

        try {
          await _user!
              .verifyBeforeUpdateEmail(email.trim())
              .timeout(const Duration(seconds: 10));
          updates['email'] = email.trim();
          _error =
              'На новый email отправлено письмо для подтверждения. Email сменится после подтверждения.';
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            _error =
                'Для смены email нужно недавно войти в аккаунт. Выйдите и войдите снова.';
            return false;
          }
          _error = _humanizeAuthError(e.code, e.message);
          return false;
        }
      }

      if (updates.isNotEmpty) {
        await _db
            .collection('users')
            .doc(_user!.uid)
            .update(updates)
            .timeout(const Duration(seconds: 8));

        if (updates.containsKey('name')) {
          try {
            await _user!.updateDisplayName(updates['name'] as String);
          } catch (_) {}
          _displayName = updates['name'] as String;
        }
        if (updates.containsKey('phone')) _phone = updates['phone'] as String;
        if (updates.containsKey('city')) _city = updates['city'] as String;
      }
      return true;
    } catch (e) {
      _error = _humanizeGenericError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> topUpBalance({int amount = AppStrings.topUpAmount}) async {
    if (_user == null) {
      _error = 'Войдите в аккаунт';
      notifyListeners();
      return false;
    }
    try {
      final docRef = _db.collection('users').doc(_user!.uid);
      final doc = await docRef.get().timeout(const Duration(seconds: 5));
      if (doc.exists) {
        await docRef.update({
          'balance': FieldValue.increment(amount),
        }).timeout(const Duration(seconds: 5));
      } else {
        await docRef.set({
          'name': _displayName ?? 'Пользователь',
          'email': _user!.email ?? '',
          'phone': _phone ?? '',
          'role': _role.name,
          'city': _city,
          'balance': amount,
          'rating': 0,
          'reviewsCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 5));
      }
      _balance += amount;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _humanizeGenericError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> chargeBalance(int amount) async {
    if (_user == null) return false;
    if (_balance < amount) return false;
    try {
      await _db.collection('users').doc(_user!.uid).update({
        'balance': FieldValue.increment(-amount),
      }).timeout(const Duration(seconds: 5));
      _balance -= amount;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Ошибка списания: $e');
      return false;
    }
  }

  String _humanizeAuthError(String code, [String? message]) {
    switch (code) {
      case 'invalid-email':
        return 'Неверный email';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован';
      case 'weak-password':
        return 'Слабый пароль (минимум 6 символов)';
      case 'network-request-failed':
        return 'Нет подключения к интернету';
      case 'operation-not-allowed':
        return 'Включите Email/Password в Firebase Console → Authentication → Sign-in method';
      case 'too-many-requests':
        return 'Слишком много попыток. Подождите и попробуйте позже';
      default:
        return 'Ошибка авторизации: $code\n${message ?? ""}';
    }
  }

  String _humanizeGenericError(Object e) {
    final msg = e.toString();
    if (msg.contains('PERMISSION_DENIED')) {
      return 'Нет прав на запись в Firestore.\nОткройте Firebase Console → Firestore → Rules и опубликуйте правила из README.';
    }
    if (msg.contains('NOT_FOUND')) {
      return 'Firestore Database не создана.\nFirebase Console → Build → Firestore → Create database.';
    }
    if (msg.contains('TimeoutException')) {
      return 'Превышено время ожидания. Проверьте интернет и правила Firestore.';
    }
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'Нет подключения к интернету';
    }
    if (msg.contains('PlatformException') && msg.contains('sign_in_failed')) {
      return 'Google Sign-In: добавьте SHA-1 ключ в Firebase Console (см. README).';
    }
    return 'Ошибка: ${msg.length > 200 ? msg.substring(0, 200) : msg}';
  }
}

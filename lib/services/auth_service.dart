import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'user_service.dart';

/// Gère l'authentification Firebase (email + téléphone) et le profil local.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _users = UserService();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  User? get firebaseUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  bool _initialized = false;
  bool get initialized => _initialized;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _currentUser = null;
      } else {
        _currentUser = await _users.getById(user.uid);
      }
      _initialized = true;
      notifyListeners();
    });
  }

  /// Inscription par email + mot de passe, puis création du profil pays.
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String countryCode,
    required String country,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final uid = cred.user!.uid;
    await _users.create(AppUser(
      uid: uid,
      fullName: fullName,
      email: email,
      phone: phone,
      country: country,
      countryCode: countryCode,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> loginWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> refreshProfile() async {
    final u = _auth.currentUser;
    if (u != null) {
      _currentUser = await _users.getById(u.uid);
      notifyListeners();
    }
  }
}

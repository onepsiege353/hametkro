import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final UserService _users = UserService();

  bool get initialized => _auth.initialized;
  bool get isSignedIn => _auth.isSignedIn;
  AppUser? get user => _auth.currentUser;
  User? get firebaseUser => _auth.firebaseUser;
  String get countryCode => user?.countryCode ?? 'CI';
  String get country => user?.country ?? "Côte d'Ivoire";

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String countryCode,
    required String country,
  }) {
    return _auth.registerWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      countryCode: countryCode,
      country: country,
    );
  }

  Future<void> login(String email, String password) =>
      _auth.loginWithEmail(email, password);

  Future<void> reset(String email) => _auth.sendResetEmail(email);

  Future<void> logout() => _auth.signOut();

  Future<void> refresh() => _auth.refreshProfile();

  Future<void> updateProfile({
    String? photoUrl,
    String? bio,
    String? fullName,
    String? country,
    String? countryCode,
    String? phone,
  }) async {
    final u = user;
    if (u == null) return;
    await _users.updateProfile(
      u.uid,
      fullName: fullName,
      photoUrl: photoUrl,
      bio: bio,
      country: country,
      countryCode: countryCode,
      phone: phone,
    );
    await _auth.refreshProfile();
  }
}

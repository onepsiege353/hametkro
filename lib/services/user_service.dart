import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserService {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('users');

  Future<void> create(AppUser user) async {
    await _col.doc(user.uid).set(user.toMap());
  }

  Future<AppUser?> getById(String uid) async {
    final snap = await _col.doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(snap.data() as Map<String, dynamic>);
  }

  Stream<AppUser?> streamById(String uid) {
    return _col.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromMap(snap.data() as Map<String, dynamic>);
    });
  }

  Future<void> updateProfile(
    String uid, {
    String? fullName,
    String? photoUrl,
    String? bio,
    String? country,
    String? countryCode,
    String? phone,
  }) async {
    final data = <String, dynamic>{
      if (fullName != null) 'fullName': fullName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (bio != null) 'bio': bio,
      if (country != null) 'country': country,
      if (countryCode != null) 'countryCode': countryCode,
      if (phone != null) 'phone': phone,
    };
    if (data.isNotEmpty) await _col.doc(uid).update(data);
  }
}

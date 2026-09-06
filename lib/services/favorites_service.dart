import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference _favDoc(String uid) =>
      _db.collection('favorites').doc(uid);

  Future<void> toggle(String uid, String listingId) async {
    final doc = _favDoc(uid);
    final snap = await doc.get();
    List<String> ids = [];
    if (snap.exists) {
      ids = List<String>.from((snap.data() as Map)['ids'] ?? []);
    }
    if (ids.contains(listingId)) {
      ids.remove(listingId);
    } else {
      ids.insert(0, listingId);
    }
    await doc.set({'ids': ids});
  }

  Future<bool> isFavorited(String uid, String listingId) async {
    final snap = await _favDoc(uid).get();
    if (!snap.exists) return false;
    return (List<String>.from((snap.data() as Map)['ids'] ?? []))
        .contains(listingId);
  }

  Stream<List<String>> streamIds(String uid) {
    return _favDoc(uid).snapshots().map((snap) => snap.exists
        ? List<String>.from((snap.data() as Map)['ids'] ?? [])
        : <String>[]);
  }
}

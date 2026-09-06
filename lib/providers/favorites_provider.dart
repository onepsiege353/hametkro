import 'package:flutter/foundation.dart';

import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _fav = FavoritesService();

  Set<String> _ids = {};
  Set<String> get ids => _ids;

  /// Démarre l'écoute des favoris pour l'utilisateur connecté.
  void watch(String? uid) {
    _fav.streamIds(uid ?? '').listen((list) {
      _ids = list.toSet();
      notifyListeners();
    });
  }

  bool isFav(String listingId) => _ids.contains(listingId);

  Future<void> toggle(String uid, String listingId) async {
    final wasFav = _ids.contains(listingId);
    // Mise à jour optimiste
    if (wasFav) {
      _ids.remove(listingId);
    } else {
      _ids.add(listingId);
    }
    notifyListeners();
    await _fav.toggle(uid, listingId);
  }
}

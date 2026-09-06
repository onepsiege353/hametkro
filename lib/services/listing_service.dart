import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/listing.dart';

/// Options de filtrage du fil d'annonces.
class ListingFilter {
  final String countryCode;
  final String? categoryId;
  final String search;
  final double? minPrice;
  final double? maxPrice;
  final String? condition;
  final bool onlyUrgent;

  ListingFilter({
    required this.countryCode,
    this.categoryId,
    this.search = '',
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.onlyUrgent = false,
  });
}

class ListingService {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('listings');

  Future<void> create(Listing listing) async {
    await _col.doc(listing.id).set(listing.toMap());
  }

  Future<Listing?> getById(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return Listing.fromMap(id, snap.data() as Map<String, dynamic>);
  }

  Stream<List<Listing>> streamBySeller(String sellerId) {
    return _col
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_parse);
  }

  /// Fil d'annonces du pays de l'utilisateur, avec filtres appliqués.
  /// Les recherches texte sont gérées côté client après récupération de la
  /// page la plus récente (simple & efficace pour démarrer).
  Future<List<Listing>> fetchFeed({
    required ListingFilter filter,
    int limit = 30,
    Listing? last,
  }) async {
    Query query = _col
        .where('countryCode', isEqualTo: filter.countryCode)
        .where('sold', isEqualTo: false)
        .orderBy('createdAt', descending: true);

    if (filter.categoryId != null) {
      query = query.where('categoryId', isEqualTo: filter.categoryId);
    }
    if (filter.condition != null) {
      query = query.where('condition', isEqualTo: filter.condition);
    }

    if (last != null) {
      query = query.startAfterDocument(
          await _col.doc(last.id).get());
    }
    query = query.limit(limit);

    final snap = await query.get();
    var list = _parse(snap);

    // Filtrage prix & recherche (client).
    if (filter.minPrice != null) {
      list = list.where((l) => l.price >= filter.minPrice!).toList();
    }
    if (filter.maxPrice != null) {
      list = list.where((l) => l.price <= filter.maxPrice!).toList();
    }
    if (filter.search.isNotEmpty) {
      final q = filter.search.toLowerCase();
      list = list
          .where((l) =>
              l.title.toLowerCase().contains(q) ||
              l.description.toLowerCase().contains(q) ||
              l.city.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Stream<List<Listing>> streamByIds(List<String> ids) {
    if (ids.isEmpty) return const Stream.empty();
    return _col.where(FieldPath.documentId, whereIn: ids).snapshots().map(
        (snap) => snap.docs
            .map((d) =>
                Listing.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> markSold(String id) =>
      _col.doc(id).update({'sold': true});

  Future<void> incrementViews(String id) async {
    await _col.doc(id).update({'views': FieldValue.increment(1)});
  }

  Future<void> toggleLike(String id, bool liked) async {
    await _col.doc(id).update({'likes': FieldValue.increment(liked ? 1 : -1)});
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  List<Listing> _parse(QuerySnapshot snap) => snap.docs
      .map((d) => Listing.fromMap(d.id, d.data() as Map<String, dynamic>))
      .toList();
}

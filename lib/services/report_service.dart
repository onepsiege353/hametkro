import 'package:cloud_firestore/cloud_firestore.dart';

/// Signalement d'une annonce ou d'un utilisateur (modération / sécurité).
class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const reasons = [
    'Arnaque ou escroquerie',
    'Produit non conforme à la photo',
    'Produit interdit',
    'Propos abusifs / harcèlement',
    'Spam',
    'Autre',
  ];

  Future<void> reportListing({
    required String reporterId,
    required String listingId,
    required String sellerId,
    required String reason,
    String? details,
  }) async {
    await _db.collection('reports').add({
      'type': 'listing',
      'reporterId': reporterId,
      'targetListingId': listingId,
      'targetUserId': sellerId,
      'reason': reason,
      'details': details,
      'status': 'open',
      'createdAt': DateTime.now(),
    });
  }

  Future<void> reportUser({
    required String reporterId,
    required String targetUserId,
    required String reason,
    String? details,
  }) async {
    await _db.collection('reports').add({
      'type': 'user',
      'reporterId': reporterId,
      'targetUserId': targetUserId,
      'reason': reason,
      'details': details,
      'status': 'open',
      'createdAt': DateTime.now(),
    });
  }
}

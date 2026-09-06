import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String authorId;
  final String authorName;
  final String targetId;
  final int rating; // 1..5
  final String text;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.targetId,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorName': authorName,
        'targetId': targetId,
        'rating': rating,
        'text': text,
        'createdAt': createdAt,
      };

  factory Review.fromMap(String id, Map<String, dynamic> map) => Review(
        id: id,
        authorId: map['authorId'] as String? ?? '',
        authorName: map['authorName'] as String? ?? '',
        targetId: map['targetId'] as String? ?? '',
        rating: (map['rating'] as num?)?.toInt() ?? 5,
        text: map['text'] as String? ?? '',
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      );
}

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Review>> streamForUser(String targetId) {
    return _db
        .collection('reviews')
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Review.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  /// Dépose un avis + recalcule la moyenne/note du vendeur.
  Future<void> addReview(Review review, double currentRating, int count) async {
    await _db.collection('reviews').doc(review.id).set(review.toMap());

    final newCount = count + 1;
    final newAvg =
        (currentRating * count + review.rating) / newCount;
    await _db.collection('users').doc(review.targetId).update({
      'rating': (newAvg * 10).roundToDouble() / 10,
      'reviewCount': newCount,
    });
  }
}

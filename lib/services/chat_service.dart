import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _convs => _db.collection('conversations');

  /// Ouvre (ou réutilise) une conversation liée à une annonce entre
  /// l'acheteur et le vendeur. Retourne l'id de la conversation.
  Future<String> openConversation({
    required String listingId,
    required String listingTitle,
    required String listingImage,
    required double listingPrice,
    required String buyerId,
    required String sellerId,
  }) async {
    final existing = await _convs
        .where('listingId', isEqualTo: listingId)
        .where('participantIds', arrayContains: buyerId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final conv = Conversation(
      id: _db.collection('x').doc().id,
      listingId: listingId,
      listingTitle: listingTitle,
      listingImage: listingImage,
      listingPrice: listingPrice,
      participantIds: [buyerId, sellerId],
      lastMessage: '',
      updatedAt: DateTime.now(),
    );
    await _convs.doc(conv.id).set(conv.toMap());
    return conv.id;
  }

  Stream<Conversation> streamConversation(String id) {
    return _convs.doc(id).snapshots().map((snap) {
      if (!snap.exists) {
        throw Exception('Conversation introuvable');
      }
      return Conversation.fromMap(id, snap.data() as Map<String, dynamic>);
    });
  }

  Stream<List<Conversation>> streamMyConversations(String userId) {
    return _convs
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Conversation.fromMap(
                d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    return _db
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                ChatMessage.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  /// Envoie un message simple.
  Future<void> sendText({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    await _send(conversationId, senderId, text: text);
  }

  /// Envoie une offre / contre-offre chiffrée (négociation intégrée au chat).
  Future<void> sendOffer({
    required String conversationId,
    required String senderId,
    required String text,
    required double amount,
  }) async {
    await _send(conversationId, senderId,
        text: text, isOffer: true, offerAmount: amount);
  }

  Future<void> _send(
    String conversationId,
    String senderId, {
    String? text,
    bool isOffer = false,
    double? offerAmount,
  }) async {
    final msg = ChatMessage(
      id: _db.collection('x').doc().id,
      conversationId: conversationId,
      senderId: senderId,
      text: text ?? '',
      createdAt: DateTime.now(),
      isOffer: isOffer,
      offerAmount: offerAmount,
    );
    await _db.collection('messages').doc(msg.id).set(msg.toMap());

    // Mise à jour du "dernier message" de la conversation.
    final label = isOffer
        ? 'Offre: $offerAmount FCFA'
        : (text ?? '').replaceAll('\n', ' ');
    await _convs.doc(conversationId).update({
      'lastMessage': label,
      'updatedAt': DateTime.now(),
    });
  }

  /// Marque les messages de l'autre partie comme lus pour cet utilisateur.
  Future<void> markRead(String conversationId, String readerId) async {
    final convSnap = await _convs.doc(conversationId).get();
    if (!convSnap.exists) return;
    final data = convSnap.data() as Map<String, dynamic>;
    final other = (data['participantIds'] as List)
        .where((p) => p != readerId)
        .cast<String>();
    for (final senderId in other) {
      final batch = _db.batch();
      final q = await _db
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('senderId', isEqualTo: senderId)
          .where('read', isEqualTo: false)
          .get();
      for (final doc in q.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    }
  }
}

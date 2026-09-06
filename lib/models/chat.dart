/// Une conversation est liée à une annonce (messagerie acheteur-vendeur).
class Conversation {
  final String id;
  final String listingId;
  final String listingTitle;
  final String listingImage;
  final double listingPrice;
  final List<String> participantIds; // 2 personnes
  final String lastMessage;
  final DateTime updatedAt;
  final Map<String, String> unreadCount; // uid -> nb non-lus

  Conversation({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingImage,
    required this.listingPrice,
    required this.participantIds,
    required this.lastMessage,
    required this.updatedAt,
    Map<String, String>? unreadCount,
  }) : unreadCount = unreadCount ?? {};

  Map<String, dynamic> toMap() => {
        'listingId': listingId,
        'listingTitle': listingTitle,
        'listingImage': listingImage,
        'listingPrice': listingPrice,
        'participantIds': participantIds,
        'lastMessage': lastMessage,
        'updatedAt': updatedAt,
        'unreadCount': unreadCount,
      };

  factory Conversation.fromMap(String id, Map<String, dynamic> map) =>
      Conversation(
        id: id,
        listingId: map['listingId'] as String? ?? '',
        listingTitle: map['listingTitle'] as String? ?? '',
        listingImage: map['listingImage'] as String? ?? '',
        listingPrice: (map['listingPrice'] as num?)?.toDouble() ?? 0,
        participantIds: List<String>.from(map['participantIds'] as List? ?? []),
        lastMessage: map['lastMessage'] as String? ?? '',
        updatedAt: (map['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
        unreadCount: Map<String, String>.from(map['unreadCount'] as Map? ?? {}),
      );
}

/// Message simple dans une conversation.
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool read;
  final double? offerAmount; // champ "négociation / contre-offre"
  final bool isOffer;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.read = false,
    this.offerAmount,
    this.isOffer = false,
  });

  Map<String, dynamic> toMap() => {
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text,
        'createdAt': createdAt,
        'read': read,
        'offerAmount': offerAmount,
        'isOffer': isOffer,
      };

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) =>
      ChatMessage(
        id: id,
        conversationId: map['conversationId'] as String? ?? '',
        senderId: map['senderId'] as String? ?? '',
        text: map['text'] as String? ?? '',
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        read: map['read'] as bool? ?? false,
        offerAmount: (map['offerAmount'] as num?)?.toDouble(),
        isOffer: map['isOffer'] as bool? ?? false,
      );
}

/// Modèle d'un utilisateur Hametkro.
/// Le compte est lié à un pays => le fil d'annonces affiche les articles du
/// même pays que l'utilisateur (marché local).
class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String? photoUrl;
  final String country; // ex: "Côte d'Ivoire"
  final String countryCode; // ex: "CI"
  final DateTime createdAt;
  final double rating; // moyenne des notes reçues (0..5)
  final int reviewCount;
  final int itemsSold;
  final bool isVerified; // badge "vérifié" (document/email/phone)
  final String? bio;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.country,
    required this.countryCode,
    required this.createdAt,
    this.rating = 0,
    this.reviewCount = 0,
    this.itemsSold = 0,
    this.isVerified = false,
    this.bio,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'country': country,
        'countryCode': countryCode,
        'createdAt': createdAt,
        'rating': rating,
        'reviewCount': reviewCount,
        'itemsSold': itemsSold,
        'isVerified': isVerified,
        'bio': bio,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid'] as String,
        fullName: map['fullName'] as String? ?? '',
        email: map['email'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        country: map['country'] as String? ?? '',
        countryCode: map['countryCode'] as String? ?? '',
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
        itemsSold: (map['itemsSold'] as num?)?.toInt() ?? 0,
        isVerified: map['isVerified'] as bool? ?? false,
        bio: map['bio'] as String?,
      );

  AppUser copyWith({
    String? photoUrl,
    double? rating,
    int? reviewCount,
    int? itemsSold,
    bool? isVerified,
    String? bio,
    String? country,
    String? countryCode,
  }) =>
      AppUser(
        uid: uid,
        fullName: fullName,
        email: email,
        phone: phone,
        photoUrl: photoUrl ?? this.photoUrl,
        country: country ?? this.country,
        countryCode: countryCode ?? this.countryCode,
        createdAt: createdAt,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        itemsSold: itemsSold ?? this.itemsSold,
        isVerified: isVerified ?? this.isVerified,
        bio: bio ?? this.bio,
      );
}

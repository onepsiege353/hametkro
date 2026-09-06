/// Modèle d'une annonce (article de seconde main).
class Listing {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final List<String> imageUrls;
  final double price;
  final String currency; // ex: FCFA
  final bool negotiable; // prix négociable
  final String condition; // neuf, comme neuf, bon état, correct, à réparer
  final String size; // taille / spécification (ex: M, 128 Go, essence...)
  final String country;
  final String countryCode;
  final String city;
  final String sellerId;
  final String sellerName;
  final String? sellerPhotoUrl;
  final bool sellerVerified;
  final DateTime createdAt;
  final bool sold;
  final int views;
  final int likes;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.imageUrls,
    required this.price,
    this.currency = 'FCFA',
    this.negotiable = true,
    required this.condition,
    this.size = '',
    required this.country,
    required this.countryCode,
    required this.city,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhotoUrl,
    this.sellerVerified = false,
    required this.createdAt,
    this.sold = false,
    this.views = 0,
    this.likes = 0,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'imageUrls': imageUrls,
        'price': price,
        'currency': currency,
        'negotiable': negotiable,
        'condition': condition,
        'size': size,
        'country': country,
        'countryCode': countryCode,
        'city': city,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerPhotoUrl': sellerPhotoUrl,
        'sellerVerified': sellerVerified,
        'createdAt': createdAt,
        'sold': sold,
        'views': views,
        'likes': likes,
      };

  factory Listing.fromMap(String id, Map<String, dynamic> map) => Listing(
        id: id,
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        categoryId: map['categoryId'] as String? ?? '',
        imageUrls: List<String>.from(map['imageUrls'] as List? ?? []),
        price: (map['price'] as num?)?.toDouble() ?? 0,
        currency: map['currency'] as String? ?? 'FCFA',
        negotiable: map['negotiable'] as bool? ?? false,
        condition: map['condition'] as String? ?? '',
        size: map['size'] as String? ?? '',
        country: map['country'] as String? ?? '',
        countryCode: map['countryCode'] as String? ?? '',
        city: map['city'] as String? ?? '',
        sellerId: map['sellerId'] as String? ?? '',
        sellerName: map['sellerName'] as String? ?? '',
        sellerPhotoUrl: map['sellerPhotoUrl'] as String?,
        sellerVerified: map['sellerVerified'] as bool? ?? false,
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        sold: map['sold'] as bool? ?? false,
        views: (map['views'] as num?)?.toInt() ?? 0,
        likes: (map['likes'] as num?)?.toInt() ?? 0,
      );

  bool get isNewPost =>
      DateTime.now().difference(createdAt).inDays <= 3;

  Listing copyWith({bool? sold, int? views, int? likes}) => Listing(
        id: id,
        title: title,
        description: description,
        categoryId: categoryId,
        imageUrls: imageUrls,
        price: price,
        currency: currency,
        negotiable: negotiable,
        condition: condition,
        size: size,
        country: country,
        countryCode: countryCode,
        city: city,
        sellerId: sellerId,
        sellerName: sellerName,
        sellerPhotoUrl: sellerPhotoUrl,
        sellerVerified: sellerVerified,
        createdAt: createdAt,
        sold: sold ?? this.sold,
        views: views ?? this.views,
        likes: likes ?? this.likes,
      );
}

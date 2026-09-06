import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/listing.dart';
import 'currency.dart';
import 'time_ago.dart';

/// Carte d'annonce affichée dans le fil.
class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ListingCard({super.key, required this.listing, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEDEA)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _image(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      trailing ?? const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${formatPrice(listing.price)} ${listing.currency}',
                    style: const TextStyle(
                      color: Color(0xFF009A44),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          listing.city.isNotEmpty
                              ? '${listing.city}, ${listing.country}'
                              : listing.country,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(timeAgo(listing.createdAt),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    Widget img;
    if (listing.imageUrls.isEmpty) {
      img = Container(
        color: const Color(0xFFE8EFEB),
        child: const Center(
          child: Icon(Icons.image_outlined,
              size: 40, color: Color(0xFF009A44)),
        ),
      );
    } else {
      img = CachedNetworkImage(
        imageUrl: listing.imageUrls.first,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: const Color(0xFFF0F3F1)),
        errorWidget: (_, __, ___) => Container(
          color: const Color(0xFFE8EFEB),
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        ),
      );
    }

    return Stack(
      children: [
        AspectRatio(aspectRatio: 1.15, child: img),
        if (listing.isNewPost)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('NOUVEAU',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ),
          ),
        if (listing.sold)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.45),
              alignment: Alignment.center,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('VENDU',
                    style: TextStyle(
                        color: Color(0xFFE6453C),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ),
            ),
          ),
      ],
    );
  }
}

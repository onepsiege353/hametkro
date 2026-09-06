import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/listing.dart';
import '../../providers/auth_provider.dart';
import '../../services/listing_service.dart';
import '../../services/review_service.dart';
import '../../services/user_service.dart';
import '../../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  final String sellerId;
  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(title: const Text('Profil vendeur')),
      body: StreamBuilder<AppUser?>(
        stream: UserService().streamById(sellerId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final seller = snap.data;
          if (seller == null) {
            return const Center(child: Text('Utilisateur introuvable'));
          }
          return Column(
            children: [
              _sellerCard(context, seller),
              const Divider(height: 1),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        indicatorColor: Color(0xFF009A44),
                        labelColor: Color(0xFF009A44),
                        tabs: [
                          Tab(text: 'Annonces'),
                          Tab(text: 'Avis'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _listings(context, seller),
                            _reviews(seller.uid),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sellerCard(BuildContext context, AppUser seller) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF009A44).withOpacity(0.15),
            backgroundImage: seller.photoUrl != null
                ? CachedNetworkImageProvider(seller.photoUrl!)
                : null,
            child: seller.photoUrl == null
                ? const Icon(Icons.person, color: Color(0xFF009A44), size: 32)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(seller.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  if (seller.isVerified)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.verified,
                          color: Color(0xFF009A44), size: 16),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(
                  '${seller.rating.toStringAsFixed(1)} ★ (${seller.reviewCount} avis) · ${seller.itemsSold} ventes',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.public, size: 14, color: Color(0xFF009A44)),
                  const SizedBox(width: 4),
                  Text(seller.country,
                      style: const TextStyle(fontSize: 12)),
                ]),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => _leaveReview(context, seller),
            style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: const Text('Noter', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _leaveReview(BuildContext context, AppUser seller) {
    final me = context.read<AuthProvider>().user;
    if (me == null || me.uid == seller.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu ne peux pas te noter toi-même')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ReviewSheet(target: seller),
    );
  }

  Widget _listings(BuildContext context, AppUser seller) {
    return StreamBuilder<List<Listing>>(
      stream: ListingService().streamBySeller(seller.uid),
      builder: (context, snap) {
        final items = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) return const Center(child: Text('Aucune annonce'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (c, i) => ListingCard(
            listing: items[i],
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: items[i])));
            },
          ),
        );
      },
    );
  }

  Widget _reviews(String uid) {
    return StreamBuilder<List<Review>>(
      stream: ReviewService().streamForUser(uid),
      builder: (context, snap) {
        final reviews = snap.data ?? [];
        if (reviews.isEmpty) {
          return const Center(child: Text('Aucun avis pour l\'instant'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: reviews.length,
          itemBuilder: (c, i) {
            final r = reviews[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${r.authorName} · ${'★' * r.rating}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(r.text),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  final AppUser target;
  const _ReviewSheet({required this.target});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 5;
  final _text = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Noter ${widget.target.fullName}',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            // simple sélecteur d'étoiles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setState(() => _rating = i),
                    icon: Icon(i <= _rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFC145), size: 34),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _text,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Ton avis sur la transaction',
                  alignLabelWithHint: true),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      final me = context.read<AuthProvider>().user;
                      final review = Review(
                        id: DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(),
                        authorId: me?.uid ?? '',
                        authorName: me?.fullName ?? 'Utilisateur',
                        targetId: widget.target.uid,
                        rating: _rating,
                        text: _text.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      await ReviewService().addReview(
                          review, widget.target.rating,
                          widget.target.reviewCount);
                      if (context.mounted) Navigator.pop(context);
                    },
              child: const Text('Envoyer mon avis'),
            ),
          ],
        ),
      ),
    );
  }
}

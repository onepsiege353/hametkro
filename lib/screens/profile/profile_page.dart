import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/listing.dart';
import '../../providers/auth_provider.dart';
import '../../services/listing_service.dart';
import '../../services/review_service.dart';
import '../../widgets/currency.dart';
import '../../widgets/listing_card.dart';
import '../listing/listing_detail_screen.dart';
import 'edit_profile_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _listingService = ListingService();
  int _segment = 0; // 0: annonces | 1: avis

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Non connecté')));
    }
    final me = auth.firebaseUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            title: const Text('Profil',
                style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          SliverToBoxAdapter(child: _header(context, user, me)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SegmentHeader(
                value: _segment,
                onChanged: (i) => setState(() => _segment = i)),
          ),
          if (_segment == 0)
            StreamBuilder<List<Listing>>(
              stream: _listingService.streamBySeller(user.uid),
              builder: (context, snap) {
                final items = snap.data ?? [];
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Aucune annonce publiée')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((c, i) {
                      return ListingCard(
                        listing: items[i],
                        onTap: () async {
                          await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: items[i])));
                          setState(() {});
                        },
                      );
                    }, childCount: items.length),
                  ),
                );
              },
            )
          else
            _reviewsSliver(user.uid),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, user, me) {
    final reviewService = ReviewService();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFF009A44).withOpacity(0.15),
                    backgroundImage: user.photoUrl != null
                        ? CachedNetworkImageProvider(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? const Icon(Icons.person,
                            color: Color(0xFF009A44), size: 34)
                        : null,
                  ),
                  if (user.isVerified)
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(0xFF009A44),
                        child: Icon(Icons.check, size: 13, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(user.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                      if (user.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified,
                              color: Color(0xFF009A44), size: 18),
                        ),
                    ]),
                    Text(user.email.isNotEmpty ? user.email : me?.email ?? '',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.public,
                          size: 14, color: Color(0xFF009A44)),
                      const SizedBox(width: 4),
                      Text(user.country,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat('${_ratingStars(user.rating)}', '${user.rating.toStringAsFixed(1)} ★'),
              _divider(),
              _stat('${user.reviewCount}', 'avis'),
              _divider(),
              _stat('${user.itemsSold}', 'ventes'),
            ],
          ),
          const SizedBox(height: 10),
          // Réseau de notes
          StreamBuilder<List<Review>>(
            stream: reviewService.streamForUser(user.uid),
            builder: (context, snap) {
              final n = snap.data?.length ?? user.reviewCount;
              return Align(
                alignment: Alignment.centerLeft,
                child: Text('$n avis reçus de la communauté',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _stat(String v, String l) {
    return Expanded(
      child: Column(
        children: [
          Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 28, color: const Color(0xFFEDEDEA));
  }

  String _ratingStars(double r) => '★';

  Widget _reviewsSliver(String uid) {
    return StreamBuilder<List<Review>>(
      stream: ReviewService().streamForUser(uid),
      builder: (context, snap) {
        final reviews = snap.data ?? [];
        if (reviews.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Aucun avis pour le moment')),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((c, i) {
              final r = reviews[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEDEDEA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r.authorName}  ·  ${'★' * r.rating}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(r.text, style: const TextStyle(fontSize: 13.5)),
                  ],
                ),
              );
            }, childCount: reviews.length),
          ),
        );
      },
    );
  }
}

class _SegmentHeader extends SliverPersistentHeaderDelegate {
  final int value;
  final ValueChanged<int> onChanged;
  _SegmentHeader({required this.value, required this.onChanged});

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _seg('Mes annonces', 0),
          ),
          Expanded(
            child: _seg('Avis reçus', 1),
          ),
        ],
      ),
    );
  }

  Widget _seg(String label, int i) {
    final sel = value == i;
    return InkWell(
      onTap: () => onChanged(i),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: sel ? const Color(0xFF009A44) : Colors.transparent,
                width: 3),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: sel ? const Color(0xFF009A44) : Colors.grey)),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SegmentHeader old) =>
      old.value != value || old.onChanged != onChanged;
}

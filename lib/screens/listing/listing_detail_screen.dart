import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/listing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/chat_service.dart';
import '../../services/listing_service.dart';
import '../../services/report_service.dart';
import '../../widgets/currency.dart';
import '../../widgets/time_ago.dart';
import '../chat/conversation_screen.dart';
import 'seller_profile_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final Listing listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _listings = ListingService();
  final _chat = ChatService();
  final _reports = ReportService();
  late Listing _listing = widget.listing;
  int _page = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _listings.incrementViews(_listing.id);
  }

  Future<void> _contact() async {
    final auth = context.read<AuthProvider>();
    final me = auth.user;
    if (me == null || me.uid == _listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('C\'est ta propre annonce.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final convId = await _chat.openConversation(
        listingId: _listing.id,
        listingTitle: _listing.title,
        listingImage:
            _listing.imageUrls.isNotEmpty ? _listing.imageUrls.first : '',
        listingPrice: _listing.price,
        buyerId: me.uid,
        sellerId: _listing.sellerId,
      );
      if (!mounted) return;
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => ConversationScreen(
                conversationId: convId,
                myUid: me.uid,
                listingId: _listing.id,
              )));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _report() {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ReportSheet(
        onReport: (reason, details) async {
          await _reports.reportListing(
            reporterId: auth.user?.uid ?? '',
            listingId: _listing.id,
            sellerId: _listing.sellerId,
            reason: reason,
            details: details,
          );
          if (ctx.mounted) Navigator.pop(ctx);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Merci, ton signalement a été envoyé.')));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().user;
    final isOwn = me?.uid == _listing.sellerId;
    final fav = context.watch<FavoritesProvider>();
    final cat = Category.byId(_listing.categoryId);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _content(context, me, cat)),
              if (!isOwn) _bottomBar(fav, me),
            ],
          ),
          // top gradient controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _topBar(),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 40, left: 8, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _roundBtn(
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).maybePop()),
          Row(
            children: [
              _roundBtn(icon: Icons.report_outlined, onTap: _report),
              const SizedBox(width: 8),
              _roundBtn(icon: Icons.share_outlined, onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Partage (lien annonce) disponible.')));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      child: IconButton(icon: Icon(icon), onPressed: onTap),
    );
  }

  Widget _content(BuildContext context, me, cat) {
    final co2 = estimateCo2Saved(_listing.categoryId);
    final waterLiters = co2 * 250;
    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: [
        _carousel(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_listing.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                              _listing.city.isNotEmpty
                                  ? '${_listing.city}, ${_listing.country}'
                                  : _listing.country,
                              style: const TextStyle(color: Colors.grey)),
                          Text('  ·  ${timeAgo(_listing.createdAt)}',
                              style:
                                  const TextStyle(color: Colors.grey)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('${formatPrice(_listing.price)} ${_listing.currency}',
                  style: const TextStyle(
                      color: Color(0xFF009A44),
                      fontSize: 26,
                      fontWeight: FontWeight.w900)),
              if (_listing.negotiable)
                const Text('Négociable · Paiement à la remise',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _specChip('Catégorie', '${cat?.emoji ?? '📦'} ${cat?.name ?? ''}'),
                  _specChip('État', _listing.condition),
                  if (_listing.size.isNotEmpty)
                    _specChip('Spécification', _listing.size),
                  if (_listing.views > 0)
                    _specChip('Vues', '${_listing.views}'),
                ],
              ),
              const SizedBox(height: 16),
              // Impact écologique (fonctionnalité signature Hametkro)
              _ecoCard(co2, waterLiters),
              const SizedBox(height: 16),
              const Text('Description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(_listing.description.isNotEmpty
                  ? _listing.description
                  : 'Aucune description.'),
              const SizedBox(height: 20),
              const Text('Vendeur',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _sellerCard(me),
            ],
          ),
        ),
      ],
    );
  }

  Widget _specChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDEDEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 10)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _ecoCard(double co2, double waterLiters) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE8F6F0), Color(0xFFEAF7EA)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF009A44).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: Color(0xFF009A44), size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Impact écologique 💚',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  'En achetant d\'occasion tu évites ~${co2.round()} kg de CO₂ (équiv. $waterLiters l d\'eau) pour la fabrication.',
                  style: const TextStyle(fontSize: 12.5, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sellerCard(me) {
    final isOwn = me?.uid == _listing.sellerId;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDEA)),
      ),
      child: Row(
        children: [
          _avatar(_listing.sellerPhotoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: isOwn
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SellerProfileScreen(
                              sellerId: _listing.sellerId))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(_listing.sellerName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800)),
                    ),
                    if (_listing.sellerVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.verified,
                            color: Color(0xFF009A44), size: 16),
                      ),
                  ]),
                  Text(isOwn ? 'C\'est ton annonce' : 'Voir le profil →',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? url) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF009A44).withOpacity(0.15),
      backgroundImage: url != null ? CachedNetworkImageProvider(url) : null,
      child: url == null
          ? const Icon(Icons.person, color: Color(0xFF009A44))
          : null,
    );
  }

  Widget _carousel() {
    final imgs = _listing.imageUrls;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              if (imgs.isEmpty)
                Container(
                  color: const Color(0xFFE8EFEB),
                  child: const Center(
                    child: Icon(Icons.image_outlined,
                        size: 60, color: Color(0xFF009A44)),
                  ),
                )
              else
                PageView.builder(
                  itemCount: imgs.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (c, i) => CachedNetworkImage(
                    imageUrl: imgs[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFFF0F3F1)),
                    errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFE8EFEB),
                        child: const Icon(Icons.broken_image_outlined,
                            size: 50, color: Colors.grey)),
                  ),
                ),
              if (imgs.length > 1)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_page + 1}/${imgs.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(FavoritesProvider fav, me) {
    final isFav = fav.isFav(_listing.id);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 10)],
      ),
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 10, bottom: 8 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          _favButton(fav, isFav),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _contact,
              icon: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.chat_bubble_outline),
              label: const Text('Contacter le vendeur'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _favButton(FavoritesProvider fav, bool isFav) {
    final me = context.read<AuthProvider>().user;
    return InkWell(
      onTap: () {
        if (me == null) return;
        fav.toggle(me.uid, _listing.id);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isFav ? const Color(0xFFFF6B5E).withOpacity(0.1) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEDEDEA)),
        ),
        child: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? const Color(0xFFE6453C) : Colors.grey,
        ),
      ),
    );
  }
}

/// Fiche de signalement d'une annonce.
class _ReportSheet extends StatefulWidget {
  final Future<void> Function(String reason, String? details) onReport;
  const _ReportSheet({required this.onReport});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String _reason = ReportService.reasons.first;
  final _details = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Signaler cette annonce',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _reason,
            items: [
              for (final r in ReportService.reasons)
                DropdownMenuItem(value: r, child: Text(r)),
            ],
            onChanged: (v) => setState(() => _reason = v ?? _reason),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _details,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Précisions (optionnel)',
                alignLabelWithHint: true),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE6453C)),
            onPressed: () => widget.onReport(_reason, _details.text),
            child: const Text('Envoyer le signalement'),
          ),
        ],
      ),
    );
  }
}

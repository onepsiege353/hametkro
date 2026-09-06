import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/listing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/listing_service.dart';
import '../../widgets/listing_card.dart';
import '../listing/listing_detail_screen.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesProvider>();
    final me = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      backgroundColor: const Color(0xFFF7F7F5),
      body: me == null
          ? const Center(child: Text('Connecte-toi pour voir tes favoris'))
          : fav.ids.isEmpty
              ? _empty()
              : _grid(fav.ids),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          const Text('Aucun favori pour l\'instant',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Touche le ❤ sur une annonce pour la retrouver ici.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _grid(Set<String> ids) {
    return _FavoriteList(ids: ids.toList());
  }
}

class _FavoriteList extends StatefulWidget {
  final List<String> ids;
  const _FavoriteList({required this.ids});

  @override
  State<_FavoriteList> createState() => _FavoriteListState();
}

class _FavoriteListState extends State<_FavoriteList> {
  final _service = ListingService();
  List<String> _ids = [];

  @override
  void initState() {
    super.initState();
    _ids = widget.ids;
  }

  @override
  void didUpdateWidget(covariant _FavoriteList old) {
    super.didUpdateWidget(old);
    if (old.ids.length != widget.ids.length ||
        old.ids.toSet().difference(widget.ids.toSet()).isNotEmpty) {
      _ids = widget.ids;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ids.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.favorite_border, color: Colors.grey, size: 60),
          SizedBox(height: 10),
          Center(
              child: Text('Aucun favori pour l\'instant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        ],
      );
    }
    return StreamBuilder<List<Listing>>(
      stream: _service.streamByIds(_ids),
      builder: (context, snap) {
        final items = snap.data ?? [];
        if (items.isEmpty && snap.connectionState != ConnectionState.waiting) {
          return const Center(child: Text('Favoris non disponibles'));
        }
        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (c, i) => ListingCard(
              listing: items[i],
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: items[i])));
              },
            ),
          ),
        );
      },
    );
  }
}

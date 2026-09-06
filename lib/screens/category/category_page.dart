import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/listing.dart';
import '../../providers/auth_provider.dart';
import '../../services/listing_service.dart';
import '../../widgets/listing_card.dart';
import '../listing/listing_detail_screen.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  String? _open;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: _open == null
          ? _grid()
          : _CategoryFeed(
              categoryId: _open!, onBack: () => setState(() => _open = null)),
    );
  }

  Widget _grid() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          title: Text('Catégories',
              style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              for (final c in Category.all)
                InkWell(
                  onTap: () => setState(() => _open = c.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEDEDEA)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c.emoji, style: const TextStyle(fontSize: 34)),
                        const SizedBox(height: 8),
                        Text(c.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        if (c.fashion)
                          const Text('✨ le plus vendu',
                              style: TextStyle(
                                  color: Color(0xFF009A44), fontSize: 10)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryFeed extends StatefulWidget {
  final String categoryId;
  final VoidCallback onBack;
  const _CategoryFeed({required this.categoryId, required this.onBack});

  @override
  State<_CategoryFeed> createState() => _CategoryFeedState();
}

class _CategoryFeedState extends State<_CategoryFeed> {
  final _service = ListingService();
  List<Listing>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _items = null;
    });
    try {
      final items = await _service.fetchFeed(
        filter: ListingFilter(
            countryCode: auth.countryCode, categoryId: widget.categoryId),
        limit: 60,
      );
      if (mounted) setState(() => _items = items);
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = Category.byId(widget.categoryId)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text('${cat.emoji}  ${cat.name}',
            style: const TextStyle(fontSize: 17)),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _items == null
            ? const Center(child: CircularProgressIndicator())
            : _items!.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 160),
                      Center(
                          child: Text('Aucune annonce dans cette catégorie')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items!.length,
                    itemBuilder: (c, i) => ListingCard(
                      listing: _items![i],
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ListingDetailScreen(listing: _items![i])));
                        _load();
                      },
                    ),
                  ),
      ),
    );
  }
}

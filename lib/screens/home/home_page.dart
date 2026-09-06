import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/listing.dart';
import '../../providers/auth_provider.dart';
import '../../services/countries.dart';
import '../../services/listing_service.dart';
import '../../widgets/listing_card.dart';
import '../listing/listing_detail_screen.dart';
import '../posting/post_listing_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = ListingService();
  final _search = TextEditingController();
  String? _categoryId;
  List<Listing> _items = [];
  bool _loading = true;
  double? _minPrice, _maxPrice;
  String? _condition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reload();
  }

  Future<void> _reload() async {
    final auth = context.read<AuthProvider>();
    setState(() => _loading = true);
    try {
      final items = await _service.fetchFeed(
        filter: ListingFilter(
          countryCode: auth.countryCode,
          categoryId: _categoryId,
          search: _search.text,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          condition: _condition,
        ),
      );
      if (mounted) setState(() => _items = items);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header(context, auth)),
              SliverToBoxAdapter(child: _categoryBar()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: _searchAndFilter(),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _empty(auth),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((c, i) {
                      final l = _items[i];
                      return ListingCard(
                        listing: l,
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ListingDetailScreen(listing: l)));
                          _reload();
                        },
                      );
                    }, childCount: _items.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    final firstName = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName.split(' ').first
        : 'Bienvenue';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour, $firstName 👋',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const Text('Que cherches-tu aujourd\'hui ?',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              // Badge marché = pays sélectionné
              InkWell(
                onTap: () => _changeCountry(context, auth),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF009A44).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.public,
                          color: Color(0xFF009A44), size: 16),
                      const SizedBox(width: 4),
                      Text(auth.countryCode,
                          style: const TextStyle(
                              color: Color(0xFF009A44),
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                      const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF009A44)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Voir les annonces de :',
              style: TextStyle(color: Colors.grey, fontSize: 11)),
          Text(auth.country,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }

  Future<void> _changeCountry(BuildContext context, AuthProvider auth) async {
    // Réutilise le CountryField via un bottom sheet réutilisable.
    final picked = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CountrySheet(selected: auth.countryCode),
    );
    if (picked != null) {
      await auth.updateProfile(countryCode: picked.$1, country: picked.$2);
      _reload();
    }
  }

  Widget _categoryBar() {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _chip('Tout', null),
          for (final c in Category.all) _chip(c.name, c.id),
        ],
      ),
    );
  }

  Widget _chip(String label, String? id) {
    final sel = _categoryId == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) {
          setState(() => _categoryId = sel ? null : id);
          _reload();
        },
      ),
    );
  }

  Widget _searchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _search,
            onSubmitted: (_) => _reload(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Rechercher…',
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () => _showFilterSheet(context),
          style: IconButton.styleFrom(
              backgroundColor: _isFiltered
                  ? const Color(0xFF009A44)
                  : const Color(0xFF009A44).withOpacity(0.1)),
          icon: Icon(Icons.tune,
              color: _isFiltered ? Colors.white : const Color(0xFF009A44)),
        ),
      ],
    );
  }

  bool get _isFiltered =>
      _minPrice != null || _maxPrice != null || _condition != null;

  Future<void> _showFilterSheet(BuildContext context) async {
    double? min = _minPrice;
    double? max = _maxPrice;
    String? cond = _condition;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Filtres',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Text('Fourchette de prix (FCFA)',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _priceField('Min', min,
                            onChanged: (v) => setSt(() => min = v))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _priceField('Max', max,
                            onChanged: (v) => setSt(() => max = v))),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('État',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final c in kConditions)
                      FilterChip(
                        label: Text(c),
                        selected: cond == c,
                        onSelected: (_) =>
                            setSt(() => cond = cond == c ? null : c),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setSt(() {
                            min = null;
                            max = null;
                            cond = null;
                          });
                        },
                        child: const Text('Réinitialiser'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _minPrice = min;
                            _maxPrice = max;
                            _condition = cond;
                          });
                          Navigator.pop(ctx);
                          _reload();
                        },
                        child: const Text('Appliquer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceField(String label, double? value,
      {required ValueChanged<double?> onChanged}) {
    final ctrl = TextEditingController(
        text: value != null ? value.toStringAsFixed(0) : '');
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
          labelText: label, isDense: true, contentPadding: EdgeInsets.all(12)),
      onChanged: (v) => onChanged(double.tryParse(v)),
    );
  }

  Widget _empty(AuthProvider auth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 60, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Aucune annonce trouvée',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Sois le premier à vendre en ${auth.country}. Publie une annonce gratuite !',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const PostListingScreen())),
            icon: const Icon(Icons.add),
            label: const Text('Publier une annonce'),
          ),
        ],
      ),
    );
  }
}

/// Feuille de choix de pays pour le header de l'accueil.
class _CountrySheet extends StatelessWidget {
  final String selected;
  const _CountrySheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Choisis ton pays (marché local)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: Countries.all.length,
              itemBuilder: (_, i) {
                final c = Countries.all[i];
                final sel = c.$1 == selected;
                return ListTile(
                  title: Text(c.$2,
                      style: TextStyle(
                          fontWeight:
                              sel ? FontWeight.w800 : FontWeight.w500,
                          color: sel
                              ? const Color(0xFF009A44)
                              : Colors.black)),
                  trailing: sel
                      ? const Icon(Icons.check_circle,
                          color: Color(0xFF009A44))
                      : null,
                  onTap: () => Navigator.pop(context, (c.$1, c.$2)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

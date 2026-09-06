import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import 'category/category_page.dart';
import 'chat/messages_page.dart';
import 'favorites/favorites_page.dart';
import 'home/home_page.dart';
import 'profile/profile_page.dart';
import 'posting/post_listing_screen.dart';

/// Navigation principale (5 onglets) : Accueil, Catégories, Publier,
/// Messages, Profil.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final List<Widget> _pages = const [
    HomePage(),
    CategoryPage(),
    PostCenter(),
    MessagesPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    context.read<FavoritesProvider>().watch(auth.user?.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _NavBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _NavBar({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onChanged,
      indicatorColor: const Color(0xFF009A44).withOpacity(0.14),
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF009A44)),
            label: 'Accueil'),
        NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: Color(0xFF009A44)),
            label: 'Catégories'),
        NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle, color: Color(0xFF009A44)),
            label: 'Vendre'),
        NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF009A44)),
            label: 'Messages'),
        NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF009A44)),
            label: 'Profil'),
      ],
    );
  }
}

/// Onglet central "Vendre" => écran de publication d'annonce.
class PostCenter extends StatelessWidget {
  const PostCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: _BigSellButton(),
    );
  }
}

class _BigSellButton extends StatelessWidget {
  const _BigSellButton();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Vends un article en 1 min',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Téléphone, friperie, voiture…',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const PostListingScreen())),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Publier une annonce'),
        ),
      ],
    );
  }
}

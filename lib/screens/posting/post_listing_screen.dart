import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/category.dart';
import '../../models/listing.dart';
import '../../providers/auth_provider.dart';
import '../../services/listing_service.dart';
import '../../services/storage_service.dart';

class PostListingScreen extends StatefulWidget {
  const PostListingScreen({super.key});

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  final _size = TextEditingController();

  final List<File> _images = [];
  String _categoryId = 'fashion';
  String _condition = 'Bon état';
  bool _negotiable = true;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _city.dispose();
    _size.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final available = await picker.pickMultiImage(limit: 6 - _images.length);
    if (available.isNotEmpty) {
      setState(() {
        for (final x in available) {
          if (_images.length < 6) _images.add(File(x.path));
        }
      });
    }
  }

  Future<void> _publish() async {
    if (!_form.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ajoute au moins une photo'),
          backgroundColor: Colors.red));
      return;
    }
    final auth = context.read<AuthProvider>();
    final me = auth.user;
    if (me == null) return;

    setState(() => _saving = true);
    try {
      final storage = StorageService();
      final urls = <String>[];
      for (final img in _images) {
        urls.add(await storage.uploadImage(
            file: img, folder: 'listings', uid: me.uid));
      }

      final id = const Uuid().v4();
      final listing = Listing(
        id: id,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        categoryId: _categoryId,
        imageUrls: urls,
        price: double.parse(_price.text.replaceAll(' ', '')),
        negotiable: _negotiable,
        condition: _condition,
        size: _size.text.trim(),
        country: auth.country,
        countryCode: auth.countryCode,
        city: _city.text.trim(),
        sellerId: me.uid,
        sellerName: me.fullName,
        sellerPhotoUrl: me.photoUrl,
        sellerVerified: me.isVerified,
        createdAt: DateTime.now(),
      );
      await ListingService().create(listing);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce publiée avec succès 🎉')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erreur lors de la publication. Réessaie.'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Publier une annonce')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photos
            Text('Photos (${_images.length}/6)',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _photosGrid(),
            const SizedBox(height: 16),

            Text('Catégorie',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _categoryDropdown(),
            const SizedBox(height: 16),

            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'Titre *',
                  hintText: 'ex: Samsung Galaxy A54, robe africaine, iPhone…'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Décris l\'état, les défauts, l\'année, la raison de la vente…',
                  alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Prix (FCFA) *',
                        prefixText: ''),
                    validator: (v) {
                      final x = double.tryParse(v?.replaceAll(' ', '') ?? '');
                      return (x == null || x <= 0) ? 'Prix invalide' : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _city,
                    decoration: const InputDecoration(
                        labelText: 'Ville',
                        hintText: 'ex: Abidjan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _conditionPicker(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _size,
              decoration: const InputDecoration(
                  labelText: 'Taille / spécification',
                  hintText: 'ex: M, 128 Go, 5 portes…'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Prix négociable'),
              subtitle: const Text('Permet aux acheteurs de faire une offre'),
              value: _negotiable,
              activeTrackColor: const Color(0xFF009A44),
              onChanged: (v) => setState(() => _negotiable = v),
            ),
            const SizedBox(height: 8),
            // Réassurance sécurité
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF009A44)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ton annonce sera visible dans ${context.read<AuthProvider>().country} (marché ${context.read<AuthProvider>().countryCode})',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saving ? null : _publish,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_saving ? 'Publication…' : 'Publier l\'annonce'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photosGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final f in _images)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(f, fit: BoxFit.cover, width: 120, height: 120),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _images.remove(f)),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        if (_images.length < 6)
          InkWell(
            onTap: _pickImages,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8EFEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF009A44).withOpacity(0.4),
                    style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: Color(0xFF009A44)),
                  SizedBox(height: 4),
                  Text('Ajouter',
                      style: TextStyle(
                          color: Color(0xFF009A44), fontSize: 11)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _categoryId,
      items: [
        for (final c in Category.all)
          DropdownMenuItem(
              value: c.id, child: Text('${c.emoji}  ${c.name}')),
      ],
      onChanged: (v) => setState(() => _categoryId = v ?? _categoryId),
    );
  }

  Widget _conditionPicker() {
    return DropdownButtonFormField<String>(
      initialValue: _condition,
      items: [
        for (final c in kConditions) DropdownMenuItem(value: c, child: Text(c)),
      ],
      decoration: const InputDecoration(labelText: 'État *'),
      onChanged: (v) => setState(() => _condition = v ?? _condition),
    );
  }
}

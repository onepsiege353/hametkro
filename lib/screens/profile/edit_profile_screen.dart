import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/countries.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _name;
  final _bio = TextEditingController();
  late String _countryCode;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    _name = TextEditingController(text: u?.fullName ?? '');
    _bio = TextEditingController(text: u?.bio ?? '');
    _countryCode = u?.countryCode ?? 'CI';
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final country = Countries.byCode(_countryCode);
    await auth.updateProfile(
      fullName: _name.text.trim(),
      bio: _bio.text.trim(),
      countryCode: _countryCode,
      country: country?.$2 ?? '',
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profil mis à jour ✅')));
    }
  }

  Future<void> _logout() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Tu pourras te reconnecter à tout moment.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Déconnexion')),
        ],
      ),
    );
    if (sure == true) {
      await context.read<AuthProvider>().logout();
    }
  }

  void _changePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Import de photo : utilise image_picker (prêt dans le code).')));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier mon profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF009A44).withOpacity(0.15),
                  backgroundImage: user?.photoUrl != null
                      ? CachedNetworkImageProvider(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? const Icon(Icons.person, color: Color(0xFF009A44), size: 40)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _changePhoto,
                    child: const CircleAvatar(
                      radius: 13,
                      backgroundColor: Color(0xFF009A44),
                      child: Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nom complet'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _bio,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Bio / description', alignLabelWithHint: true),
          ),
          const SizedBox(height: 14),
          _countryPicker(context),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Enregistrer')),
          const SizedBox(height: 30),
          OutlinedButton.icon(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE6453C),
                side: const BorderSide(color: Color(0xFFE6453C))),
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  Widget _countryPicker(BuildContext context) {
    final sel = Countries.byCode(_countryCode);
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          builder: (ctx) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final c in Countries.all)
                  ListTile(
                    title: Text(c.$2),
                    trailing: c.$1 == _countryCode
                        ? const Icon(Icons.check, color: Color(0xFF009A44))
                        : null,
                    onTap: () {
                      setState(() => _countryCode = c.$1);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
      child: InputDecorator(
        decoration: const InputDecoration(
            labelText: 'Mon pays (marché)',
            prefixIcon: Icon(Icons.public)),
        child: Text(sel?.$2 ?? ''),
      ),
    );
  }
}

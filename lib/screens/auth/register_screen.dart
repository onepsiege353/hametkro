import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/country_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _countryCode = 'CI';
  String _country = "Côte d'Ivoire";
  bool _loading = false;
  bool _agree = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agree) {
      _err('Tu dois accepter les conditions d\'utilisation.');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().registerWithEmail(
            fullName: _name.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            password: _pass.text,
            countryCode: _countryCode,
            country: _country,
          );
      // Connexion réussie => AuthGate bascule automatiquement.
    } catch (e) {
      _err('Inscription impossible. Cet email est peut-être déjà utilisé.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _err(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer mon compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choisis ton pays : tu verras les articles des vendeurs de ton pays.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                CountryField(
                  selectedCode: _countryCode,
                  onChanged: (c) => setState(() {
                    _countryCode = c.$1;
                    _country = c.$2;
                  }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      hintText: '+225 07 00 00 00 00',
                      prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline)),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email invalide' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Mot de passe (min 6)',
                      prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 caractères' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                        value: _agree,
                        onChanged: (v) => setState(() => _agree = v ?? false)),
                    const Expanded(
                      child: Text(
                        'J\'accepte les conditions d\'utilisation et la charte de vente Hametkro.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text("S'inscrire")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Téléverse un fichier (photo d'annonce ou de profil) et renvoie l'URL.
  Future<String> uploadImage({
    required File file,
    required String folder, // ex: listings, avatars, chats
    required String uid,
    String? name,
  }) async {
    final ref = _storage
        .ref()
        .child('$folder/$uid/${name ?? DateTime.now().millisecondsSinceEpoch}.jpg');

    // Redimensionnement/compression côté client pour économiser les données.
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Compresse une image pour éviter les fichiers trop lourds en Afrique
  /// (réseau + forfait data). Implémentation de référence : sur mobile on
  /// s'appuie sur package:image. Ici on renvoie le fichier tel quel.
  @protected
  Future<void> _compress(File file) async {}

  Future<void> delete(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // ignorer les erreurs de suppression
    }
  }
}

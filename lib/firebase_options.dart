// ⚠️ FICHIER GÉNÉRÉ (modèle).
//
// Deux façons de le remplir :
//   Option A (recommandée) — génère automatiquement avec tes vraies valeurs :
//       dart pub global activate flutterfire_cli
//       flutterfire configure
//     → Ceci écrase ce fichier avec DefaultFirebaseOptions valides.
//
//   Option B (manuelle) — remplace chaque "REPLACE_ME_..." par tes valeurs de
//   la console Firebase → Paramètres du projet → Vos applications.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return web; // adapter si besoin
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "REPLACE_ME_WEB_API_KEY",
    appId: "REPLACE_ME_WEB_APP_ID",
    messagingSenderId: "REPLACE_ME_SENDER_ID",
    projectId: "REPLACE_ME_PROJECT_ID",
    authDomain: "REPLACE_ME.firebaseapp.com",
    storageBucket: "REPLACE_ME.appspot.com",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "REPLACE_ME_ANDROID_API_KEY",
    appId: "REPLACE_ME_ANDROID_APP_ID",
    messagingSenderId: "REPLACE_ME_SENDER_ID",
    projectId: "REPLACE_ME_PROJECT_ID",
    storageBucket: "REPLACE_ME.appspot.com",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "REPLACE_ME_IOS_API_KEY",
    appId: "REPLACE_ME_IOS_APP_ID",
    messagingSenderId: "REPLACE_ME_SENDER_ID",
    projectId: "REPLACE_ME_PROJECT_ID",
    storageBucket: "REPLACE_ME.appspot.com",
    iosBundleId: "com.hametkro.hametkro",
  );
}

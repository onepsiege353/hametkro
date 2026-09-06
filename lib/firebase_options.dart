// Configuration Firebase réelle du projet "hametkro".
// NB: les clés API Firebase ne sont pas des secrets (la sécurité vient des règles).
//
// Android & Web sont branchés (valeurs réelles). iOS : complète ici quand tu
// auras ajouté l'app iOS (apiKey/appId iOS) — même procédure que l'Android.
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
        return web;
      default:
        return android;
    }
  }

  // App Web (utilisée par la version web)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAf0gcAGddEDkOiJMUrjFUrsd-MzvgYLaQ",
    appId: "1:1071001951580:web:7217e57ea6e9362e41b599",
    messagingSenderId: "1071001951580",
    projectId: "hametkro",
    authDomain: "hametkro.firebaseapp.com",
    storageBucket: "hametkro.firebasestorage.app",
  );

  // App Android (package com.hametkro.hametkro)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBPYT-GhUqwAu-bnDWNwS9gOOCA5QKrurA",
    appId: "1:1071001951580:android:0e27e311b8fe648b41b599",
    messagingSenderId: "1071001951580",
    projectId: "hametkro",
    storageBucket: "hametkro.firebasestorage.app",
  );

  // App iOS — REMPLACE avec les valeurs de ton GoogleService-Info.plist iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "REPLACE_IOS_API_KEY",
    appId: "REPLACE_IOS_APP_ID",
    messagingSenderId: "1071001951580",
    projectId: "hametkro",
    storageBucket: "hametkro.firebasestorage.app",
    iosBundleId: "com.hametkro.hametkro",
  );
}

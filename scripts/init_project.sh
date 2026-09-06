#!/usr/bin/env bash
# Initialise les dossiers de plateforme (android/ios) + config.
# À exécuter depuis la racine du projet hametkro.
set -e

echo "→ Génération des dossiers Android/iOS…"
flutter create --org com.hametkro --project-name hametkro \
  --platforms android,ios .

echo "→ Dépendances…"
flutter pub get

echo ""
echo "Étape suivante (manuel) :"
echo "  1) Crée ton projet Firebase + app Android/iOS (console.firebase.google.com)"
echo "  2) Place android/app/google-services.json"
echo "  3) Lance :  flutterfire configure   (génère lib/firebase_options.dart)"
echo "  4) flutter run"

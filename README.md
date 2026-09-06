# 🔁 Hametkro — Marché de seconde main (Android + iOS)

> « Donne une seconde vie à tes objets. »
> Hametkro est une application **Android & iOS** de **revente d'articles de seconde main**
> (inspirée de l'ancienne app **Vendito**), pensée d'abord pour l'**Afrique de l'Ouest**
> (Côte d'Ivoire 🇨🇮 en lancement), puis ouvrable **au monde entier** : chaque utilisateur
> choisit son **pays** et voit les annonces publiées dans **son** pays.

---

## 🎯 Le concept en une phrase
Un **Vinted + eBay local** où chacun **inscrit/connexion**, **publie des annonces**
(photos, catégorie, taille, état, prix), parcourt un **fil filtré par pays** et par
catégorie (**téléphones, ordinateurs, voitures, mode/friperie, meubles…**), discute
avec le vendeur via une **messagerie liée à l'annonce**, met en **favoris**, **note**
les vendeurs et peut **signaler** les annonces.

---

## ✨ Fonctionnalités « révolutionnaires » propres à Hametkro
1. **Impact écologique mesuré** 💚 — chaque annonce affiche le CO₂ et les litres d'eau
   économisés par l'achat d'occasion (signature Hametkro).
2. **Négociation intégrée au chat** 🤝 — propose un prix/contre-offre directement dans
   la conversation (bulle « OFFRE »).
3. **Marché par pays** 🌍 — un compte = un pays = un fil d'annonces local automatique.
4. **Badge « vendeur vérifié »** ✅ et **notes publiques** ★ (confiance entre inconnus).
5. **Publication en ~1 minute**, légère en données (compression des photos pour les
   réseaux africains).
6. **Sécurité : signalement** et charte anti-arnaque (conseils affichés).

---

## 🧱 Architecture technique
- **Framework** : [Flutter](https://flutter.dev) (une seule base de code = **Android + iOS**)
- **Backend** : **Firebase**
  - `Firebase Auth` → inscription / connexion (email + téléphone)
  - `Firestore` → annonces, profils, conversations, messages, favoris, avis, signalements
  - `Firebase Storage` → photos d'annonces et avatars
  - `Firebase Cloud Messaging` (optionnel) → notifications de messages
- **État** : Provider
- **CI/CD** : GitHub Actions (compile l'APK automatiquement à chaque push)

### Arborescence
```
hametkro/
├─ lib/
│  ├─ main.dart                # point d'entrée + branchement Firebase
│  ├─ theme.dart               # palette & style Hametkro
│  ├─ models/                  # User, Listing, Conversation, Message, Review, Category
│  ├─ services/                # auth, users, listings, chat, storage, favoris, avis, signalements
│  ├─ providers/               # AuthProvider, FavoritesProvider
│  ├─ screens/
│  │  ├─ auth/                 # Splash, Login, Register
│  │  ├─ home/                 # fil d'annonces + recherche + filtres + choix pays
│  │  ├─ category/             # navigation par catégories
│  │  ├─ listing/              # fiche détaillée, profil vendeur
│  │  ├─ chat/                 # liste messages + conversation (avec offre)
│  │  ├─ favorites/            # favoris
│  │  ├─ profile/              # profil, mes annonces, avis reçus
│  │  └─ posting/              # publier une annonce (photos/catégorie/taille/état/prix)
│  └─ widgets/
├─ firebase/                   # règles Firestore & Storage + config
├─ .github/workflows/build_apk.yml   # CI → APK automatique
├─ assets/icon_hametkro.png
└─ scripts/
```

---

## 🚀 Démarrer (développeur)
### 1) Générer les dossiers Android/iOS
```bash
flutter create --org com.hametkro --project-name hametkro --platforms android,ios .
flutter pub get
```

### 2) Brancher Firebase
1. Crée un projet sur [console.firebase.google.com](https://console.firebase.google.com).
2. Ajoute une app **Android** (package `com.hametkro.hametkro`) puis une app **iOS**.
3. **Android** : télécharge `google-services.json` → place-le dans `android/app/`.
4. **iOS** : télécharge `GoogleService-Info.plist` → ajoute-le dans Xcode.
5. **Firestore + Storage + Auth** : active les services (voir les règles dans `/firebase`).
6. Colle `firebase/firebase_options.dart` en bas de tes valeurs dans `lib/main.dart`
   **ou** (recommandé) génère un fichier officiel :
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   → il crée `lib/firebase_options.dart` ; remplace l'appel dans `main.dart` par
   `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.

### 3) Lancer l'application
```bash
flutter run            # émulateur / téléphone
flutter build apk      # APK release
```

---

## 🤖 Compilation automatique (GitHub Actions)
Le fichier `.github/workflows/build_apk.yml` compile **automatiquement l'APK** à chaque
`git push` sur `main`/`develop`. L'APK est déposé dans les **artefacts** de l'onglet
Actions.

1. Mets ton dépôt sur GitHub.
2. **Ajoute le secret** `FIREBASE_CONFIG` (contenu du `google-services.json`) :
   *Repo → Settings → Secrets and variables → Actions.*
3. Pousse :
```bash
git init && git add . && git commit -m "Hametkro initial"
git branch -M main
git remote add origin https://github.com/TON_COMPTE/hametkro.git
git push -u origin main
```

---

## 📦 Publier sur le Play Store
1. Dans `android/app/build.gradle` remplace `applicationId` si besoin.
2. Génère une **clé de signature** (`keytool`), place `key.properties` dans `android/`.
3. `flutter build appbundle --release` (via la CI : artefact `.aab`).
4. Crée un **compte développeur Google Play** (25 $ unique).
5. Dans la **Play Console** : *Create app* → upload du `.aab` → remplis fiche, politique
   de confidentialité, déclaration `fcm.data` si notifications.
6. Publie (test interne → test fermé → production).

## 📦 Publier sur l'App Store
1. `flutter build ios --release`, ouvre `ios/Runner.xcworkspace` dans Xcode.
2. Règle le **Bundle ID**, les signatures, ajoute `GoogleService-Info.plist`.
3. Compte développeur **Apple** (99 $/an).
4. Archive → **App Store Connect** → remplis la fiche → soumets pour validation.

---

## 🔒 Bonnes pratiques sécurité / modération
- Les règles Firestore dans `firebase/firestore.rules` n'autorisent une personne à
  écrire que **ses propres** données et à **ne pas se noter soi-même**.
- Les **signalements** alimentent une file de modération.
- Affiche toujours le **conseil sécurité** : « Paie à la remise, jamais par avance. »

---

## 🗺️ Feuille de route
- [ ] MVP : pays pilote (Côte d'Ivoire) → test fermé
- [ ] Paiement mobile sécurisé (Mobile Money / Orange Money) au dépôt en main propre
- [ ] Notifications push (nouveau message, prix baissé)
- [ ] « Boost » payant pour les annonces + option « Vendre en une photo »
- [ ] Badge vérifié par téléphone + carte d'identité
- [ ] Extension aux 25+ pays de la liste (`lib/services/countries.dart`)

> ⚠️ Pour une vraie mise en ligne il te faudra tes **comptes** Firebase / GitHub /
> Google Play / Apple. Ce dépôt te fournit **100 % du code + config + CI + guide** ;
> il ne reste qu'à y brancher tes identifiants.

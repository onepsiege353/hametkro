# Activer Firebase côté Android (après `flutter create`)

Une fois les dossiers `android/` générés, applique ces 2 modifications.

## 1) `android/build.gradle` (à la racine Android)
Ajoute le plugin Google Services (bloc `buildscript`/`plugins`) :

```gradle
plugins {
    id "com.android.application" version "8.1.0" apply false
    id "org.jetbrains.kotlin.android" version "1.9.0" apply false
    // ▼ ajoute cette ligne
    id "com.google.gms.google-services" version "4.4.1" apply false
}
```

## 2) `android/app/build.gradle`
En bas du fichier, ajoute :

```gradle
apply plugin: 'com.google.gms.google-services'
```

## 3) Config Firebase
- Télécharge `google-services.json` (console Firebase → ton app Android → *Télécharger google-services.json*).
- Place-le dans `android/app/`.

> Le pipeline GitHub Actions (`build_apk.yml`) fait cette injection automatiquement
> à partir du **secret** `FIREBASE_CONFIG` (le contenu du `google-services.json`).

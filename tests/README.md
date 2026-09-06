# Tests Hametkro (chat + présence)

Trois niveaux de tests. Tous testent le **vrai code** de `webapp/index.html`.

## 1. Tests logiques (Node, sans navigateur)
Chargent le script réel dans une VM Node avec stubs DOM/Firebase.

```bash
node tests/chat_logic.test.js        # 25 assertions (déterministe, unread, XSS, bulles, partage, présence)
node tests/chat_integration.test.js  # 10 assertions (échange acheteur<->vendeur simulé, arrayUnion anti-course)
```

## 2. Tests E2E (Playwright, navigateur headless, **production réelle**)
Crée de **vrais comptes temporaires** sur ton projet Firebase et exerce l'app sur
`https://onepsiege353.github.io/hametkro/`.

```bash
cd tests/e2e
npm i playwright
npx playwright install chromium
node run_e2e.js
```

Couverture E2E :
- vendeur publie une annonce (upload photo réel) ;
- acheteur trouve l'annonce, ouvre « Discuter » ;
- échange de messages (si règles publiées) ;
- **badges de présence** : « En ligne » quand le vendeur est connecté, « Hors ligne » après fermeture.

> ⚠️ Le **chat** ne peut pas s'ouvrir tant que les règles Firestore
> `conversations`/`messages` **ne sont pas publiées** sur le projet (voir ci-dessous).
> Tant que ce n'est pas fait, le test affiche un message de SKIP et poursuit sur la
> présence — le blocage est volontairement visible et explicite.

---

## 🔧 À FAIRE À LA MAIN : publier les règles Firestore (débloque le chat)

Le workflow GitHub Pages ne déploie **que les fichiers web** (`webapp/`), jamais les
règles Firestore. Pourtant les règles `conversations`/`messages` sont **indispensables**
au chat et existent déjà dans `firebase/firestore.rules`.

### Méthode A — Console Firebase (recommandée, 2 min)
1. Va sur https://console.firebase.google.com → projet **hametkro**.
2. Menu de gauche : **Firestore Database** → onglet **Rules**.
3. Remplace tout le contenu par celui du fichier `firebase/firestore.rules`.
4. Bouton **Publier**.

### Méthode B — Firebase CLI
```bash
npm i -g firebase-tools
firebase login            # connecte-toi dans le navigateur
cd hametkro
firebase use --add        # choisis le projet hametkro
firebase deploy --only firestore:rules
```

### Extrait minimal (si tu préfères n'ajouter que le chat)
```js
match /conversations/{id} {
  allow read, update: if request.auth != null
    && request.auth.uid in resource.data.participantIds;
  allow create: if request.auth != null
    && request.resource.data.participantIds.size() == 2
    && request.auth.uid in request.resource.data.participantIds;
  allow delete: if false;
}
match /messages/{id} {
  allow read, create: if request.auth != null
    && exists(/databases/$(database)/documents/conversations/$(request.resource.data.conversationId));
  allow update, delete: if false;
}
```

Une fois publiées, relance `node run_e2e.js` : les étapes du chat passeront.

---

## Corrigés en cours de route (découverts par les tests)
1. **Sortie intempestive du fil** : les snapshots globaux ré-affichaient l'accueil pendant le chat → verrou `chatIsOpen()`.
2. **Perte de saisie** : `renderConv()` reconstruisait toute la page à chaque snapshot → rendu incrémental des seules bulles.
3. **Perte de message en concurrence** : envoi non atomique → `FieldValue.arrayUnion`.
4. **Modal cachant le chat** : depuis une annonce, « Discuter » ouvrait le chat *sous* le modal → `closeAll()` avant d'ouvrir.
5. **Présence** : heartbeat 20 s sur le profil `users/{uid}` (aucune règle supplémentaire requise).

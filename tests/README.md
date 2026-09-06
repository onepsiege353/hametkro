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
node e2e_chat_real.js    # chat de bout en bout (2 contextes isolés) → 9 assertions
node run_e2e.js          # chat + présence (badges En ligne / Hors ligne)
```

Couverture du chat réel (`e2e_chat_real.js`) :
1. vendeur publie une annonce (upload photo réel, vérifiée en Firestore) ;
2. acheteur (contexte isolé) trouve l'annonce et ouvre « Discuter » ;
3. l'acheteur envoie un message ;
4. le vendeur (autre contexte) l'ouvre et reçoit le message ;
5. le vendeur répond ;
6. l'acheteur reçoit la réponse **sans être éjecté** du fil ;
7. les deux messages sont **persistés** en Firestore.

Couverture de la présence (`run_e2e.js`) : badges « En ligne » quand le vendeur est
connecté, « Hors ligne » après fermeture (>60 s sans heartbeat).

> ✅ **Règles Firestore publiées** (06-09). Le chat passe intégralement. Seule la
> correction importante du `read` de `conversations` reste à conserver (voir ci-dessous).

---

## 🔧 Règles Firestore — ce qu'il faut retenir (déjà appliqué, mais fragile)

Le workflow GitHub Pages ne déploie **que** les fichiers web (`webapp/`), jamais les
règles Firestore. Les règles de production sont publiées et correspondent à
`firebase/firestore.rules`. **À chaque modification de ce fichier, il faut re-publier.**

### Correction critique (piège Firestore) — déjà en place
L'app fait `ref.get()` sur une conversation **avant** de la créer pour tester son
existence. Si la règle `read` exige d'être participant (`uid in resource.data.participantIds`),
la lecture d'un document **absent** (`resource == null`) est **refusée** → le chat
échouait en `permission-denied`. La règle doit donc autoriser le doc absent :

```js
match /conversations/{id} {
  allow read: if request.auth != null && (
    resource == null || request.auth.uid in resource.data.participantIds);
  ...
}
```

### Ne pas sur-restreindre `listings.create`
La règle de création d'annonces ne doit **pas** exiger `price is number` ni d'autres
contraintes que l'app n'émet pas réellement, sinon toute publication échoue en
`permission-denied`. Garder : `allow create: if request.auth != null
&& request.resource.data.sellerId == request.auth.uid;`.

### Re-publier
Console Firebase → Firestore → Rules → coller `firebase/firestore.rules` → Publier.
(Le compte de service du sandbox, `firebase-adminsdk-fbsvc@hametkro…`, ne peut pas
utiliser `firebase deploy` — l'API serviceusage lui est fermée — mais peut publier les
rulesets via l'API REST `firebaserules.googleapis.com`.)

---

## Corrigés en cours de route (découverts par les tests)
1. **Sortie intempestive du fil** : les snapshots globaux ré-affichaient l'accueil pendant le chat → verrou `chatIsOpen()`.
2. **Perte de saisie** : `renderConv()` reconstruisait toute la page à chaque snapshot → rendu incrémental des seules bulles.
3. **Perte de message en concurrence** : envoi non atomique → `FieldValue.arrayUnion`.
4. **Modal cachant le chat** : depuis une annonce, « Discuter » ouvrait le chat *sous* le modal → `closeAll()` avant d'ouvrir.
5. **Présence** : heartbeat 20 s sur le profil `users/{uid}` (aucune règle supplémentaire requise).

# 🔒 Hametkro — Architecture « Achat sécurisé » & modèle Admin

Ce document décrit le dispositif anti-arnaque et la monétisation de la plateforme,
implémenté dans la démo web (`webapp/index.html`) et prêt à brancher sur Firebase
(règles Firestore déjà écrites dans `firebase/firestore.rules`).

---

## 1. Parcours sans compte (navigation libre) — décision produit
- Un **visiteur** (nouvel arrivant) **voit immédiatement** : le fil d'annonces, la
  fiche article (photos, **catégorie, état, description**, vendeur) **sans créer de
  compte**.
- Il n'a besoin d'un compte **que pour 2 actions** :
  a) **publier un article** à vendre,
  b) **contacter le vendeur / lancer une transaction**.
- Objectif : maximiser la consultation (SEO/bouche-à-oreille) sans friction.

**Règles Firestore** : `listings` et `reviews` sont en `read: true` (public).

---

## 2. Le problème des arnaques sur les marchés de seconde main
Scénarios courants sur les apps type Vendito :
1. Acheteur paie d'avance → vendeur fantôme.
2. Vendeur envoie un produit différent / jamais reçu.
3. Fausse annonce (produit n'existe pas), usurpation d'identité.

**Réponse Hametkro : la « Transaction sécurisée » à validation mutuelle.** L'argent
ne circule **jamais d'avance** ; il est remis **à la remise physique** ET la clôture
exige **deux confirmations** (acheteur + vendeur).

---

## 3. Cycle de vie d'une transaction

```
[1] ACCORD       : l'acheteur « Contacter » + les 2 conviennent d'un prix
[2] MODE         : l'acheteur choisit la remise :
      • 🤝 En main propre  → lieu public recommandé (poste, grande surface)
      • 📦 Livraison       → coursier / point relais sécurisé
[3] REMISE/RÉCEP : échange physique réel de l'article CONTRE l'argent (cash)
[4] ACHETEUR ✅  : « J'ai reçu l'article conforme »
[5] VENDEUR ✅   : « J'ai reçu le paiement »
[6] CLÔTURÉE 🎉  : les 2 ont validé → commission admin tracée
       └─ en cas de désaccord à [4] ou [5] → état « litige » → arbitrage admin
```

- **Aucune clôture possible** sans les 2 confirmations → un arnaqueur ne peut pas
  « gagner » seul.
- **Traçabilité** : chaque étape est horodatée ; les transactions ne sont **jamais
  supprimables** (règle `delete: false`).
- **Litige** : accessible par l'acheteur ou le vendeur ; l'**admin** voit la file
  de litiges et peut arbitrer/clôturer.

---

## 4. Modèle de commission Admin (revenus de la plateforme)
- **Taux configurable** : `COMM_RATE = 0.06` (6 % par défaut), modifiable dans une
  seule constante.
- **Calcul automatique** au prix final convenu, **verrouillé** dès la création de la
  transaction côté règles Firestore :
  `commission = price * 0.06` (impossible à falsifier par un client).
- Transparence **vendeur** : l'app affiche clairement la commission avant validation.
- Exemple : article **15 000 FCFA** → commission **900 FCFA**, vendeur **14 100 FCFA**.

| Prix final (FCFA) | Commission 6 % | Net vendeur |
|-------------------|----------------|-------------|
| 5 000             | 300            | 4 700       |
| 15 000            | 900            | 14 100      |
| 50 000            | 3 000          | 47 000      |
| 200 000           | 12 000         | 188 000     |

### Tableau de bord Admin 📊 (compte `role: 'admin'`)
- Nombre de ventes clôturées.
- **Total des commissions** (revenus de la plateforme).
- File des **litiges** à arbitrer.
- Historique détaillé (acheteur → vendeur, montant, commission, date).

---

## 5. Sécurisation technique (Firestore rules)
Fichier : `firebase/firestore.rules`. Points clés :
- **`transactions`** : lisible seulement par les 2 participants + admin ;
  création = l'acheteur ; `commission` recalculée côté serveur ; jamais supprimable.
- **`users.role`** : champ réservé ; seul le **compte admin** (paramétré par toi au
  boot) a accès à `reports` et au traitement.
- **`reports`** (signalements) : écrits par tous les connectés, lus/traités par admin.
- Vérification des participants : on utilise `participants` (2 ids) pour limiter
  l'accès aux seules personnes concernées.

---

## 6. Limites à connaître (honnêteté)
- **Aucun transfert d'argent automatique** pour l'instant : le paiement se fait en
  **main propre / à la remise**. La validation protège des arnaques de non-livraison
  / non-paiement, mais **pas** des faux billets (contrôler à la remise) ni des
  annonces usurpant des photos.
- Pour le **paiement 100 % en ligne** (escrow réel) il faudra brancher un agrégateur
  **Mobile Money** (CinetPay / PayDunya / Flutterwave) — l'architecture `transactions`
  est conçue pour ajouter ce champ sans tout réécrire.

---

## 7. Améliorations prévues (feuille de route sécurité)
- [ ] Vérification de téléphone (SMS) + badge « numéro vérifié ».
- [ ] Blocage / compte en attente après X signalements.
- [ ] Notification push à chaque étape de transaction.
- [ ] Double authentification pour les vendeurs à fort volume.
- [ ] Brancher l'escrow Mobile Money (encaissement automatique de la commission).

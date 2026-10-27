# IOS-004 : Réseau, données locales et sécurité

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : ios
- **Auteurs** : Mo, Claude

## Contexte

Comme Android (AND-004), l'app consomme l'API OpenAPI du backend (BE-004), gère le token de session (BE-006) et parfois le hors-ligne, sur un appareil qu'on ne contrôle pas.

## Décision

**Réseau**

- **URLSession** avec async/await.
- Client et types générés depuis la spec OpenAPI avec **swift-openapi-generator** (plugin SPM), dans `Core/Networking`.
- À la connexion, le token de session arrive dans l'en-tête de réponse `set-auth-token` ; il est aussitôt rangé dans le Keychain.
- Un middleware ajoute le token de session en `Authorization: Bearer` (BE-006). Sur une réponse `401`, il efface le token et renvoie vers la connexion ; il n'y a pas de refresh token.
- Les erreurs Problem Details sont converties en erreurs typées du domaine.
- App Transport Security actif : HTTPS uniquement, aucune exception en production.

**Données locales**

- **SwiftData** pour les données structurées et le cache hors-ligne simple. **GRDB** (SQLite) si les besoins de requêtes ou de migrations dépassent SwiftData (à acter par ADR).
- `UserDefaults` / `@AppStorage` uniquement pour des préférences non sensibles.
- Fichiers volumineux dans les dossiers appropriés (`Caches` pour ce qui peut être reconstruit, exclus de la sauvegarde iCloud).

**Sécurité**

- Tokens et données sensibles dans le **Keychain** avec une accessibilité restrictive (`…AfterFirstUnlockThisDeviceOnly` ou plus strict).
- Aucun secret embarqué dans le binaire (GLB-005).
- Pas de données personnelles ni de tokens dans les logs ; utiliser `Logger` (OSLog) avec la confidentialité par défaut (`.private`).
- Permissions système (caméra, localisation…) demandées au moment où la fonctionnalité est utilisée, avec un texte d'usage clair.

## Alternatives envisagées

- **Alamofire** : n'apporte plus grand-chose face à URLSession async/await.
- **Core Data** : mature, mais SwiftData est l'API moderne pour les nouveaux projets.

## Conséquences

- ✅ Client API aligné sur le backend, stockage sécurisé par défaut.
- ⚠️ SwiftData a encore des limites sur les migrations complexes : surveiller.

## Mise en application

- Plugin SPM de génération branché sur la spec OpenAPI publiée.
- Revue de code des accès Keychain et des `Info.plist` (ATS, textes de permissions).

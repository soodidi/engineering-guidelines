# AND-004 : Réseau, données locales et sécurité

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : android
- **Auteurs** : Mo, Claude

## Contexte

L'app consomme l'API décrite en OpenAPI (BE-004) et doit gérer le hors-ligne, les tokens d'authentification (BE-006) et les données sensibles sur un appareil qu'on ne contrôle pas.

## Décision

**Réseau**

- **Retrofit + OkHttp + kotlinx.serialization**.
- Le client API et les DTO sont **générés depuis la spec OpenAPI** du backend, dans `:core:network`.
- Un intercepteur OkHttp ajoute l'access token ; un `Authenticator` gère le renouvellement avec le refresh token (un seul renouvellement simultané).
- Les erreurs Problem Details (BE-004) sont converties en erreurs typées du domaine.
- Timeouts explicites ; logs HTTP détaillés uniquement en build debug.
- HTTPS uniquement : `usesCleartextTraffic=false`, Network Security Config.

**Données locales**

- **Room** pour les données structurées / le cache hors-ligne.
- **DataStore** (Preferences ou Proto) pour les préférences. Pas de `SharedPreferences` dans le nouveau code.
- Les migrations Room sont écrites et testées ; `fallbackToDestructiveMigration` interdit en production.

**Sécurité**

- Tokens et données sensibles **chiffrés avec une clé de l'Android Keystore** (par exemple via Tink) avant d'être stockés dans DataStore. Pas d'`EncryptedSharedPreferences` (bibliothèque dépréciée).
- Aucun secret embarqué dans l'APK/AAB (GLB-005) : il est extractible.
- `android:allowBackup` configuré pour exclure les données sensibles des sauvegardes.
- R8 (minification + obfuscation) activé en release.
- Les logs ne contiennent jamais de token ni de données personnelles ; `Log` est retiré en release.

## Alternatives envisagées

- **Ktor Client** : excellent, et indispensable si on passe à Kotlin Multiplatform (AND-001) ; Retrofit reste le standard Android à ce jour.
- **Gson / Moshi** : kotlinx.serialization est natif Kotlin et partagé avec la navigation typée.

## Conséquences

- ✅ Client API toujours aligné sur le backend, données sensibles protégées.
- ⚠️ Pipeline de génération du client à maintenir.

## Mise en application

- Tâche Gradle de génération du client depuis la spec OpenAPI publiée par le backend.
- Tests de migration Room en CI.
- Android Lint (règles de sécurité) bloquant en CI.

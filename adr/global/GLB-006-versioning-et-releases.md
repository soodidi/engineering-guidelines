# GLB-006 : Versioning et releases

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : global
- **Auteurs** : Mo, Claude

## Contexte

Il faut savoir quelle version tourne où, ce qu'elle contient, et pouvoir revenir en arrière. Le web et le backend se déploient en continu, le mobile passe par une validation des stores.

## Décision

- Versioning **SemVer** (`MAJEUR.MINEUR.CORRECTIF`) pour les apps, API et librairies.
- Les versions et le `CHANGELOG.md` DEVRAIENT être générés automatiquement à partir des Conventional Commits (GLB-002).
- Chaque release DOIT correspondre à un **tag Git** `vX.Y.Z` sur `main`.
- **Web et backend** : déploiement continu ; chaque fusion sur `main` produit un artefact versionné (image Docker taguée avec le SHA et, à la release, avec la version).
- **Mobile** :
  - `versionName` / `CFBundleShortVersionString` = version SemVer ;
  - `versionCode` / `CFBundleVersion` = nombre strictement croissant, généré par la CI ;
  - un correctif urgent se fait sur `main` puis est publié en nouvelle version corrective. Une branche `release/x.y` n'est créée que si `main` contient déjà du travail non publiable.
- L'API publique suit son propre versioning de contrat (BE-004).

## Alternatives envisagées

- **CalVer (2026.10.1)** : pertinent pour des releases à date fixe, moins parlant sur la compatibilité.
- **Versions manuelles** : source d'oublis et d'incohérences.

## Conséquences

- ✅ Traçabilité complète du code au déploiement.
- ⚠️ Dépend de la discipline des messages de commit.

## Mise en application

- `release-please` (GitHub Action) : ouvre automatiquement une PR de release avec changelog et bump de version.
- CI mobile : génération du numéro de build à partir du numéro de run.

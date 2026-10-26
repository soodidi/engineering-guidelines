# GLB-008 : Gestion des dépendances

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : global
- **Auteurs** : Mo, Claude

## Contexte

Chaque dépendance est du code qu'on ne maîtrise pas : surface d'attaque (attaques supply chain), poids, maintenance. Des dépendances jamais mises à jour finissent en migrations douloureuses.

## Décision

**Ajouter une dépendance**

- Avant d'ajouter une dépendance, vérifier : maintenance active, adoption, licence compatible (MIT, Apache-2.0, BSD… ; pas de GPL dans le code distribué sans validation), poids, alternatives natives.
- Une dépendance pour quelques lignes de code évitables NE DEVRAIT PAS être ajoutée.
- Une dépendance structurante (framework, ORM, state management…) DOIT faire l'objet d'un ADR.

**Versions**

- Les lockfiles (`package-lock.json`, `gradle.lockfile`/version catalog, `Package.resolved`) DOIVENT être commités. En CI, l'installation se fait avec `npm ci` (échoue si le lockfile n'est pas à jour).
- Les versions des outils (Node, JDK, Xcode…) DOIVENT être épinglées (`.nvmrc` / `packageManager`, `.java-version`, `.xcode-version`).
- **Node** : version LTS active, gestionnaire de paquets **npm** (fourni avec Node, aucun outil supplémentaire à installer). Les monorepos utilisent les **npm workspaces**.

**Mises à jour**

- Mises à jour automatisées via **Renovate**, regroupées par écosystème, à fréquence hebdomadaire.
- Correctifs et mineurs : fusion automatique si la CI est verte (hors frameworks principaux).
- Majeures : PR dédiée, relue manuellement, notes de version lues.
- Vulnérabilités critiques : traitées dans la semaine.

## Alternatives envisagées

- **Dependabot** : intégré à GitHub, mais regroupement et configuration moins souples que Renovate.
- **pnpm** : plus rapide et plus strict sur les dépendances fantômes, mais un outil de plus à installer et à maintenir sur chaque poste et chaque CI. npm suffit à nos besoins.
- **yarn** : pas d'avantage décisif sur npm pour nos projets.

## Conséquences

- ✅ Dépendances à jour en continu, par petits pas.
- ⚠️ Flux régulier de PR automatiques à traiter.

## Mise en application

- `renovate.json` dans chaque repo (preset partagé à terme).
- `npm audit` / Dependabot alerts / `osv-scanner` en CI.
- Vérification de licences en CI (`license-checker` ou équivalent).

# GLB-010 : Boilerplates et libs partagées

- **Statut** : Proposé
- **Date** : 2026-10-26
- **Périmètre** : global
- **Auteurs** : Mo, Claude
- **Liens** : GLB-001, GLB-008

## Contexte

Les ADR décrivent des règles, mais une règle qu'il faut reconfigurer à la main dans chaque nouveau projet finit appliquée à moitié. Démarrer un projet en recopiant un ancien repo embarque aussi ses dettes. Il faut des points de départ qui appliquent déjà les ADR, et un endroit unique pour le code et la configuration communs à plusieurs projets.

## Décision

### Boilerplates

- Tout nouveau projet DOIT démarrer depuis le repo **`boilerplates`**, qui contient un boilerplate par type d'application :

| Boilerplate | Domaine | ADR appliqués |
|-------------|---------|---------------|
| `web-react-vite` | frontend | FE-001 à FE-009 |
| `api-nestjs` | backend | BE-001 à BE-008 |
| `infra-scaleway` | devops | OPS-003 à OPS-007 |
| `android-compose` | android | AND-001 à AND-005 |
| `ios-swiftui` | ios | IOS-001 à IOS-005 |

- Un boilerplate se copie (`npx degit soodidi/boilerplates/<nom> <projet>`) : le nouveau projet ne reste **pas** lié au boilerplate. Il démarre son propre historique Git.
- Chaque boilerplate DOIT fonctionner seul : installation, lint, tests et build passent sans autre étape que celles de son README.
- Les comptes, secrets et réglages qu'aucun boilerplate ne peut porter (Sentry, Scaleway, domaine, stores, pages légales) sont listés dans la [checklist « nouveau projet »](../../docs/checklist-nouveau-projet.md). `/new-project` l'affiche à la fin et ouvre dans chaque repo une issue « Mise en route » avec ce qui reste à faire.
- Chaque boilerplate contient : configuration des outils de qualité, hooks Git, CI GitHub Actions, templates de PR et d'issue (GLB-003, GLB-009), `.env.example`, un exemple de feature minimal qui montre l'architecture, et un README de démarrage.
- Quand un ADR change une règle outillée, le boilerplate concerné DOIT être mis à jour dans la foulée.
- Un projet Next.js (exception FE-001) part de `create-next-app` puis reprend la configuration de `web-react-vite`. Pas de boilerplate dédié tant qu'il n'y a pas eu au moins deux projets Next.js.

### Faire remonter les améliorations des apps

- Chaque app créée par `/new-project` contient un `.boilerplate.json` : boilerplate d'origine, commit du repo `boilerplates` au moment de la copie, renommages appliqués.
- Quand une app améliore son **socle générique** (outillage, CI, kit IA, client HTTP, gestion d'erreurs, design system, setup de tests), l'amélioration DEVRAIT remonter dans le boilerplate pour profiter aux apps suivantes. La commande `/upstream`, lancée depuis l'app, compare l'app à son origine, trie les divergences (à remonter, propre à l'app, dérive) et ouvre une PR par sujet sur `boilerplates`.
- `/upstream` DEVRAIT être lancé au moins une fois par mois sur chaque app active, et après toute fonctionnalité qui a touché l'outillage ou le socle.
- Une **dérive** (règle désactivée, test supprimé, ADR contourné sans commentaire `Dérogation`) n'est jamais remontée : elle est corrigée dans l'app.

### Libs partagées

- Le repo **`shared-libs`** est un monorepo (npm workspaces) qui contient ce qui est commun à plusieurs projets :
  - les **configurations** : `@soodidi/tsconfig`, `@soodidi/eslint-config`, `@soodidi/prettier-config`, `@soodidi/commitlint-config` ;
  - les **libs de code** utilisées par plusieurs apps, par exemple `@soodidi/problem-details` (format d'erreur API de BE-004, partagé entre le back et le front) ;
  - le **preset Renovate** (GLB-008) ;
  - les **workflows GitHub Actions réutilisables** (OPS-002).
- Les packages sont publiés sur **GitHub Packages** sous le scope `@soodidi`, versionnés en SemVer avec **Changesets** (plus adapté que release-please à un monorepo de packages publiés indépendamment ; c'est la seule exception à GLB-006).
- Une lib n'entre dans `shared-libs` que si elle sert **au moins deux projets** et ne contient pas de logique métier propre à une app.
- Le code mobile (Kotlin, Swift) n'y figure pas : rien ne se partage entre ces langages sans Kotlin Multiplatform (AND-001).

### Lien entre les deux

- Tant que les packages `@soodidi/*` ne sont pas publiés, les boilerplates embarquent une **copie** des configurations. Une fois la première version publiée, ils DEVRAIENT les consommer comme dépendances.
- Les workflows et le preset Renovate se consomment directement depuis GitHub, sans publication.

## Alternatives envisagées

- **Générateur de projet (Yeoman, Plop, CLI maison)** : plus flexible, mais un outil de plus à maintenir. Un dossier qu'on copie suffit pour l'instant.
- **Template repositories GitHub (un repo par boilerplate)** : bonne option, mais multiplie les repos à maintenir. Le passage reste simple si le besoin apparaît.
- **Monorepo unique pour tous les projets (Nx, Turborepo)** : pertinent quand les apps partagent beaucoup de code et une même équipe. Prématuré ici.

## Conséquences

- ✅ Un nouveau projet applique les ADR dès le premier commit.
- ✅ Une seule source pour les configurations et le code commun.
- ⚠️ Les boilerplates doivent être maintenus (Renovate aide) et testés régulièrement.
- ⚠️ Les projets déjà créés ne reçoivent pas automatiquement les évolutions du boilerplate : à reporter à la main ou via les libs partagées.

## Mise en application

- CI de chaque boilerplate : installation, lint, tests et build sur chaque PR du repo `boilerplates` qui le touche (jobs filtrés par chemins, OPS-002), et sur chaque push sur `main`.
- Renovate actif sur `boilerplates` et `shared-libs`.
- Revue : tout nouveau repo d'app qui ne part pas d'un boilerplate doit le justifier.

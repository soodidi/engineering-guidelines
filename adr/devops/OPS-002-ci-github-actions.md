# OPS-002 : CI/CD avec GitHub Actions

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : devops
- **Auteurs** : Mo, Claude

## Contexte

La CI est le garde-fou qui applique automatiquement la plupart des ADR. Elle doit être rapide (sinon on la contourne), fiable et sécurisée : un workflow compromis donne accès à la production.

## Décision

**Pipeline standard (sur chaque PR)**
1. Installation avec cache (pnpm, Gradle, SPM).
2. Lint + format + typecheck.
3. Tests unitaires et d'intégration.
4. Build (image Docker ou bundle).
5. Scans sécurité : secrets (`gitleaks`), dépendances, image (`trivy`).

**Sur `main`** : même pipeline + publication de l'artefact + déploiement automatique en **staging** (OPS-004).
**Production** : déploiement déclenché par une release (tag), avec approbation manuelle via un **GitHub Environment** protégé.

**Objectif** : retour de CI sur une PR en **moins de 10 minutes**.

**Sécurité des workflows**
- Les actions tierces DOIVENT être **épinglées par SHA** de commit (pas par tag `@v4`), mises à jour par Renovate.
- `permissions:` déclarées explicitement au niveau du workflow, au minimum nécessaire (`contents: read` par défaut).
- Authentification au cloud par **OIDC** quand le fournisseur le supporte ; sinon clés d'API **dédiées à la CI**, à portée minimale, stockées dans les secrets d'**Environment** (pas au niveau du repo), renouvelées régulièrement.
- Jamais de `pull_request_target` avec checkout du code de la PR.
- Les secrets ne sont jamais affichés dans les logs.

**Organisation**
- Workflows réutilisables (`workflow_call`) dans un repo partagé pour éviter de copier-coller les pipelines entre projets.
- `concurrency` pour annuler les runs obsolètes d'une même branche.
- Monorepo : jobs filtrés par chemins modifiés.

## Alternatives envisagées

- **GitLab CI** : très bon, mais le code est sur GitHub.
- **CI du fournisseur cloud** : verrouillage et intégration GitHub moins bonne.

## Conséquences

- ✅ Les règles sont appliquées automatiquement, sans dépendre de la vigilance humaine.
- ⚠️ Les minutes de CI (notamment macOS pour iOS, IOS-005) ont un coût à surveiller.

## Mise en application

- `actionlint` et `zizmor` (audit de sécurité des workflows) en CI.
- Protection de branche : checks obligatoires.

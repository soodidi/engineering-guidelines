# Guide global

Règles transverses, applicables à tous les domaines.

## Règles en bref

**Process**

- Toute décision structurante passe par un ADR, rangé par domaine. → [GLB-001](GLB-001-documenter-les-decisions-en-adr.md)
- `main` toujours déployable, branches courtes `type/sujet`, Conventional Commits en anglais, squash merge. → [GLB-002](GLB-002-git-trunk-based-et-conventional-commits.md)
- PR < 400 lignes, un seul sujet, 1 approbation (2 pour migrations, auth, infra prod), CI verte. Préfixes `bloquant:` / `suggestion:` / `question:` / `nit:`. → [GLB-003](GLB-003-revue-de-code.md)

**Qualité**

- On teste le comportement ; tout bug corrigé a son test ; E2E réservés aux parcours critiques. → [GLB-004](GLB-004-strategie-de-tests.md)
- Definition of Done commune (revue, tests, a11y, Sentry, docs, validation en staging par une autre personne) ; bugs classés S1 à S4 ; critères de mise en production web et mobile. → [GLB-009](GLB-009-qa-et-definition-of-done.md)
- Code, commits et commentaires en anglais ; docs et ADR en français ; un concept métier = un seul nom (glossaire). → [GLB-007](GLB-007-langue-et-nommage.md)

**Sécurité et livraison**

- Aucun secret dans Git ; config par variables d'environnement validées au démarrage ; `.env.example` obligatoire ; rien de secret dans un bundle front ou mobile. → [GLB-005](GLB-005-secrets-et-configuration.md)
- SemVer + tags `vX.Y.Z`, changelog généré par release-please. → [GLB-006](GLB-006-versioning-et-releases.md)
- Lockfiles commités, versions d'outils épinglées, npm (`npm ci` en CI), Renovate hebdo ; dépendance structurante = ADR. → [GLB-008](GLB-008-gestion-des-dependances.md)
- Tout nouveau projet part du repo `boilerplates` ; le code et les configs communs vivent dans `shared-libs` (packages `@soodidi/*`). → [GLB-010](GLB-010-boilerplates-et-libs-partagees.md)

**Travail avec l'IA**

- Cycle `/feature` : issue avec critères d'acceptation → plan validé par un humain → code + `verify` → contrôles par agents spécialisés (`reviewer`, `qa`, `security`, `devops`) → PR. Bugs : `/fix` (test qui reproduit d'abord). L'IA ne fusionne jamais ; actions irréversibles interdites par la config `.claude/`. → [GLB-011](GLB-011-developpement-avec-l-ia.md)

## Index

| ADR | Titre | Statut |
|-----|-------|--------|
| [GLB-001](GLB-001-documenter-les-decisions-en-adr.md) | Documenter les décisions structurantes en ADR | Proposé |
| [GLB-002](GLB-002-git-trunk-based-et-conventional-commits.md) | Git : trunk-based et Conventional Commits | Proposé |
| [GLB-003](GLB-003-revue-de-code.md) | Revue de code et pull requests | Proposé |
| [GLB-004](GLB-004-strategie-de-tests.md) | Stratégie de tests | Proposé |
| [GLB-005](GLB-005-secrets-et-configuration.md) | Secrets et configuration | Proposé |
| [GLB-006](GLB-006-versioning-et-releases.md) | Versioning et releases | Proposé |
| [GLB-007](GLB-007-langue-et-nommage.md) | Langue et nommage | Proposé |
| [GLB-008](GLB-008-gestion-des-dependances.md) | Gestion des dépendances | Proposé |
| [GLB-009](GLB-009-qa-et-definition-of-done.md) | QA, Definition of Done et gestion des bugs | Proposé |
| [GLB-010](GLB-010-boilerplates-et-libs-partagees.md) | Boilerplates et libs partagées | Proposé |
| [GLB-011](GLB-011-developpement-avec-l-ia.md) | Développement avec l'IA et agents spécialisés | Proposé |

# Guide DevOps

Stack : **Docker + GitHub Actions + OpenTofu/Terraform + Scaleway** (OVHcloud en alternative).
S'applique en plus du [guide global](../global/README.md).

## Règles en bref

**Build**

- Dockerfile multi-stage, image de base minimale épinglée, utilisateur non-root, tag = SHA du commit, jamais `latest` ; Compose pour les dépendances locales. → [OPS-001](OPS-001-conteneurisation-docker.md)
- CI GitHub Actions : lint, typecheck, tests, build, scans (gitleaks, trivy) sur chaque PR, < 10 min ; actions épinglées par SHA ; permissions minimales ; secrets par Environment. → [OPS-002](OPS-002-ci-github-actions.md)

**Infrastructure**

- Tout en OpenTofu (`infra/modules` + `infra/envs`), state distant verrouillé et chiffré par OpenTofu, `plan` en PR, `apply` par la CI ; pas de click-ops. → [OPS-003](OPS-003-infrastructure-as-code.md)
- Scaleway `fr-par` : Serverless Containers + PostgreSQL managé en réseau privé + Object Storage/CDN pour le front ; Kubernetes (Kapsule) seulement sur ADR. → [OPS-005](OPS-005-hebergement-scaleway.md)

**Livraison**

- local → (preview) → staging automatique → production sur release + approbation ; même artefact partout ; migrations au démarrage de l'API, sous verrou, avant `/health/ready` ; rollback = image précédente ; pas de données de prod hors prod sans anonymisation. → [OPS-004](OPS-004-environnements-et-deploiement.md)
- Secrets saisis à la main dans Secret Manager ; secrets générés par OpenTofu en variables secrètes du conteneur, state chiffré ; clés IAM créées par `envs/iam` appliqué à la main, jamais par la CI ; clés dédiées par app/pipeline ; rotation annuelle. → [OPS-006](OPS-006-gestion-des-secrets-en-production.md)

**Exploitation**

- Cockpit (logs, métriques, traces) ; uptime externe ; alertes sur symptômes avec runbook ; sauvegardes quotidiennes + copie hors région ; restauration testée chaque trimestre ; post-mortems sans blâme. → [OPS-007](OPS-007-supervision-et-sauvegardes.md)

## Index

| ADR | Titre | Statut |
|-----|-------|--------|
| [OPS-001](OPS-001-conteneurisation-docker.md) | Conteneurisation avec Docker | Proposé |
| [OPS-002](OPS-002-ci-github-actions.md) | CI/CD avec GitHub Actions | Proposé |
| [OPS-003](OPS-003-infrastructure-as-code.md) | Infrastructure as Code (OpenTofu) | Proposé |
| [OPS-004](OPS-004-environnements-et-deploiement.md) | Environnements et déploiement | Proposé |
| [OPS-005](OPS-005-hebergement-scaleway.md) | Hébergement Scaleway | Proposé |
| [OPS-006](OPS-006-gestion-des-secrets-en-production.md) | Secrets en production | Proposé |
| [OPS-007](OPS-007-supervision-et-sauvegardes.md) | Supervision et sauvegardes | Proposé |

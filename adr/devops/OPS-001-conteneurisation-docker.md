# OPS-001 : Conteneurisation avec Docker

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : devops
- **Auteurs** : Mo, Claude

## Contexte

« Ça marche sur ma machine » n'est pas une stratégie de déploiement. Les images Docker garantissent que ce qui est testé en CI est exactement ce qui tourne en production, chez n'importe quel hébergeur (OPS-005).

## Décision

**Images**
- Tout service backend est livré sous forme d'**image OCI** construite par un `Dockerfile` à la racine du projet.
- **Multi-stage** : étape de build (dépendances de dev, compilation) séparée de l'image finale (dépendances de production uniquement).
- Image de base **minimale et épinglée** : `node:<version>-slim` ou distroless, avec un tag de version précis (et idéalement le digest), jamais `latest`.
- Le conteneur tourne avec un **utilisateur non-root**.
- `.dockerignore` exclut `node_modules`, `.git`, `.env*`, tests et docs.
- Ordre des instructions optimisé pour le cache : copier les manifestes et lockfiles, installer, puis copier le code.
- Une image = un processus. Les migrations sont lancées par la même image avec une autre commande (OPS-004).
- `HEALTHCHECK` ou sondes de la plateforme branchées sur `/health/live` et `/health/ready` (BE-007).

**Tags**
- Chaque image est taguée avec le **SHA du commit** ; les releases ajoutent `vX.Y.Z` (GLB-006). Le tag `latest` n'est jamais utilisé pour déployer.
- La même image est promue d'un environnement à l'autre, jamais reconstruite.

**Développement local**
- `compose.yaml` pour lancer les dépendances (PostgreSQL, Redis, Mailpit…) avec les mêmes versions majeures que la production.
- Le front (Vite) tourne en natif en local ; il est servi en statique en production (OPS-005).

## Alternatives envisagées

- **Buildpacks** : moins de contrôle sur le contenu de l'image.
- **Déploiement sans conteneur (PaaS Node natif)** : plus simple au début, mais verrouille sur une plateforme.

## Conséquences

- ✅ Environnements reproductibles, portabilité entre Scaleway, OVH ou autre.
- ⚠️ Les Dockerfiles doivent être maintenus (mises à jour d'image de base via Renovate, GLB-008).

## Mise en application

- `hadolint` en CI.
- Scan de vulnérabilités de l'image (`trivy`) en CI ; vulnérabilité critique corrigeable = build bloqué.

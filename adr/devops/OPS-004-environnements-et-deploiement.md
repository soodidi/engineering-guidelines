# OPS-004 : Environnements et stratégie de déploiement

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : devops
- **Auteurs** : Mo, Claude

## Contexte

On veut déployer souvent et sans stress. Cela suppose que ce qui arrive en production a déjà tourné ailleurs dans des conditions proches, et qu'on peut revenir en arrière en quelques minutes.

## Décision

**Environnements**

| Environnement | Rôle | Déploiement | Données |
|---------------|------|-------------|---------|
| `local` | Développement | Docker Compose | Seeds fictives |
| `preview` (optionnel) | Une PR front | Automatique par PR | Mock ou staging |
| `staging` | Recette, intégration | Automatique à chaque fusion sur `main` | Fictives ou anonymisées |
| `production` | Utilisateurs | Release taguée + approbation | Réelles |

- Staging DOIT être aussi proche que possible de la production (mêmes modules OpenTofu, mêmes versions), en plus petit.
- Les données de production NE DOIVENT JAMAIS être copiées telles quelles hors production (RGPD). Une copie pour staging DOIT être anonymisée.

**Déploiement**

- **Build once, deploy many** : l'artefact (image, bundle) testé en staging est exactement celui promu en production.
- Ordre : (1) job de **migration** de base (BE-003, compatible avec la version en cours) → (2) déploiement progressif des nouvelles instances → (3) bascule quand `/health/ready` répond.
- **Rollback** : redéployer l'image précédente, en une commande ou un clic. Grâce aux migrations *expand/contract*, le schéma reste compatible avec la version N-1.
- Fonctionnalités risquées : **feature flags** (GLB-002), activées progressivement.
- Pas de déploiement de production le vendredi après-midi ni la veille d'un jour férié, sauf correctif urgent.

**Front statique**

- Fichiers avec hash dans le nom : cache long (`immutable`). `index.html` : pas de cache (ou très court).
- La configuration propre à l'environnement (URL d'API…) est injectée au déploiement, pas codée en dur au build.

## Alternatives envisagées

- **Reconstruire l'image par environnement** : ce qui part en production n'est plus ce qui a été testé.
- **Migrations au démarrage de l'app** : course entre instances, démarrages lents et risqués.

## Conséquences

- ✅ Déploiements fréquents, rollback rapide.
- ⚠️ Un environnement de staging a un coût (réduit en le dimensionnant au minimum).

## Mise en application

- Workflows GitHub Actions avec Environments `staging` et `production` (OPS-002).
- Runbook de rollback dans le repo de chaque projet.

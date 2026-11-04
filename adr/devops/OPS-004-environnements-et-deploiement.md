# OPS-004 : Environnements et stratégie de déploiement

- **Statut** : Proposé
- **Date** : 2026-10-28
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
| `production` | Utilisateurs | Lancement manuel depuis `main` par le propriétaire du repo, avec l'artefact déjà déployé en staging | Réelles |

- Staging DOIT être aussi proche que possible de la production (mêmes modules OpenTofu, mêmes versions), en plus petit.
- Les données de production NE DOIVENT JAMAIS être copiées telles quelles hors production (RGPD). Une copie pour staging DOIT être anonymisée.

**Déploiement**

- **Build once, deploy many** : l'artefact (image, bundle) testé en staging est exactement celui promu en production.
- **Mise en production** (2026-11-04, choix de l'utilisateur) : à la main, depuis `main`, par le propriétaire du repo (`gh workflow run deploy`, ou `infra` pour l'infra), pour le dernier commit de `main` déjà déployé en staging avec succès ; rien n'est reconstruit. Un lancement par quelqu'un d'autre, ou depuis une autre branche, échoue. Raison : pour un repo privé, GitHub ne propose pas de validation obligatoire (reviewers) hors Enterprise ; une production qui suivrait automatiquement le staging enverrait chaque fusion aux utilisateurs. Une release taguée (release-please) reste possible plus tard, quand une app aura un rythme de versions (tags protégés par un ruleset).
- Ordre : (1) déploiement progressif des nouvelles instances, qui appliquent les **migrations au démarrage**, sous verrou (BE-003, compatibles avec la version en cours) → (2) bascule quand `/health/ready` répond. Une migration qui échoue bloque la mise en service : l'ancienne version continue de tourner.
- **Rollback** : redéployer l'image précédente, en une commande ou un clic. Avec la mise en production manuelle : le propriétaire relance (« Re-run all jobs ») le run de production de la version voulue ; l'API retrouve son image, le web son build tant qu'il existe (30 jours). Une relance par quelqu'un d'autre ne déploie rien. Grâce aux migrations *expand/contract*, le schéma reste compatible avec la version N-1.
- Fonctionnalités risquées : **feature flags** (GLB-002), activées progressivement.
- Pas de déploiement de production le vendredi après-midi ni la veille d'un jour férié, sauf correctif urgent.

**Front statique**

- Fichiers avec hash dans le nom : cache long (`immutable`). `index.html` : pas de cache (ou très court).
- La configuration propre à l'environnement (URL d'API…) est injectée au déploiement, pas codée en dur au build.

## Alternatives envisagées

- **Reconstruire l'image par environnement** : ce qui part en production n'est plus ce qui a été testé.
- **Job de migration lancé par la CI avant le déploiement** : la base n'a pas d'accès public et Serverless Jobs ne joint pas le réseau privé (BE-003). La course entre instances au démarrage est évitée par un verrou PostgreSQL. Le démarrage plus lent est accepté : il ne dure que le temps des migrations en attente.

## Conséquences

- ✅ Déploiements fréquents, rollback rapide.
- ⚠️ Un environnement de staging a un coût (réduit en le dimensionnant au minimum).

## Mise en application

- Workflows GitHub Actions avec Environments `staging` et `production` (OPS-002).
- Runbook de rollback dans le repo de chaque projet.

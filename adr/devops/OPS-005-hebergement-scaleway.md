# OPS-005 : Hébergement sur Scaleway (OVH en alternative)

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : devops
- **Auteurs** : Mo, Claude

## Contexte

On veut un hébergement **européen** (données en France/UE, RGPD, souveraineté), des services **managés** pour ne pas administrer de serveurs, et une architecture qui puisse grandir sans tout réécrire. Le choix s'est porté sur Scaleway ou OVHcloud.

## Décision

**Fournisseur par défaut : Scaleway**, région `fr-par`. OVHcloud reste l'alternative (même logique : conteneurs, PostgreSQL managé, stockage objet), et l'usage de Docker (OPS-001) + OpenTofu (OPS-003) garde la migration possible.

**Architecture par défaut (« niveau 1 »)**

| Besoin | Service Scaleway |
|--------|------------------|
| Images Docker | Container Registry |
| Backend | **Serverless Containers** (scale automatique, y compris à zéro hors prod) |
| Base de données | **Managed Database for PostgreSQL** (sauvegardes auto, haute dispo en prod) |
| Front statique (SPA) | Object Storage + Edge Services (CDN, HTTPS) |
| Fichiers utilisateurs | Object Storage (bucket privé, URLs signées) |
| Secrets | Secret Manager (OPS-006) |
| Logs / métriques | Cockpit (OPS-007) |
| Cache / files (si besoin) | Managed Redis |
| E-mails transactionnels | Transactional Email |

**Quand passer au « niveau 2 » (Kubernetes Kapsule)**
Seulement si au moins un besoin n'est plus couvert : plusieurs services avec communication interne complexe, workers longs ou nombreux, besoins réseau/stockage spécifiques, ou coût des conteneurs serverless devenu supérieur à un cluster. Ce passage DOIT faire l'objet d'un ADR.

**Règles**
- Base de données dans un réseau privé (Private Network), jamais exposée publiquement.
- Production : base en haute disponibilité, sauvegardes quotidiennes avec rétention ≥ 7 jours.
- Budgets et alertes de facturation configurés par projet.
- Next.js (cas d'exception FE-001) : déployé en conteneur comme un service backend.

## Alternatives envisagées

- **AWS / GCP / Azure** : catalogue plus large et très demandé sur le marché, mais hors critère de souveraineté retenu ; les compétences Docker/OpenTofu/Kubernetes acquises ici restent transférables.
- **Vercel / Railway / Fly** : très simples, mais moins de contrôle, hébergement des données moins maîtrisé, coût élevé à l'échelle.
- **Kubernetes dès le départ** : complexité d'exploitation injustifiée au démarrage.

## Conséquences

- ✅ Données hébergées en France, services managés, coûts maîtrisés (scale à zéro hors prod).
- ✅ Chemin d'évolution clair vers Kubernetes.
- ⚠️ Catalogue plus restreint que les hyperscalers : vérifier la disponibilité d'un service avant de le prévoir.

## Mise en application

- Modules OpenTofu `app-service`, `database`, `static-site` dans `infra/modules` (OPS-003).
- Revue d'architecture au démarrage de chaque projet.

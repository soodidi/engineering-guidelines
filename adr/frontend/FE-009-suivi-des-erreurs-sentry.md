# FE-009 : Suivi des erreurs en production (Sentry)

- **Statut** : Proposé
- **Date** : 2026-10-26
- **Périmètre** : frontend
- **Auteurs** : Mo, Claude
- **Liens** : BE-007, OPS-007, GLB-009

## Contexte

Une erreur JavaScript chez un utilisateur est invisible pour l'équipe : elle n'apparaît que si quelqu'un prend la peine de la signaler, et sans contexte. Il faut capter automatiquement les erreurs du navigateur, les relier à une version et, si possible, à la requête backend concernée, sans collecter de données personnelles inutiles (RGPD).

## Décision

**Outil**

- **Sentry** (`@sentry/react`), hébergé dans la **région de données UE**. GlitchTip auto-hébergé (compatible avec le SDK Sentry) reste une alternative si l'on veut tout garder chez soi.
- Le même projet Sentry regroupe les environnements (`development`, `staging`, `production`), distingués par l'option `environment`.

**Initialisation**

- Sentry est initialisé dans `src/lib/sentry.ts`, appelé avant le premier rendu.
- Sans DSN configuré (`VITE_SENTRY_DSN` vide, cas du développement local), Sentry n'est pas initialisé.
- `release` = SHA du commit, injecté au build par la CI.
- Le DSN est public par nature : il peut être dans le bundle (GLB-005 ne s'applique pas à lui).

**Données collectées**

- Depuis la v11 du SDK, la collecte par défaut est large (cookies, en-têtes, corps de requêtes). On DOIT configurer `dataCollection` de façon restrictive : pas de cookies, pas de corps HTTP, pas d'informations utilisateur automatiques.
- On identifie l'utilisateur uniquement par un **identifiant interne** (`Sentry.setUser({ id })`), jamais par son e-mail ou son nom.
- **Session Replay désactivé par défaut**. S'il est activé pour un besoin précis, tout le texte et les champs DOIVENT être masqués (`maskAllText`, `blockAllMedia`) et l'activation passe par un ADR projet.

**Erreurs**

- Une `Sentry.ErrorBoundary` enveloppe l'app à la racine, avec un écran d'erreur générique et un bouton pour recharger.
- Chaque route PEUT définir son propre composant d'erreur (TanStack Router `errorComponent`) pour garder le reste de l'app utilisable.
- Les erreurs attendues (validation, 404 métier, 401) NE sont PAS envoyées à Sentry : elles sont gérées dans l'UI.

**Performance**

- Tracing navigateur activé avec un échantillonnage faible en production (`tracesSampleRate: 0.1`), plus élevé en staging.
- `tracePropagationTargets` limité à l'URL de notre API, pour relier une erreur front à la trace backend (BE-007) sans envoyer d'en-têtes de trace à des domaines tiers.

**Source maps**

- Les source maps sont générées au build, **envoyées à Sentry par la CI**, puis **supprimées** du dossier publié : elles ne sont pas servies au public.

## Alternatives envisagées

- **Pas d'outil, on lit les retours utilisateurs** : on découvre les erreurs trop tard et sans contexte.
- **LogRocket, Datadog RUM** : très complets, mais plus chers et données hors UE par défaut.
- **Collecte maison vers le backend** : à réinventer (dédoublonnage, source maps, alertes).

## Conséquences

- ✅ Les erreurs de production sont visibles, groupées, liées à une version et au backend.
- ✅ Configuration compatible RGPD.
- ⚠️ Le plan gratuit a des quotas : l'échantillonnage et le filtrage des erreurs attendues sont indispensables.

## Mise en application

- `src/lib/sentry.ts` et l'`ErrorBoundary` sont fournis par le boilerplate `web-react-vite` (GLB-010).
- Job CI de build : upload des source maps (`@sentry/vite-plugin` ou `sentry-cli`) puis suppression des `.map`.
- Alertes Sentry sur les nouveaux types d'erreur et les pics, branchées sur le canal de l'équipe (OPS-007).

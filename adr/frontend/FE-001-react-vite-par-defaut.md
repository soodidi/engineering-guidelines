# FE-001 : React + Vite par défaut, Next.js seulement si nécessaire

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : frontend
- **Auteurs** : Mo, Claude

## Contexte

La plupart de nos apps sont des interfaces authentifiées (back-offices, outils, dashboards) qui consomment une API séparée (BE-001). Elles n'ont pas besoin de rendu serveur. Next.js apporte SSR, RSC et routing côté serveur, mais aussi un serveur Node à opérer, un modèle mental plus complexe (client/server components, cache) et un couplage à son écosystème de déploiement.

## Décision

**Par défaut : SPA React + TypeScript + Vite**, servie en statique (OPS-005).

**Next.js est autorisé uniquement si au moins un critère est rempli** :
- SEO indispensable sur des pages à contenu dynamique (catalogue, annonces, blog) ;
- performance du premier affichage critique pour des visiteurs non connectés (landing, e-commerce) ;
- besoin de rendu serveur pour des aperçus de partage (Open Graph dynamique).

Le choix de Next.js pour un projet DOIT être justifié dans un ADR du projet citant le critère.

Un site purement éditorial (vitrine, docs) PEUT utiliser un générateur statique (Astro) plutôt que Next.js.

**Routing (SPA)** : **TanStack Router**, avec routes, params et search params typés ; les search params sont validés par un schéma Zod. Routes chargées en lazy par feature.

**Pas de backend dans le front** : même avec Next.js, la logique métier reste dans le backend (BE-001). Les route handlers Next servent au rendu et au BFF léger, pas aux règles métier.

## Alternatives envisagées

- **Next.js partout** : surdimensionné pour une app authentifiée, coûts d'exploitation et de complexité injustifiés.
- **React Router** : le standard le plus connu, mais typage faible des routes et des search params. Or l'état d'URL (filtres, pagination) est central dans nos apps (FE-004).
- **Remix / React Router framework mode** : mêmes compromis que Next.js.

## Conséquences

- ✅ Build et dev server rapides, déploiement statique simple et peu cher.
- ✅ Séparation nette front / back, le même backend sert web et mobile.
- ⚠️ Pas de SEO sur les SPA : acceptable pour des apps derrière login.

## Mise en application

- Template de projet `create-vite` (react-ts) adapté avec la config de ces ADR.
- Revue d'architecture au démarrage du projet.

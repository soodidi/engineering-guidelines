# BE-001 : Node.js + TypeScript + NestJS + PostgreSQL

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : backend
- **Auteurs** : Mo, Claude

## Contexte

Il faut un backend **robuste, fiable, capable de servir plusieurs types d'apps** (web, Android, iOS, intégrations tierces), et une stack **valorisée sur le marché** pour les années à venir. L'équipe est forte en TypeScript côté front ; la montée en compétence backend doit rester réaliste.

## Décision

| Brique | Choix |
|--------|-------|
| Runtime | **Node.js LTS active** (version épinglée dans `.nvmrc`) |
| Langage | **TypeScript strict** (mêmes règles que FE-002 pour le typage) |
| Framework | **NestJS** avec l'adaptateur **Fastify** |
| Base de données | **PostgreSQL** (version majeure supportée la plus récente du cloud, OPS-005) |
| Accès aux données | **Drizzle ORM** + migrations SQL versionnées (BE-003) |
| Validation | **Zod** (BE-005) |
| Cache / files d'attente | Redis (Valkey) + BullMQ, seulement quand le besoin apparaît |
| Contrat d'API | REST + OpenAPI (BE-004) |

**Pourquoi cette combinaison**
- **Un seul langage** du front au back : types et schémas partagés, montée en compétence plus rapide, pas de changement de contexte.
- **NestJS** impose une structure (modules, injection de dépendances, guards, pipes, interceptors) qui tient quand le code et l'équipe grandissent. C'est aussi le framework Node le plus demandé en entreprise, en France notamment.
- **Fastify** en dessous : nettement plus performant qu'Express, validation et sérialisation natives.
- **PostgreSQL** : la base relationnelle de référence, fiable, transactionnelle, avec JSONB et extensions (PostGIS, recherche plein texte, pgvector pour l'IA).

## Alternatives envisagées

- **Express seul** : minimaliste, mais aucune structure imposée ; chaque projet réinvente l'architecture. Express reste ce qu'il y a sous NestJS par défaut, la connaissance n'est pas perdue.
- **Fastify ou Hono seul** : excellent pour des microservices simples, mais demande de construire soi-même l'architecture applicative.
- **Go** : très bon pour les services réseau et l'outillage d'infra, mais un deuxième langage dès le départ. **Candidat naturel pour des services spécifiques plus tard.**
- **Kotlin + Spring Boot** : très robuste et recherché (banque, assurance), mais lourd et sans synergie avec le front.
- **Rust (Axum)** : performances et fiabilité excellentes, courbe d'apprentissage élevée. Pertinent ensuite pour des composants critiques en performance.
- **MongoDB** : rejeté comme base par défaut ; nos données sont relationnelles.

## Conséquences

- ✅ Stack cohérente de bout en bout, très employable.
- ✅ Architecture prête pour plusieurs clients (web, mobile, partenaires).
- ⚠️ NestJS a une part de « magie » (décorateurs, DI) à apprendre.
- ⚠️ Node est mono-thread : les traitements CPU lourds partent dans des workers ou un service dédié.

## Mise en application

- Template de projet NestJS + Fastify + Drizzle pré-configuré selon ces ADR.
- Tout autre langage ou framework backend nécessite un ADR.

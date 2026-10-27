# Guide backend

Stack : **Node.js LTS + TypeScript + NestJS (Fastify) + PostgreSQL + Drizzle + Zod**.
S'applique en plus du [guide global](../global/README.md).

## Règles en bref

**Socle et architecture**

- NestJS sur Fastify, TypeScript strict, PostgreSQL ; tout autre langage/framework backend passe par un ADR. → [BE-001](BE-001-choix-de-stack.md)
- Monolithe modulaire : un module NestJS par domaine métier ; controller (HTTP) → service (métier) → repository (Drizzle) ; un module n'accède jamais aux tables d'un autre. → [BE-002](BE-002-architecture-modulaire.md)

**Données**

- Drizzle ; migrations générées, relues, appliquées par un job avant déploiement ; tables `snake_case` au pluriel ; UUID v7 ; `timestamptz` en UTC ; montants en centimes ; migrations *expand/contract* ; pas de N+1 ; transactions multi-tables. → [BE-003](BE-003-donnees-drizzle-et-migrations.md)

**API**

- REST `/v1`, contrat OpenAPI généré, JSON `camelCase`, pagination par curseur, erreurs Problem Details (RFC 9457), pas de changement cassant sans nouvelle version. → [BE-004](BE-004-api-rest-et-openapi.md)
- Toute donnée entrante validée par Zod à la frontière (requêtes, env, webhooks, API tierces) ; schémas stricts ; réponses filtrées par un schéma de sortie. → [BE-005](BE-005-validation-aux-frontieres.md)

**Sécurité**

- Better Auth (Drizzle) ; Argon2id ; sessions opaques révocables, en cookie `HttpOnly` + CSRF sur le web, en `Bearer` stocké dans le Keychain/Keystore sur mobile, durée de vie absolue bornée ; routes protégées par défaut ; contrôle d'accès sur la ressource ; rate limiting ; pas de données sensibles dans les logs. → [BE-006](BE-006-authentification-et-securite.md)

**Exploitation**

- Logs JSON pino avec `traceId`, OpenTelemetry, `/health/live` + `/health/ready`, arrêt propre sur `SIGTERM`, pas de `console.log`. → [BE-007](BE-007-observabilite.md)

**Tests**

- Vitest ; PostgreSQL réel via Testcontainers (jamais de base mockée) ; factories ; un test d'accès refusé par endpoint protégé. → [BE-008](BE-008-tests-backend.md)

## Conventions de nommage

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Fichier | `kebab-case.<rôle>.ts` | `invoice-lines.service.ts` |
| Classe | `PascalCase` + suffixe | `InvoiceLinesService` |
| Table / colonne SQL | `snake_case`, table au pluriel | `invoice_lines.created_at` |
| URL | `kebab-case`, pluriel | `/v1/invoice-lines` |
| JSON | `camelCase` | `createdAt` |

## Index

| ADR | Titre | Statut |
|-----|-------|--------|
| [BE-001](BE-001-choix-de-stack.md) | Node.js + TypeScript + NestJS + PostgreSQL | Proposé |
| [BE-002](BE-002-architecture-modulaire.md) | Monolithe modulaire par domaine | Proposé |
| [BE-003](BE-003-donnees-drizzle-et-migrations.md) | Drizzle et conventions SQL | Proposé |
| [BE-004](BE-004-api-rest-et-openapi.md) | API REST et contrat OpenAPI | Proposé |
| [BE-005](BE-005-validation-aux-frontieres.md) | Validation aux frontières | Proposé |
| [BE-006](BE-006-authentification-et-securite.md) | Authentification et sécurité | Proposé |
| [BE-007](BE-007-observabilite.md) | Logs, traces, santé | Proposé |
| [BE-008](BE-008-tests-backend.md) | Tests backend | Proposé |

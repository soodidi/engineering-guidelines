# BE-008 : Tests backend

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : backend
- **Auteurs** : Mo, Claude

## Contexte

Déclinaison backend de GLB-004. Les tests qui mockent la base de données passent alors que les requêtes SQL réelles échouent. Le vrai risque backend se situe souvent dans les requêtes, les transactions et les règles d'accès.

## Décision

| Niveau | Outil | Cible |
|--------|-------|-------|
| Unitaire | **Vitest** | règles métier pures, calculs, mappers |
| Intégration | **Vitest + Testcontainers (PostgreSQL réel)** | services + repositories avec une vraie base |
| API / e2e | **Vitest + `app.inject()` (Fastify)** ou supertest | endpoints complets : auth, validation, codes HTTP, format d'erreur |

**Règles**
- On NE mocke PAS la base de données pour tester les repositories : on utilise un PostgreSQL réel en conteneur, avec les vraies migrations.
- Chaque test d'intégration part d'un état propre (transaction annulée en fin de test, ou base tronquée).
- Les données de test sont créées via des **factories** (`createUser({ role: 'admin' })`), pas par des fixtures SQL géantes partagées.
- Les services externes (paiement, email, API tierces) sont simulés à la frontière (adaptateur de test ou MSW/nock), jamais appelés réellement.
- **Chaque endpoint protégé a au moins un test d'accès refusé** (non authentifié → 401, autre organisation → 403/404).
- Le temps est injecté (horloge contrôlable), jamais `new Date()` directement dans la logique métier testée.

## Alternatives envisagées

- **Jest** : fonctionne, mais Vitest est plus rapide et aligné avec le front.
- **SQLite en mémoire pour les tests** : différences de comportement avec PostgreSQL, faux positifs.

## Conséquences

- ✅ Confiance réelle sur les requêtes, les migrations et la sécurité.
- ⚠️ Tests d'intégration plus lents : Docker nécessaire en local et en CI.

## Mise en application

- CI : tests unitaires + intégration sur chaque PR (Docker disponible sur les runners GitHub).
- Revue de code : pas de nouvelle route sans test d'accès.

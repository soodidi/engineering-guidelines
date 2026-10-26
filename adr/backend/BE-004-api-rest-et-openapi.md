# BE-004 : API REST, contrat OpenAPI et conventions

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : backend
- **Auteurs** : Mo, Claude

## Contexte

Le même backend sert le web, Android, iOS et potentiellement des partenaires. Les applications mobiles installées ne se mettent pas à jour en même temps que le serveur : l'API doit rester compatible longtemps. Il faut un contrat unique dont chaque client peut générer son code.

## Décision

**Contrat**

- L'API est décrite en **OpenAPI 3.1**, générée depuis le code (schémas Zod + décorateurs NestJS) et publiée à chaque build.
- Les clients (web, Android, iOS) DEVRAIENT générer leurs types / clients à partir de ce contrat (FE-006, AND-004, IOS-004).
- Un changement cassant du contrat est détecté en CI.

**Conventions REST**

- URLs : ressources au pluriel, `kebab-case` : `/v1/invoice-lines/{id}`.
- JSON en `camelCase`. Dates en ISO 8601 UTC (`2026-10-25T21:30:00Z`). Montants en centimes (entiers) avec la devise.
- Verbes : `GET` (lecture), `POST` (création ou action), `PATCH` (modification partielle), `PUT` (remplacement complet), `DELETE`.
- Codes : `200`, `201` (+ `Location`), `204`, `400` (validation), `401`, `403`, `404`, `409` (conflit), `422` (règle métier), `429`, `500`.
- Les `POST` sensibles à la duplication (paiement, commande) acceptent un en-tête `Idempotency-Key`.

**Versioning**

- Version majeure dans l'URL : `/v1/…`.
- Sans changer de version, on PEUT ajouter des champs, des endpoints, des valeurs optionnelles. On NE PEUT PAS supprimer ou renommer un champ, changer un type ou rendre obligatoire un champ optionnel.
- Une ancienne version est maintenue tant que des versions d'apps mobiles en circulation l'utilisent ; l'abandon est annoncé avec l'en-tête `Deprecation` / `Sunset`.

**Pagination, filtres, tri**

- Pagination par **curseur** par défaut : `?limit=20&cursor=…` → `{ data: [...], nextCursor: "…" | null }`.
- Filtres en query params explicites (`?status=paid`), tri avec `?sort=-createdAt`.

**Erreurs**

- Format **Problem Details (RFC 9457)**, `Content-Type: application/problem+json` :

```json
{
  "type": "https://api.example.com/errors/validation",
  "title": "Validation failed",
  "status": 400,
  "detail": "2 champs sont invalides",
  "errors": [{ "field": "email", "code": "invalid_format" }],
  "traceId": "4bf92f3577b34da6"
}
```

- Les messages d'erreur ne divulguent jamais de détail interne (stack trace, SQL).

## Alternatives envisagées

- **GraphQL** : utile pour des clients aux besoins très variés ; ajoute de la complexité (cache, autorisation par champ, N+1). Pas nécessaire au départ.
- **tRPC** : excellent entre un front et un back TypeScript, mais inutilisable proprement depuis Kotlin et Swift.
- **Versioning par en-tête** : plus « pur », moins pratique à tester et à router.

## Conséquences

- ✅ Un contrat unique, des clients générés, des erreurs homogènes.
- ⚠️ Rigueur nécessaire sur la rétrocompatibilité.

## Mise en application

- Spec OpenAPI exportée en artefact CI ; `oasdiff` pour bloquer les changements cassants sur `/v1`.
- Filtre d'exception global NestJS qui produit le format Problem Details.
- `Spectral` pour linter la spec.

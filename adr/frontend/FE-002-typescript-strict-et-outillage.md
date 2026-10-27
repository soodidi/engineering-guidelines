# FE-002 : TypeScript strict et outillage de qualité

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : frontend
- **Auteurs** : Mo, Claude

## Contexte

TypeScript ne protège que si on le laisse faire son travail. Les `any`, les assertions `as` et une configuration permissive annulent l'intérêt du typage. Le formatage et les règles de style doivent être automatiques pour ne jamais occuper la revue de code.

## Décision

**tsconfig**

- `"strict": true` DOIT être activé, ainsi que `noUncheckedIndexedAccess`, `noImplicitOverride`, `noFallthroughCasesInSwitch`.
- `exactOptionalPropertyTypes` reste **désactivé** : trop de friction avec les librairies tierces pour un gain faible.
- Alias d'import `@/` vers `src/`.

**Règles de code**

- `any` est interdit. Utiliser `unknown` puis affiner.
- Les assertions `as` sont réservées aux cas justifiés par un commentaire. `as const` et `satisfies` sont encouragés.
- Pas de `!` (non-null assertion) hors tests.
- Les données venant de l'extérieur (API, localStorage, URL) DOIVENT être validées à l'exécution (Zod) avant d'être typées.
  - Exception : les appels d'authentification passent par le SDK client de Better Auth (BE-006), qui gère lui-même ses requêtes. Seules les données que l'app consomme sont validées : la session par un schéma Zod, et seuls `status` et `code` sont lus dans les erreurs. Les réponses des autres appels d'auth ne sont pas utilisées.
- `type` par défaut ; `interface` seulement pour un contrat destiné à être étendu.
- Pas d'`enum` TypeScript : utiliser des unions de littéraux ou des objets `as const`.
- Exports nommés uniquement (sauf contrainte d'un outil, ex : `lazy()`).

**Conventions de nommage**

- Composants et types : `PascalCase`. Fichiers de composant : `PascalCase.tsx`.
- Hooks : `useCamelCase`, fichier `useCamelCase.ts`.
- Autres fichiers : `kebab-case.ts`.
- Constantes globales : `SCREAMING_SNAKE_CASE`.

**Outils**

- ESLint (flat config) avec `typescript-eslint` (preset `strict-type-checked`), `eslint-plugin-react-hooks`, `eslint-plugin-jsx-a11y-x` (fork de `eslint-plugin-jsx-a11y` compatible ESLint 10 ; revenir à l'original dès qu'il le supporte).
- Prettier pour le formatage, avec `prettier-plugin-tailwindcss` pour l'ordre des classes.
- `tsc --noEmit` en CI.

## Alternatives envisagées

- **Biome** : beaucoup plus rapide qu'ESLint + Prettier, mais il lui manque encore une partie des règles basées sur les types et les plugins sur lesquels s'appuient nos ADR (hooks, a11y, TanStack Query, Testing Library). À réévaluer en 2027.
- **TypeScript non strict** : rejeté, perd l'essentiel de la valeur.

## Conséquences

- ✅ Erreurs détectées à la compilation plutôt qu'en production.
- ⚠️ Plus de friction au début, notamment avec des libs mal typées.

## Mise en application

- CI : `npm run lint`, `npm run typecheck`, `prettier --check`.
- `lefthook` : lint et format des fichiers modifiés en pre-commit.

# Guide frontend

Stack : **React + TypeScript + Vite + Tailwind**, TanStack Router, TanStack Query, React Compiler, React Hook Form + Zod, Vitest, Playwright, Sentry.
S'applique en plus du [guide global](../global/README.md).

## Règles en bref

**Socle**

- SPA React + Vite + TanStack Router (routes et search params typés) par défaut. Next.js seulement pour SEO, premier affichage public critique ou aperçus de partage, justifié dans un ADR du projet. → [FE-001](FE-001-react-vite-par-defaut.md)
- TS `strict` + `noUncheckedIndexedAccess` ; pas de `any`, pas d'`enum`, pas de `!` ; `as` justifié ; données externes validées avec Zod ; exports nommés. → [FE-002](FE-002-typescript-strict-et-outillage.md)

**Architecture**

- Code rangé par feature (`src/features/x/{api,components,hooks,schemas,routes}`), imports entre features uniquement via `index.ts`. → [FE-003](FE-003-structure-par-feature.md)
- Données serveur dans TanStack Query (jamais copiées dans un store) ; filtres et pagination dans l'URL ; état local en `useState` ; Zustand seulement pour l'état client partagé. → [FE-004](FE-004-gestion-de-l-etat.md)

**UI**

- Tailwind uniquement, tokens sémantiques, pas de valeurs arbitraires ; `cn()` + `cva` ; composants shadcn/ui sur Radix. → [FE-005](FE-005-styling-tailwind-et-composants.md)
- Formulaires : React Hook Form + Zod, type dérivé du schéma, erreurs API mappées sur les champs, labels et ARIA systématiques. → [FE-006](FE-006-formulaires-et-validation.md)
- WCAG 2.2 AA, tout au clavier, HTML sémantique ; responsive mobile first de 320 px au grand écran, sans défilement horizontal, cibles tactiles ≥ 24 px ; routes en lazy, bundle initial ≤ 200 Ko ; React Compiler activé, pas de `useMemo`/`useCallback` manuels. → [FE-008](FE-008-accessibilite-et-performance.md)

**Production**

- Sentry (région UE) initialisé avant le rendu, `release` = SHA du commit, `dataCollection` restrictif, pas de Replay par défaut, ErrorBoundary racine, source maps envoyées par la CI puis retirées du build. → [FE-009](FE-009-suivi-des-erreurs-sentry.md)

**Tests**

- Vitest + Testing Library + MSW ; requêtes par rôle ; pas de mock interne ; Playwright pour les parcours critiques. → [FE-007](FE-007-tests-frontend.md)

## Conventions de nommage

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Composant | `PascalCase.tsx` | `InvoiceTable.tsx` |
| Hook | `useCamelCase.ts` | `useInvoices.ts` |
| Autre fichier | `kebab-case.ts` | `format-currency.ts` |
| Test | à côté du fichier | `InvoiceTable.test.tsx` |

## Index

| ADR | Titre | Statut |
|-----|-------|--------|
| [FE-001](FE-001-react-vite-par-defaut.md) | React + Vite par défaut, Next.js si nécessaire | Proposé |
| [FE-002](FE-002-typescript-strict-et-outillage.md) | TypeScript strict et outillage | Proposé |
| [FE-003](FE-003-structure-par-feature.md) | Organisation par feature | Proposé |
| [FE-004](FE-004-gestion-de-l-etat.md) | Gestion de l'état | Proposé |
| [FE-005](FE-005-styling-tailwind-et-composants.md) | Tailwind et composants accessibles | Proposé |
| [FE-006](FE-006-formulaires-et-validation.md) | Formulaires et validation | Proposé |
| [FE-007](FE-007-tests-frontend.md) | Tests frontend | Proposé |
| [FE-008](FE-008-accessibilite-et-performance.md) | Accessibilité, responsive et performance | Proposé |
| [FE-009](FE-009-suivi-des-erreurs-sentry.md) | Suivi des erreurs en production (Sentry) | Proposé |

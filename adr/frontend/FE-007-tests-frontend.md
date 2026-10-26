# FE-007 : Tests frontend

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : frontend
- **Auteurs** : Mo, Claude

## Contexte

Déclinaison front de GLB-004. Les tests front qui vérifient des détails d'implémentation (state interne, nombre d'appels d'un hook) cassent à chaque refactoring sans apporter de confiance.

## Décision

| Niveau | Outil | Cible |
|--------|-------|-------|
| Unitaire | **Vitest** | fonctions pures, hooks métier, schémas Zod |
| Composant / intégration | **Vitest + Testing Library** (+ `user-event`) | composants et écrans d'une feature |
| Mock réseau | **MSW** | réponses API réalistes partagées entre tests et dev |
| End-to-end | **Playwright** | parcours critiques (login, création, paiement…) |

**Règles**

- Tester comme un utilisateur : requêtes par rôle et libellé (`getByRole`, `getByLabelText`). `getByTestId` en dernier recours.
- Ne pas mocker les modules internes (hooks, composants enfants). Mocker la **frontière réseau** avec MSW.
- Interactions avec `user-event`, pas `fireEvent`.
- Pas de snapshot de composants entiers (illisibles, approuvés sans être lus). Les tests visuels se font avec Playwright si besoin.
- Les handlers MSW sont dans `src/mocks/` et réutilisables en développement.
- E2E : sélecteurs par rôle, pas de `waitForTimeout` arbitraire.

## Alternatives envisagées

- **Jest** : fonctionne, mais configuration plus lourde avec Vite et ESM ; Vitest partage la config Vite.
- **Cypress** : bon outil, mais Playwright est plus rapide, multi-navigateurs et mieux parallélisable.

## Conséquences

- ✅ Tests robustes aux refactorings, qui renforcent aussi l'accessibilité (requêtes par rôle).
- ⚠️ Les handlers MSW doivent suivre l'évolution de l'API (idéalement générés depuis OpenAPI).

## Mise en application

- CI : `vitest run --coverage` sur chaque PR, Playwright avant déploiement en production.
- `eslint-plugin-testing-library`.

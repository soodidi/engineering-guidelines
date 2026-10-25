# FE-008 : Accessibilité et performance minimales

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : frontend
- **Auteurs** : Mo, Claude

## Contexte

L'accessibilité et la performance sont coûteuses à rattraper après coup. En France, le RGAA s'impose à certaines organisations, et l'European Accessibility Act élargit les obligations à de nombreux services numériques privés. Il faut un socle non négociable sur chaque écran.

## Décision

**Accessibilité (cible : WCAG 2.2 niveau AA)**
- HTML sémantique d'abord : `button` pour une action, `a` pour une navigation, titres `h1`–`h6` hiérarchisés, landmarks (`main`, `nav`, `header`).
- Toute l'app DOIT être utilisable au clavier, avec un focus visible.
- Images informatives : `alt` pertinent ; images décoratives : `alt=""`.
- Contraste conforme AA (vérifié au niveau des tokens, FE-005).
- Ne jamais transmettre une information **uniquement** par la couleur.
- Respect de `prefers-reduced-motion` pour les animations.
- À chaque changement de route, le titre de la page change et le focus est géré.

**Performance**
- Routes chargées en lazy (`React.lazy` par feature).
- Budget de bundle JS initial (compressé) : **≤ 200 Ko**, suivi en CI.
- Images : formats modernes (WebP/AVIF), dimensions explicites, `loading="lazy"` sous la ligne de flottaison.
- Listes de plus de quelques centaines d'éléments : virtualisation (TanStack Virtual).
- **React Compiler activé** sur les nouveaux projets (plugin Babel dans Vite), avec la règle ESLint associée (`eslint-plugin-react-hooks`, preset recommandé). Le code DOIT respecter les règles de React : composants et hooks purs, pas de mutation des props ni de l'état.
- Pas de `useMemo` / `useCallback` / `React.memo` écrits à la main, sauf problème mesuré que le compilateur ne règle pas, ou besoin d'une référence stable pour une librairie externe.
- Cibles Core Web Vitals pour les pages publiques : LCP < 2,5 s, INP < 200 ms, CLS < 0,1.

## Alternatives envisagées

- **Audit d'accessibilité en fin de projet** : correctifs coûteux et partiels.

## Conséquences

- ✅ Socle accessible et rapide sans effort supplémentaire par écran.
- ⚠️ Vérification manuelle au clavier nécessaire sur les écrans nouveaux.

## Mise en application

- `eslint-plugin-jsx-a11y`.
- `@axe-core/playwright` dans les tests E2E.
- `size-limit` ou équivalent en CI pour le budget de bundle.
- Lighthouse CI sur les pages publiques.

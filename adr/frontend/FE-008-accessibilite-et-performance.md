# FE-008 : Accessibilité, responsive et performance minimales

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : frontend
- **Auteurs** : Mo, Claude

## Contexte

L'accessibilité, l'adaptation aux tailles d'écran et la performance sont coûteuses à rattraper après coup. Une bonne part des visites se fait sur téléphone. En France, le RGAA s'impose à certaines organisations, et l'European Accessibility Act élargit les obligations à de nombreux services numériques privés. Il faut un socle non négociable sur chaque écran.

## Décision

**Accessibilité (cible : WCAG 2.2 niveau AA)**

- HTML sémantique d'abord : `button` pour une action, `a` pour une navigation, titres `h1`–`h6` hiérarchisés, landmarks (`main`, `nav`, `header`).
- Toute l'app DOIT être utilisable au clavier, avec un focus visible.
- Images informatives : `alt` pertinent ; images décoratives : `alt=""`.
- Contraste conforme AA (vérifié au niveau des tokens, FE-005).
- Ne jamais transmettre une information **uniquement** par la couleur.
- Respect de `prefers-reduced-motion` pour les animations.
- À chaque changement de route, le titre de la page change et le focus est géré.

**Responsive (mobile first)**

- Chaque écran DOIT être utilisable de **320 px** de large (petit téléphone, ou zoom à 400 % d'un écran de 1280 px, WCAG 1.4.10) jusqu'au grand écran, en portrait comme en paysage.
- Aucun défilement horizontal de la page, quelle que soit la largeur : le contenu se réorganise (WCAG 1.4.10). Seuls un tableau, un bloc de code ou une carte PEUVENT défiler dans leur propre zone.
- Styles écrits **mobile first** : classes de base pour le petit écran, puis préfixes `sm:`, `md:`, `lg:` pour élargir. Pas de largeur fixe en pixels sur un conteneur ; `max-w-*` et `w-full`.
- Navigation : sur petit écran, elle se replie (menu) ou passe à la ligne sans déborder.
- Cibles tactiles d'au moins **24 × 24 px** avec leur espacement (WCAG 2.5.8), 44 × 44 px visés pour les actions principales.
- Formulaires sur une colonne en petit écran ; type de champ adapté (`type="email"`, `inputmode`, `autocomplete`) pour le bon clavier mobile.
- Tableaux : en cartes sur petit écran, ou défilement interne avec la première colonne lisible.
- Texte : taille de base d'au moins 16 px sur les champs (sinon iOS zoome à la saisie) ; le zoom du navigateur n'est jamais bloqué (`user-scalable` interdit).

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
- ⚠️ Un écran pensé d'abord pour le bureau doit être repris : le responsive se conçoit dès la maquette.

## Mise en application

- `eslint-plugin-jsx-a11y-x` (voir FE-002).
- `@axe-core/playwright` dans les tests E2E.
- Test E2E de débordement : chaque route ouverte à 320, 768 et 1280 px échoue si la page défile horizontalement ; les parcours critiques tournent aussi sur un profil mobile.
- Agent `reviewer` : le responsive fait partie de la revue d'un écran (classes `sm:`/`md:`, largeurs fixes, cibles tactiles).
- `size-limit` ou équivalent en CI pour le budget de bundle.
- Lighthouse CI sur les pages publiques.

# FE-005 : Styling avec Tailwind et composants accessibles

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : frontend
- **Auteurs** : Mo, Claude
- **Liens** : GLB-012

## Contexte

Il faut une méthode de style cohérente, rapide à écrire et sans coût d'exécution. Recoder des composants complexes (select, dialog, combobox) de façon accessible est long et source de bugs.

## Décision

**Style**

- **Tailwind CSS** est la seule méthode de style. Pas de CSS-in-JS à l'exécution, pas de fichiers CSS par composant (sauf cas exceptionnel justifié).
- Les tokens (couleurs, rayons, police) viennent du thème choisi dans `@soodidi/design-tokens` (GLB-012), copié dans `src/theme/`. Pas de valeurs arbitraires (`w-[437px]`, `#3a7bd5`) hors cas ponctuel justifié.
- Les couleurs sont **sémantiques** (`bg-primary`, `text-muted-foreground`), jamais des couleurs brutes dans les composants. Le mode sombre passe par les variables.
- Fusion de classes conditionnelles avec un utilitaire `cn()` (`clsx` + `tailwind-merge`).
- Variantes de composants avec `cva` (class-variance-authority) plutôt que des ternaires imbriqués.

**Composants**

- Base : **shadcn/ui** (composants copiés dans `components/ui`, construits sur Radix), adaptés au design du projet.
- Pour tout composant interactif complexe, partir d'une primitive accessible (Radix / React Aria) plutôt que de le coder à la main.
- Icônes : une seule bibliothèque par projet (Lucide par défaut).

**Composants React**

- Composants fonctionnels uniquement.
- Un composant de plus de ~150 lignes DEVRAIT être découpé.
- Props explicites et typées ; pas de spread de props non maîtrisé sauf pour les composants de base qui enveloppent un élément HTML.

## Alternatives envisagées

- **CSS Modules** : bonne isolation, mais plus lent à écrire et pas de système de tokens partagé par défaut.
- **Bibliothèque complète (MUI, Chakra, Mantine)** : rapide au début, mais design difficile à personnaliser profondément et poids plus important.

## Conséquences

- ✅ Pas de CSS mort, design cohérent, composants accessibles par défaut.
- ⚠️ Les classes longues nuisent à la lisibilité : extraire des composants plutôt que des `@apply`.

## Mise en application

- `prettier-plugin-tailwindcss` (ordre des classes).
- `eslint-plugin-tailwindcss` ou équivalent compatible avec la version de Tailwind utilisée, pour signaler les valeurs arbitraires.

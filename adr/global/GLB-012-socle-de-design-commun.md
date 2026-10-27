# GLB-012 : Socle de design commun

- **Statut** : Proposé
- **Date** : 2026-10-27
- **Périmètre** : global
- **Auteurs** : Mo, Claude
- **Liens** : FE-005, FE-008, AND-001, IOS-001, GLB-010, GLB-011

## Contexte

Les apps sont en grande partie codées par une IA. Sans référence de design, chaque écran réinvente ses couleurs, ses rayons et ses contrastes, et les apps web, Android et iOS d'un même produit finissent par ne pas se ressembler. Toutes les apps n'ont pas la même personnalité : certaines doivent être épurées, d'autres chaleureuses ou colorées. Il faut donc un socle commun, mais pas une identité unique.

## Décision

- Le package **`@soodidi/design-tokens`** (repo `shared-libs`) est la source unique des tokens de design. Il génère, à partir d'un seul fichier (`src/themes.ts`) :
  - le CSS pour le web (variables + correspondance Tailwind 4) ;
  - `ThemeTokens.kt` pour Jetpack Compose (schémas de couleurs Material 3 complets, formes) ;
  - `ThemeTokens.swift` pour SwiftUI (`AppColor`, `AppRadius`).
- Un **thème** = des **rôles de couleur** en clair et en sombre, un rayon de base et une police. Trois thèmes de départ :

| Thème | Id | Style |
|-------|----|-------|
| Épuré | `clean` | Neutre et sobre, accent quasi noir, angles discrets (6 px) |
| Chaleureux | `warm` | Fonds sable, accent miel, coins arrondis (12 px) |
| Coloré | `vivid` | Accent violet, touches rose et turquoise, formes généreuses (16 px) |

- Rôles de couleur : `background`, `foreground`, `card`, `primary`, `secondary`, `muted`, `accent`, `destructive`, `success`, `warning` (chacun avec sa variante `…Foreground`), plus `border`, `input` et `ring`. Les noms suivent shadcn/ui pour que ses composants fonctionnent tels quels (FE-005).
- Chaque app choisit **un** thème au démarrage du projet (`/new-project`) et copie ses fichiers générés. Le **mode clair et le mode sombre** sont toujours fournis ; par défaut l'app suit le système.
- Les composants et écrans **NE DOIVENT** utiliser que les rôles (`bg-primary`, `MaterialTheme.colorScheme.primary`, `AppColor.primary`), jamais une couleur brute ni une couleur système (`Color.red`, `#3a7bd5`).
- Une app qui a besoin de sa propre identité **DEVRAIT** ajouter un thème au package (copie d'un thème existant, nouvelles valeurs) plutôt que modifier ses fichiers générés à la main : le contrôle des contrastes s'applique alors aussi à elle.
- Tout thème **DOIT** respecter WCAG AA : 4,5:1 pour chaque paire texte / fond, 3:1 pour les bordures de champ, l'anneau de focus et la couleur principale sur le fond (FE-008). Les tests du package le vérifient.
- Hors couleurs et rayons, chaque plateforme garde ses conventions : échelle Tailwind sur le web, typographie Material 3 sur Android, Dynamic Type sur iOS. Les espacements restent sur une grille de 4 px.

## Alternatives envisagées

- **Une identité unique pour toutes les apps** : plus simple, mais toutes les apps n'ont pas le même public ni le même ton.
- **Style Dictionary ou Tokens Studio** : outils complets, mais une dépendance et un format de plus pour une vingtaine de valeurs. Un générateur de 200 lignes testé suffit.
- **Couleurs dynamiques Android (Material You) par défaut** : l'app perdrait son identité ; l'option reste disponible dans `AppTheme(dynamicColor = true)`.

## Conséquences

- ✅ L'IA dispose d'un vocabulaire fermé de couleurs et de rayons : les écrans restent cohérents entre eux et entre plateformes.
- ✅ Mode sombre et contrastes accessibles fournis d'office.
- ⚠️ Les apps copient les fichiers générés (GLB-010) : une évolution du package doit être reportée à la main dans chaque app.

## Mise en application

- Tests du package : contrastes WCAG de chaque thème, fichiers générés à jour.
- Boilerplates : thème `clean` installé (`src/theme/` en web, `core/designsystem/ThemeTokens.kt` en Android, `DesignSystem/ThemeTokens.swift` en iOS).
- Revue de code et agent `reviewer` : toute couleur brute ou valeur arbitraire dans un composant est un `bloquant:`.
